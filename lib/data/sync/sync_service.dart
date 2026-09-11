// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../db/app_database.dart';
import 'sync_blob.dart';
import 'sync_client.dart';
import 'sync_crypto.dart';

/// Wrong passphrase on join or unlock.
class SyncWrongPassphrase implements Exception {}

/// No sync data on the server to join.
class SyncNoData implements Exception {}

/// Persisted sync state (in the OS secure store; never in plain prefs).
class SyncState {
  const SyncState({
    required this.baseUrl,
    required this.syncId,
    required this.masterKeyB64,
    required this.dekB64,
    required this.saltB64,
    required this.params,
    required this.version,
    this.lastSyncedAtMs,
  });

  final String baseUrl;
  final String syncId;
  final String masterKeyB64;
  final String dekB64;
  final String saltB64;
  final Argon2Params params;
  final int version;
  final int? lastSyncedAtMs;

  Map<String, dynamic> toJson() => {
        'baseUrl': baseUrl,
        'syncId': syncId,
        'masterKey': masterKeyB64,
        'dek': dekB64,
        'salt': saltB64,
        'params': params.toJson(),
        'version': version,
        'lastSyncedAt': lastSyncedAtMs,
      };

  factory SyncState.fromJson(Map<String, dynamic> j) => SyncState(
        baseUrl: j['baseUrl'] as String,
        syncId: j['syncId'] as String,
        masterKeyB64: j['masterKey'] as String,
        dekB64: j['dek'] as String,
        saltB64: j['salt'] as String,
        params: Argon2Params.fromJson(
          (j['params'] as Map?)?.cast<String, dynamic>() ?? const {},
        ),
        version: (j['version'] as num?)?.toInt() ?? 1,
        lastSyncedAtMs: (j['lastSyncedAt'] as num?)?.toInt(),
      );

  SyncState copyWith({int? version, int? lastSyncedAtMs}) => SyncState(
        baseUrl: baseUrl,
        syncId: syncId,
        masterKeyB64: masterKeyB64,
        dekB64: dekB64,
        saltB64: saltB64,
        params: params,
        version: version ?? this.version,
        lastSyncedAtMs: lastSyncedAtMs ?? this.lastSyncedAtMs,
      );
}

const _stateKey = 'cairn.sync.state';

/// End-to-end encrypted multi-device sync (spec: the user's Zest-sync request).
/// Optional and off by default; the app is fully functional without it.
class SyncService {
  SyncService({
    required this.db,
    required this.dio,
    required this.storage,
    SyncCrypto? crypto,
  }) : crypto = crypto ?? SyncCrypto();

  final AppDatabase db;
  final Dio dio;
  final FlutterSecureStorage storage;
  final SyncCrypto crypto;

  Future<SyncState?> loadState() async {
    final raw = await storage.read(key: _stateKey);
    if (raw == null) return null;
    return SyncState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<bool> get isEnabled async => (await loadState()) != null;

  Future<void> _save(SyncState s) =>
      storage.write(key: _stateKey, value: jsonEncode(s.toJson()));

  SyncClient _client(String baseUrl, String syncId) =>
      SyncClient(dio: dio, baseUrl: baseUrl, syncId: syncId, deviceId: 'cairn');

  /// Sets up sync on the first device. Returns the sync code to enter on others.
  Future<String> enable({
    required String baseUrl,
    required String passphrase,
  }) async {
    final syncId = crypto.newSyncId();
    final salt = crypto.newSalt();
    final dek = crypto.newDek();
    const params = Argon2Params();
    final masterKey = await crypto.deriveMasterKey(passphrase, salt, params);
    final pwHash = await crypto.passwordHash(masterKey);
    final wrapped = await crypto.wrapDek(dek, masterKey);

    final blob = await gatherAll(db);
    final enc = await crypto.encryptBlob(utf8.encode(jsonEncode(blob)), dek);

    final version = await _client(baseUrl, syncId).push(
      encryptedData: base64.encode(enc),
      salt: base64.encode(salt),
      passwordHash: base64.encode(pwHash),
      wrappedDekPassword: base64.encode(wrapped),
      argon2Params: params.toJson(),
    );

    await _save(
      SyncState(
        baseUrl: baseUrl,
        syncId: syncId,
        masterKeyB64: base64.encode(masterKey),
        dekB64: base64.encode(dek),
        saltB64: base64.encode(salt),
        params: params,
        version: version,
        lastSyncedAtMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    return syncId;
  }

  /// Joins existing sync on another device with the sync code and passphrase.
  Future<void> join({
    required String baseUrl,
    required String syncId,
    required String passphrase,
  }) async {
    final pull = await _client(baseUrl, syncId).pull();
    if (pull == null || pull.wrappedDekPassword == null) throw SyncNoData();

    final salt = base64.decode(pull.salt);
    final params = Argon2Params.fromJson(pull.argon2Params ?? const {});
    final masterKey = await crypto.deriveMasterKey(passphrase, salt, params);

    final List<int> dek;
    try {
      dek = await crypto.unwrapDek(
        base64.decode(pull.wrappedDekPassword!),
        masterKey,
      );
    } catch (_) {
      throw SyncWrongPassphrase();
    }

    final plaintext = await crypto.decryptBlob(
      base64.decode(pull.encryptedData),
      dek,
    );
    await restoreAll(
        db, jsonDecode(utf8.decode(plaintext)) as Map<String, dynamic>);

    await _save(
      SyncState(
        baseUrl: baseUrl,
        syncId: syncId,
        masterKeyB64: base64.encode(masterKey),
        dekB64: base64.encode(dek),
        saltB64: pull.salt,
        params: params,
        version: pull.version,
        lastSyncedAtMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  /// Pull-merge-push. Retries once on a version conflict.
  Future<void> syncNow() async {
    final state = await loadState();
    if (state == null) return;
    final client = _client(state.baseUrl, state.syncId);
    final dek = base64.decode(state.dekB64);
    final masterKey = base64.decode(state.masterKeyB64);
    final pwHash = base64.encode(await crypto.passwordHash(masterKey));

    var serverVersion = await _pullAndMerge(client, dek);

    for (var attempt = 0; attempt < 2; attempt++) {
      final blob = await gatherAll(db);
      final enc = await crypto.encryptBlob(utf8.encode(jsonEncode(blob)), dek);
      try {
        final version = await client.push(
          encryptedData: base64.encode(enc),
          salt: state.saltB64,
          passwordHash: pwHash,
          expectedVersion: serverVersion,
        );
        await _save(
          state.copyWith(
            version: version,
            lastSyncedAtMs: DateTime.now().millisecondsSinceEpoch,
          ),
        );
        return;
      } on SyncVersionConflict {
        // Someone else pushed. Merge their changes and retry once.
        serverVersion = await _pullAndMerge(client, dek);
      }
    }
  }

  /// Pulls the server blob (if any), merges it locally, returns the server
  /// version to use as expected_version on the next push.
  Future<int?> _pullAndMerge(SyncClient client, List<int> dek) async {
    final pull = await client.pull();
    if (pull == null) return null;
    final plaintext = await crypto.decryptBlob(
      base64.decode(pull.encryptedData),
      dek,
    );
    await restoreAll(
        db, jsonDecode(utf8.decode(plaintext)) as Map<String, dynamic>);
    return pull.version;
  }

  /// Disconnects sync on this device only. Nothing is deleted.
  Future<void> disconnect() => storage.delete(key: _stateKey);

  /// Deletes the synced data on the server, then disconnects locally.
  Future<void> purge() async {
    final state = await loadState();
    if (state != null) {
      final pwHash = base64.encode(
        await crypto.passwordHash(base64.decode(state.masterKeyB64)),
      );
      await _client(state.baseUrl, state.syncId).purge(pwHash);
    }
    await disconnect();
  }
}
