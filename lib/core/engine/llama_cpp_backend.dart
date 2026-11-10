import 'package:llama_engine/llama_engine.dart';
import 'inference_backend.dart';

/// InferenceBackend implementation for GGUF files via llama_engine (llama.cpp).
///
/// [LlamaEngine.instance] is a singleton — only one GGUF model can be loaded at
/// a time. [unloadModel] must be called before loading a new model.
final class LlamaCppBackend extends InferenceBackend {
  final _llama = LlamaEngine.instance;

  int _nThreads = 4;
  int _contextSize = 2048;
  int _batchSize = 512;
  int _maxTokens = 512;
  double _temperature = 0.7;
  int _topK = 40;
  double _topP = 0.95;
  double _repeatPenalty = 1.1;

  @override
  bool get isLoaded => _llama.isModelLoaded;

  // Cached at loadModel time — see the class doc comment above for why this
  // isn't a live native query on every access.
  bool _supportsVision = false;

  @override
  bool get supportsVision => _supportsVision;

  @override
  Future<String> mediaMarker() => _llama.mediaMarker();

  @override
  Future<void> loadModel(
    String path, {
    String? mmprojPath,
    int nThreads = 4,
    int contextSize = 2048,
    int batchSize = 512,
  }) async {
    _nThreads = nThreads;
    _contextSize = contextSize;
    _batchSize = batchSize;
    final success = await _llama.loadModel(
      LlamaConfig(
        modelPath: path,
        nThreads: nThreads,
        contextSize: contextSize,
        batchSize: batchSize,
        mmprojPath: mmprojPath,
      ),
    );
    if (!success) {
      throw StateError('LlamaCppBackend: failed to load model at $path');
    }
    try {
      _supportsVision = await _llama.supportsVision();
    } catch (_) {
      try {
        await _llama.unloadModel();
      } catch (_) {
        // Best-effort cleanup; the original exception below is what matters.
      }
      rethrow;
    }
  }

  @override
  Map<String, Object?> get generationParams => {
        'maxTokens': _maxTokens,
        'temperature': _temperature,
        'topP': _topP,
        'topK': _topK,
        'repeatPenalty': _repeatPenalty,
        'contextSize': _contextSize,
        'batchSize': _batchSize,
        'nThreads': _nThreads,
      };

  @override
  Stream<String> generate(
    String prompt, {
    List<String> stopSequences = const [],
    String? grammar,
    List<String> imagePaths = const [],
    int maxTokens = 512,
    double temperature = 0.7,
    int topK = 40,
    double topP = 0.95,
    double repeatPenalty = 1.1,
  }) {
    _maxTokens = maxTokens;
    _temperature = temperature;
    _topK = topK;
    _topP = topP;
    _repeatPenalty = repeatPenalty;
    return _llama.generateStream(
      GenerationParams(
        prompt: prompt,
        maxTokens: maxTokens,
        temperature: temperature,
        topK: topK,
        topP: topP,
        repeatPenalty: repeatPenalty,
        stopSequences: stopSequences,
        grammar: grammar,
        imagePaths: imagePaths,
      ),
    );
  }

  @override
  Future<void> stop() async {
    await _llama.stopGeneration();
  }

  @override
  Future<void> unloadModel() async {
    await _llama.unloadModel();
    _supportsVision = false;
  }
}
