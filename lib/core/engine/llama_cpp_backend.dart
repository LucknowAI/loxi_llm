import 'package:llama_engine/llama_engine.dart';
import 'inference_backend.dart';

/// InferenceBackend implementation for GGUF files via llama_engine (llama.cpp).
///
/// [LlamaEngine.instance] is a singleton — only one GGUF model can be loaded at
/// a time. [unloadModel] must be called before loading a new model.
final class LlamaCppBackend extends InferenceBackend {
  final _llama = LlamaEngine.instance;

  @override
  bool get isLoaded => _llama.isModelLoaded;

  @override
  Future<void> loadModel(String path) async {
    final success = await _llama.loadModel(
      LlamaConfig(
        modelPath: path,
        nThreads: 4,
        contextSize: 2048,
        batchSize: 512,
      ),
    );
    if (!success) {
      throw StateError('LlamaCppBackend: failed to load model at $path');
    }
  }

  // Generation tuning — single source of truth so [generationParams] always
  // matches what [generate] actually uses. topP/topK/repeatPenalty fall back to
  // GenerationParams defaults (0.95 / 40 / 1.1).
  static const int _maxTokens = 512;
  static const double _temperature = 0.7;

  @override
  Map<String, Object?> get generationParams => const {
        'maxTokens': _maxTokens,
        'temperature': _temperature,
        'topP': 0.95,
        'topK': 40,
        'repeatPenalty': 1.1,
        'contextSize': 2048,
        'batchSize': 512,
      };

  @override
  Stream<String> generate(String prompt,
      {List<String> stopSequences = const []}) {
    return _llama.generateStream(
      GenerationParams(
        prompt: prompt,
        maxTokens: _maxTokens,
        temperature: _temperature,
        stopSequences: stopSequences,
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
  }
}
