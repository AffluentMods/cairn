// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:cairn/core/diagnostics/crash_log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;
  late CrashLog log;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('cairn_diag');
    log = await CrashLog.init(dir);
  });
  tearDown(() async {
    await log.whenWritten; // release the file before deleting the temp dir
    try {
      if (dir.existsSync()) await dir.delete(recursive: true);
    } on FileSystemException {
      // A locked temp dir on Windows must not fail the test.
    }
  });

  test('redacts anything shaped like a coordinate pair', () async {
    log.record('flutter', 'failed at 46.1234, -121.5678 while routing');
    final out = log.readAll();
    expect(out, contains('[redacted]'));
    expect(out, isNot(contains('46.1234')));
    expect(out, isNot(contains('-121.5678')));
  });

  test('clear empties the log and the file', () async {
    log.record('async', 'boom');
    expect(log.isEmpty, isFalse);
    await log.clear();
    expect(log.isEmpty, isTrue);
    expect(log.readAll(), isEmpty);
  });

  test('a stall is rate-limited to avoid flooding', () async {
    log.recordStall(const Duration(milliseconds: 300));
    log.recordStall(const Duration(milliseconds: 400)); // within 1 s, dropped
    expect('\n'.allMatches(log.readAll()).length, 0); // exactly one line
    expect(log.readAll(), contains('300 ms'));
    expect(log.readAll(), isNot(contains('400 ms')));
  });
}
