// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Argon2id parameters, stored on the server so every device derives the same
/// key (spec sync design). Defaults follow OWASP guidance for interactive use.
class Argon2Params {
  const Argon2Params({
    // OWASP's first recommended Argon2id setting (46 MiB, t=1, p=1), up from
    // the 19 MiB / t=2 minimum (security audit finding 3). Existing blobs
    // keep their stored parameters, so this only affects new setups.
    this.memoryKib = 47104, // 46 MiB
    this.iterations = 1,
    this.parallelism = 1,
  });

  final int memoryKib;
  final int iterations;
  final int parallelism;

  Map<String, dynamic> toJson() => {
        'memoryKib': memoryKib,
        'iterations': iterations,
        'parallelism': parallelism,
      };

  /// A blob always carries its parameters; the fallbacks are the values the
  /// first builds used, so a blob written before they were stored still
  /// derives the same key.
  factory Argon2Params.fromJson(Map<String, dynamic> j) => Argon2Params(
        memoryKib: (j['memoryKib'] as num?)?.toInt() ?? 19456,
        iterations: (j['iterations'] as num?)?.toInt() ?? 2,
        parallelism: (j['parallelism'] as num?)?.toInt() ?? 1,
      );
}

/// End-to-end sync crypto (spec sync design). The passphrase derives a master
/// key (Argon2id); a random data key (DEK) encrypts the blob (AES-256-GCM) and
/// is wrapped by the master key (DEK indirection, so the passphrase can change
/// without re-encrypting everything). The server only ever sees ciphertext, the
/// KDF salt, the wrapped DEK, and a verification hash, none of which reveal the
/// data or the passphrase.
class SyncCrypto {
  final _rng = Random.secure();
  final _aes = AesGcm.with256bits();

  Uint8List randomBytes(int n) {
    final b = Uint8List(n);
    for (var i = 0; i < n; i++) {
      b[i] = _rng.nextInt(256);
    }
    return b;
  }

  /// A fresh sync identity: 32 random bytes as URL-safe base64 (43 chars).
  String newSyncId() => base64Url.encode(randomBytes(32)).replaceAll('=', '');

  Uint8List newSalt() => randomBytes(32);
  Uint8List newDek() => randomBytes(32);

  Future<List<int>> deriveMasterKey(
    String passphrase,
    List<int> salt,
    Argon2Params params,
  ) async {
    final algorithm = Argon2id(
      memory: params.memoryKib,
      iterations: params.iterations,
      parallelism: params.parallelism,
      hashLength: 32,
    );
    final key = await algorithm.deriveKey(
      secretKey: SecretKey(utf8.encode(passphrase)),
      nonce: salt,
    );
    return key.extractBytes();
  }

  /// The verification value the server stores and compares in constant time.
  /// A one-way hash of the master key: proves passphrase knowledge without
  /// revealing the key.
  Future<List<int>> passwordHash(List<int> masterKey) async {
    final h = await Sha256().hash([...masterKey, 0x63, 0x61, 0x69, 0x72, 0x6e]);
    return h.bytes;
  }

  /// AES-256-GCM: nonce(12) + mac(16) + ciphertext.
  Future<Uint8List> _seal(List<int> plaintext, List<int> key) async {
    final nonce = randomBytes(12);
    final box = await _aes.encrypt(
      plaintext,
      secretKey: SecretKey(key),
      nonce: nonce,
    );
    return Uint8List.fromList([...nonce, ...box.mac.bytes, ...box.cipherText]);
  }

  Future<List<int>> _open(List<int> sealed, List<int> key) async {
    if (sealed.length < 28) throw const FormatException('sealed too short');
    final nonce = sealed.sublist(0, 12);
    final mac = sealed.sublist(12, 28);
    final ct = sealed.sublist(28);
    final box = SecretBox(ct, nonce: nonce, mac: Mac(mac));
    return _aes.decrypt(box, secretKey: SecretKey(key));
  }

  Future<Uint8List> wrapDek(List<int> dek, List<int> masterKey) =>
      _seal(dek, masterKey);

  Future<List<int>> unwrapDek(List<int> wrapped, List<int> masterKey) =>
      _open(wrapped, masterKey);

  Future<Uint8List> encryptBlob(List<int> plaintext, List<int> dek) =>
      _seal(plaintext, dek);

  Future<List<int>> decryptBlob(List<int> blob, List<int> dek) =>
      _open(blob, dek);
}
