/// Abstract base class for all LLM inference backends.
///
/// Use `extends InferenceBackend` (not `implements`) to inherit
/// UnimplementedError defaults — new methods added here are safely
/// caught at runtime for any subclass that forgets to override.
base class InferenceBackend {
  /// [mmprojPath], when non-null, loads a companion mmproj vision projector
  /// alongside the base model. Backends that don't support vision ignore it.
  Future<void> loadModel(String path, {String? mmprojPath}) =>
      throw UnimplementedError('loadModel not implemented');

  /// Stream the model's response to [prompt].
  ///
  /// [stopSequences] are strings at which generation should halt (the model's
  /// turn terminators, supplied by the chat template). Backends that handle
  /// stopping internally (e.g. MediaPipe) may ignore them.
  ///
  /// [imagePaths] are file paths to images to ground the response in. Empty
  /// by default — existing text-only call sites are unaffected.
  Stream<String> generate(
    String prompt, {
    List<String> stopSequences = const [],
    String? grammar,
    List<String> imagePaths = const [],
  }) =>
      throw UnimplementedError('generate not implemented');

  Future<void> unloadModel() =>
      throw UnimplementedError('unloadModel not implemented');

  /// Request that an in-flight [generate] stop as soon as possible. The partial
  /// output already streamed is kept. Default is a no-op for backends that
  /// cannot be interrupted.
  Future<void> stop() async {}

  bool get isLoaded => throw UnimplementedError('isLoaded not implemented');

  /// Whether the currently loaded model can accept images via [generate]'s
  /// [imagePaths]. `false` by default — this is a real answer, not an
  /// unimplemented stub, since most backends/models are text-only.
  bool get supportsVision => false;

  /// Generation parameters this backend applies (temperature, maxTokens, ...).
  /// Reported for diagnostics/model-I/O logging; defaults to empty.
  Map<String, Object?> get generationParams => const {};

  /// Stub for Phase 5 EmbeddingService — do not implement here.
  Future<List<double>> embeddings(String text) =>
      throw UnimplementedError('embeddings: use Phase 5 EmbeddingService');
}
