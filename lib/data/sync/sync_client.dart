// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:dio/dio.dart';

/// Thrown on a push when the server version moved ahead (optimistic concurrency).
class SyncVersionConflict implements Exception {
  SyncVersionConflict(this.serverVersion);
  final int serverVersion;
}

/// Thrown when the server rejects the write verification (wrong passphrase hash).
class SyncVerificationFailed implements Exception {}

/// The pulled blob and its metadata.
class SyncPullResult {
  const SyncPullResult({
    required this.encryptedData,
    required this.salt,
    required this.version,
    this.wrappedDekPassword,
    this.argon2Params,
  });
  final String encryptedData; // base64
  final String salt; // base64
  final int version;
  final String? wrappedDekPassword; // base64
  final Map<String, dynamic>? argon2Params;
}

/// HTTP client for the Cairn sync server (accountless E2E). The bearer token is
/// the sync id. Wire contract matches the cairn-sync backend.
class SyncClient {
  SyncClient({
    required this.dio,
    required this.baseUrl,
    required this.syncId,
    this.deviceId,
  });

  final Dio dio;
  final String baseUrl; // e.g. https://sync.affluentlabs.dev
  final String syncId;
  final String? deviceId;

  Options get _auth => Options(
        headers: {'Authorization': 'Bearer $syncId'},
        responseType: ResponseType.json,
        validateStatus: (s) => s != null && s < 500,
      );

  Future<int> push({
    required String encryptedData,
    required String salt,
    required String passwordHash,
    int? expectedVersion,
    String? wrappedDekPassword,
    Map<String, dynamic>? argon2Params,
  }) async {
    final res = await dio.post<dynamic>(
      '$baseUrl/v1/sync/push',
      options: _auth,
      data: {
        'encrypted_data': encryptedData,
        'salt': salt,
        'password_hash': passwordHash,
        if (deviceId != null) 'device_id': deviceId,
        if (expectedVersion != null) 'expected_version': expectedVersion,
        if (wrappedDekPassword != null)
          'wrapped_dek_password': wrappedDekPassword,
        if (argon2Params != null) 'argon2_params': argon2Params,
      },
    );
    final code = res.statusCode ?? 0;
    if (code == 409) {
      final sv = (res.data?['server_version'] as num?)?.toInt() ?? 0;
      throw SyncVersionConflict(sv);
    }
    if (code == 403) throw SyncVerificationFailed();
    if (code != 200) {
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        message: 'push failed ($code)',
      );
    }
    return (res.data?['version'] as num).toInt();
  }

  /// Returns null if the server has no blob yet (404).
  Future<SyncPullResult?> pull() async {
    final res = await dio.get<dynamic>('$baseUrl/v1/sync/pull', options: _auth);
    if (res.statusCode == 404) return null;
    if (res.statusCode != 200 || res.data is! Map) {
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        message: 'pull failed (${res.statusCode})',
      );
    }
    final d = res.data as Map;
    return SyncPullResult(
      encryptedData: d['encrypted_data'] as String,
      salt: d['salt'] as String,
      version: (d['version'] as num).toInt(),
      wrappedDekPassword: d['wrapped_dek_password'] as String?,
      argon2Params: (d['argon2_params'] as Map?)?.cast<String, dynamic>(),
    );
  }

  Future<({bool hasData, int version})> status() async {
    final res =
        await dio.get<dynamic>('$baseUrl/v1/sync/status', options: _auth);
    final d = (res.data as Map?) ?? const {};
    return (
      hasData: d['has_data'] == true,
      version: (d['version'] as num?)?.toInt() ?? 0,
    );
  }

  Future<bool> verifyPassword(String passwordHash) async {
    final res = await dio.post<dynamic>(
      '$baseUrl/v1/sync/verify-password',
      options: _auth,
      data: {'password_hash': passwordHash},
    );
    return (res.data as Map?)?['valid'] == true;
  }

  Future<void> purge(String passwordHash) async {
    await dio.post<dynamic>(
      '$baseUrl/v1/sync/purge',
      options: _auth,
      data: {'password_hash': passwordHash},
    );
  }
}
