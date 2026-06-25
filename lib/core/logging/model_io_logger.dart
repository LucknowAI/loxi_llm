import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'model_io_trace.dart';

/// Records full model input/output traces, but only while enabled. Mirrors the
/// AppLogger pattern: an in-memory ring buffer for the viewer plus a persisted
/// JSONL file. When disabled, [record] is a no-op so there is zero overhead.
class ModelIoLogger {
  ModelIoLogger._();

  static final ModelIoLogger instance = ModelIoLogger._();

  static const int _maxBufferEntries = 200;
  static const int _maxFileBytes = 2 * 1024 * 1024;

  final ListQueue<ModelIoTrace> _buffer = ListQueue<ModelIoTrace>();
  final StreamController<ModelIoTrace> _controller =
      StreamController<ModelIoTrace>.broadcast();

  File? _file;

  /// Whether new traces are captured and persisted. Kept in sync with the
  /// "Model I/O logging" setting; defaults to off.
  bool enabled = false;

  /// Broadcast stream of newly recorded traces, for the live viewer.
  Stream<ModelIoTrace> get stream => _controller.stream;

  /// Buffered traces (oldest first).
  List<ModelIoTrace> get entries => _buffer.toList(growable: false);

  String? get filePath => _file?.path;

  /// Open the persisted JSONL file. Safe to call once at startup.
  Future<void> init() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      _file = File('${dir.path}/model_io.jsonl');
    } catch (e) {
      debugPrint('ModelIoLogger init failed: $e');
    }
  }

  /// Record a trace. No-op when [enabled] is false. Never throws.
  void record(ModelIoTrace trace) {
    if (!enabled) return;

    _buffer.addLast(trace);
    while (_buffer.length > _maxBufferEntries) {
      _buffer.removeFirst();
    }
    if (!_controller.isClosed) _controller.add(trace);

    unawaited(_appendToFile(trace));
  }

  Future<void> _appendToFile(ModelIoTrace trace) async {
    final file = _file;
    if (file == null) return;
    try {
      await file.writeAsString(
        '${trace.toJsonLine()}\n',
        mode: FileMode.writeOnlyAppend,
        flush: true,
      );
      // Roll the file if it grows too large: keep the most recent half.
      if (await file.length() > _maxFileBytes) {
        await _rollFile(file);
      }
    } catch (_) {
      // Never crash on logging.
    }
  }

  Future<void> _rollFile(File file) async {
    try {
      final lines = await file.readAsLines();
      final keep = lines.sublist(lines.length ~/ 2);
      await file.writeAsString('${keep.join('\n')}\n');
    } catch (_) {
      // Ignore.
    }
  }

  /// Read all persisted traces (survives restarts). Returns newest-last.
  Future<List<ModelIoTrace>> readAll() async {
    final file = _file;
    if (file == null || !await file.exists()) return const [];
    try {
      final lines = await file.readAsLines();
      return lines
          .map(ModelIoTrace.tryParseLine)
          .whereType<ModelIoTrace>()
          .toList();
    } catch (_) {
      return const [];
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
  }
}
