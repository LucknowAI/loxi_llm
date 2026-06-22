import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Severity levels for [AppLogger].
enum LogLevel { debug, info, warn, error }

extension LogLevelLabel on LogLevel {
  String get label => switch (this) {
        LogLevel.debug => 'DEBUG',
        LogLevel.info => 'INFO',
        LogLevel.warn => 'WARN',
        LogLevel.error => 'ERROR',
      };
}

/// A single log line.
class LogEntry {
  const LogEntry({
    required this.time,
    required this.level,
    required this.tag,
    required this.message,
  });

  final DateTime time;
  final LogLevel level;
  final String tag;
  final String message;

  String format() =>
      '${time.toIso8601String()} [${level.label}] $tag: $message';
}

/// App-wide logger with an in-memory ring buffer (for the log viewer) and a
/// persisted file (so logs survive a native crash, which Dart cannot catch).
///
/// Use [flush] before invoking risky native code so the last lines are on disk
/// even if the process aborts mid-call.
class AppLogger {
  AppLogger._();

  static final AppLogger instance = AppLogger._();

  static const int _maxBufferEntries = 2000;

  final ListQueue<LogEntry> _buffer = ListQueue<LogEntry>();
  final StreamController<LogEntry> _controller =
      StreamController<LogEntry>.broadcast();

  IOSink? _sink;
  File? _file;

  /// Broadcast stream of new entries, for the live log viewer.
  Stream<LogEntry> get stream => _controller.stream;

  /// Snapshot of buffered entries (oldest first).
  List<LogEntry> get entries => _buffer.toList(growable: false);

  /// Absolute path of the on-disk log file, or null before [init].
  String? get filePath => _file?.path;

  /// Open the persisted log file. Safe to call once at startup; failures are
  /// swallowed so logging never takes the app down.
  Future<void> init() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/loki_llm.log');
      // Roll the file if it grows large so it stays shareable.
      if (await file.exists() && await file.length() > 2 * 1024 * 1024) {
        await file.writeAsString('');
      }
      _file = file;
      _sink = file.openWrite(mode: FileMode.writeOnlyAppend);
      log(LogLevel.info, 'AppLogger',
          '===== session start ===== file: ${file.path}');
    } catch (e) {
      // Fall back to in-memory only.
      debugPrint('AppLogger init failed: $e');
    }
  }

  void debug(String tag, String message) =>
      log(LogLevel.debug, tag, message);

  void info(String tag, String message) => log(LogLevel.info, tag, message);

  void warn(String tag, String message) => log(LogLevel.warn, tag, message);

  void error(String tag, String message, [Object? err, StackTrace? st]) {
    final full = [
      message,
      if (err != null) 'error: $err',
      if (st != null) st.toString(),
    ].join('\n');
    log(LogLevel.error, tag, full);
  }

  void log(LogLevel level, String tag, String message) {
    final entry = LogEntry(
      time: DateTime.now(),
      level: level,
      tag: tag,
      message: message,
    );

    _buffer.addLast(entry);
    while (_buffer.length > _maxBufferEntries) {
      _buffer.removeFirst();
    }
    if (!_controller.isClosed) _controller.add(entry);

    final line = entry.format();
    if (kDebugMode) debugPrint(line);
    try {
      _sink?.writeln(line);
    } catch (_) {
      // Ignore I/O failures — never crash on logging.
    }
  }

  /// Force buffered file bytes to the OS so they survive a subsequent native
  /// crash. Cheap; await this before calling into native inference.
  Future<void> flush() async {
    try {
      await _sink?.flush();
    } catch (_) {
      // Ignore.
    }
  }

  /// Read the full persisted log file (survives restarts/crashes). Returns an
  /// empty string if logging to disk is unavailable or the file is missing.
  Future<String> readFile() async {
    try {
      final file = _file;
      if (file == null || !await file.exists()) return '';
      return await file.readAsString();
    } catch (e) {
      return 'Failed to read log file: $e';
    }
  }

  /// Clear the in-memory buffer and truncate the file.
  Future<void> clear() async {
    _buffer.clear();
    try {
      await _file?.writeAsString('');
    } catch (_) {
      // Ignore.
    }
    info('AppLogger', 'Logs cleared');
  }

  /// Full buffered log as a single string, for copy/share.
  String dump() => _buffer.map((e) => e.format()).join('\n');
}
