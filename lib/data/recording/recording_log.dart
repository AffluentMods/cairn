// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import '../../domain/usecases/recording_engine.dart';

/// The durable recording log: one JSON line per accepted fix or pause
/// transition, appended and flushed as it happens, so a recording survives the
/// app or the service being killed (spec Phase 6 acceptance). Replaying the
/// file into a fresh [RecordingEngine] restores the exact live state.
class RecordingLogWriter {
  RecordingLogWriter(this.file);

  final File file;
  IOSink? _sink;

  Future<void> open() async {
    await file.parent.create(recursive: true);
    _sink = file.openWrite(mode: FileMode.append);
  }

  /// Appends [lines] and flushes, so a kill right after loses nothing.
  Future<void> append(List<String> lines) async {
    final sink = _sink;
    if (sink == null || lines.isEmpty) return;
    for (final l in lines) {
      sink.writeln(l);
    }
    await sink.flush();
  }

  Future<void> close() async {
    final sink = _sink;
    _sink = null;
    if (sink == null) return;
    await sink.flush();
    await sink.close();
  }
}

/// Replays every complete line of [file] into [engine]. A torn last line (the
/// process died mid-write) is skipped. Returns the number of lines applied.
Future<int> replayRecordingLog(File file, RecordingEngine engine) async {
  if (!await file.exists()) return 0;
  final lines = await file.readAsLines();
  return replayRecordingLines(lines, engine);
}

/// Pure variant of [replayRecordingLog] for a worker isolate or a test.
int replayRecordingLines(Iterable<String> lines, RecordingEngine engine) {
  var n = 0;
  for (final l in lines) {
    if (l.trim().isEmpty) continue;
    try {
      engine.replayLine(l);
      n++;
    } on FormatException {
      // torn line
    } on TypeError {
      // torn line
    }
  }
  return n;
}
