/// Abstract base class for all LLM inference backends.
///
/// Use `extends InferenceBackend` (not `implements`) to inherit
/// UnimplementedError defaults — new methods added here are safely
/// caught at runtime for any subclass that forgets to override.
base class InferenceBackend {
  Future<void> loadModel(String path) =>
      throw UnimplementedError('loadModel not implemented');

  Stream<String> generate(String prompt) =>
      throw UnimplementedError('generate not implemented');

  Future<void> unloadModel() =>
      throw UnimplementedError('unloadModel not implemented');

  bool get isLoaded => throw UnimplementedError('isLoaded not implemented');

  /// Stub for Phase 5 EmbeddingService — do not implement here.
  Future<List<double>> embeddings(String text) =>
      throw UnimplementedError('embeddings: use Phase 5 EmbeddingService');
}
