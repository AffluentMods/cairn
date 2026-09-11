// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// The app version baked into the User-Agent. NWS and Overpass require a
/// User-Agent that identifies the app (spec Sections 5.2, 5.5). Keep in sync
/// with pubspec `version`.
const String kCairnVersion = '0.1.0';

/// The User-Agent every Cairn request carries.
const String kUserAgent = 'Cairn/$kCairnVersion (contact@affluentlabs.dev)';

/// Builds the shared Dio client. One place sets timeouts, the User-Agent, and
/// (only in debug) request logging. Release builds NEVER log request URLs: they
/// contain coordinates (spec Section 9.5 security checklist).
Dio buildDioClient() {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: const {'User-Agent': kUserAgent},
      // Do not throw on 4xx; callers inspect status and fall back to cache.
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        request: false,
        requestHeader: false,
        requestBody: false,
        responseHeader: false,
        responseBody: false,
        // Method and status only, and only in debug. No URLs (coordinates).
        logPrint: (obj) => debugPrint('[dio] $obj'),
      ),
    );
  }

  return dio;
}
