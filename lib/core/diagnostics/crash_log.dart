// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

/// A local, on-device diagnostics log with no third-party SDK (Fix Pass 1
/// X1.3.8). It records crashes, uncaught async errors, and (in debug) UI stalls
/// to a capped file the user can view, share, or clear from Settings >
/// Diagnostics. It never records coordinates.
class CrashLog {
  CrashLog._(this._file, this._entries);

  static CrashLog? _instance;
  static CrashLog? get instanceOrNull => _instance;

  final File _file;
  final List<String> _entries;
  static const _maxEntries = 200;
  DateTime _lastStall = DateTime.fromMillisecondsSinceEpoch(0);

  /// Serializes disk writes so successive records never race the same file.
  Future<void> _writeChain = Future<void>.value();

  /// Completes when every write requested so far has settled. Mainly for tests
  /// and for [clear], so a pending write cannot resurrect the file.
  Future<void> get whenWritten => _writeChain;

  /// Loads any existing log from [dir]. Call once at startup.
  static Future<CrashLog> init(Directory dir) async {
    final file = File('${dir.path}/diagnostics.log');
    var entries = <String>[];
    try {
      if (file.existsSync()) {
        entries = (await file.readAsLines())
            .where((l) => l.trim().isNotEmpty)
            .toList();
        if (entries.length > _maxEntries) {
          entries = entries.sublist(entries.length - _maxEntries);
        }
      }
    } on IOException {
      entries = [];
    }
    return _instance = CrashLog._(file, entries);
  }

  /// Records an entry. [kind] is a short tag (flutter, async, stall).
  void record(String kind, String message, {StackTrace? stack}) {
    final ts = DateTime.now().toUtc().toIso8601String();
    final head = _scrub(message).replaceAll('\n', ' ');
    final tail = stack == null
        ? ''
        : ' | ${_scrub(stack.toString()).split('\n').take(6).join(' / ')}';
    _entries.add('$ts [$kind] $head$tail');
    if (_entries.length > _maxEntries) {
      _entries.removeRange(0, _entries.length - _maxEntries);
    }
    _flush();
  }

  /// Records a UI stall, rate-limited so a rough patch does not flood the log.
  void recordStall(Duration blocked) {
    final now = DateTime.now();
    if (now.difference(_lastStall) < const Duration(seconds: 1)) return;
    _lastStall = now;
    record('stall', 'UI isolate blocked ${blocked.inMilliseconds} ms');
  }

  /// The whole log, oldest first, for the Diagnostics screen and sharing.
  String readAll() => _entries.join('\n');

  bool get isEmpty => _entries.isEmpty;

  Future<void> clear() async {
    _entries.clear();
    await _writeChain; // let any pending write finish before deleting
    try {
      if (_file.existsSync()) await _file.delete();
    } on IOException {
      // Nothing to clear.
    }
  }

  void _flush() {
    _writeChain = _writeChain.then((_) async {
      try {
        await _file.writeAsString('${_entries.join('\n')}\n');
      } on IOException {
        // A diagnostics write must never crash the app.
      }
    });
  }

  /// Redacts anything shaped like a lat,lon pair, so location never lands in a
  /// shareable log.
  static String _scrub(String s) => s.replaceAll(
        RegExp(r'-?\d{1,3}\.\d{3,}\s*,\s*-?\d{1,3}\.\d{3,}'),
        '[redacted]',
      );
}
