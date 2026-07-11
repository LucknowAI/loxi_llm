import 'dart:async';

import 'package:flutter/services.dart';

/// Model-load configuration.
class LlamaConfig {
  const LlamaConfig({
    required this.modelPath,
    this.nThreads = 4,
    this.contextSize = 2048,
    this.batchSize = 512,
  });

  final String modelPath;
  final int nThreads;
  final int contextSize;
  final int batchSize;

  Map<String, dynamic> toMap() => {
        'modelPath': modelPath,
        'nThreads': nThreads,
        'contextSize': contextSize,
        'batchSize': batchSize,
      };
}

/// Per-generation parameters.
class GenerationParams {
  const GenerationParams({
    required this.prompt,
    this.maxTokens = 512,
    this.temperature = 0.7,
    this.topP = 0.95,
    this.topK = 40,
    this.repeatPenalty = 1.1,
    this.stopSequences = const [],
    this.grammar,
  });

  final String prompt;
  final int maxTokens;
  final double temperature;
  final double topP;
  final int topK;
  final double repeatPenalty;

  /// Strings at which generation halts (the model's turn terminators).
  final List<String> stopSequences;

  /// Reserved for GBNF constrained decoding (currently ignored by the engine).
  final String? grammar;

  Map<String, dynamic> toMap() => {
        'prompt': prompt,
        'maxTokens': maxTokens,
        'temperature': temperature,
        'topP': topP,
        'topK': topK,
        'repeatPenalty': repeatPenalty,
        'stopSequences': stopSequences,
        if (grammar != null) 'grammar': grammar,
      };
}

/// MIT-licensed llama.cpp GGUF engine (Android). One model loaded at a time.
class LlamaEngine {
  LlamaEngine._();

  static final LlamaEngine instance = LlamaEngine._();

  static const MethodChannel _channel = MethodChannel('llama_engine');
  static const EventChannel _events = EventChannel('llama_engine/stream');

  bool _loaded = false;
  bool get isModelLoaded => _loaded;

  /// Load a GGUF model. Returns true on success.
  Future<bool> loadModel(LlamaConfig config) async {
    final ok = await _channel.invokeMethod<bool>('loadModel', config.toMap());
    _loaded = ok ?? false;
    return _loaded;
  }

  /// Stream generated tokens for [params]. Tokens arrive over an event channel
  /// as the native side produces them; the method call itself is fired without
  /// awaiting so streaming is incremental (not buffered until completion).
  Stream<String> generateStream(GenerationParams params) async* {
    if (!_loaded) {
      throw StateError('LlamaEngine: no model loaded');
    }

    final controller = StreamController<String>();
    late final StreamSubscription<dynamic> sub;
    sub = _events.receiveBroadcastStream().listen(
      (event) {
        if (event is String) controller.add(event);
      },
      onError: controller.addError,
      onDone: controller.close,
    );

    try {
      // Let the event-channel onListen install the native sink before the
      // generation begins, then fire generation without awaiting it.
      await Future<void>.delayed(Duration.zero);
      final generation = _channel.invokeMethod('generateStream', params.toMap());
      unawaited(generation.catchError((Object e) {
        if (!controller.isClosed) controller.addError(e);
      }));
      yield* controller.stream;
    } finally {
      await sub.cancel();
      if (!controller.isClosed) await controller.close();
    }
  }

  /// Request that an in-flight [generateStream] stop as soon as possible.
  Future<void> stopGeneration() =>
      _channel.invokeMethod<void>('stopGeneration');

  /// Unload the current model and free native resources.
  Future<void> unloadModel() async {
    await _channel.invokeMethod<void>('unloadModel');
    _loaded = false;
  }
}
