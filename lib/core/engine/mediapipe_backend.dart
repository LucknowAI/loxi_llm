import 'package:flutter_gemma/flutter_gemma.dart';
import 'inference_backend.dart';

/// InferenceBackend implementation for Gemma .task files via flutter_gemma.
///
/// This backend calls [FlutterGemma.installModel().fromFile(path).install()]
/// to register the local .task file, then [FlutterGemma.getActiveModel()]
/// to get a ready-to-use [InferenceModel].
final class MediaPipeBackend extends InferenceBackend {
  InferenceModel? _model;
  InferenceChat? _chat;
  bool _loaded = false;

  // Configured at load time via getActiveModel(maxTokens: 1024).
  static const int _maxTokens = 1024;

  @override
  bool get isLoaded => _loaded;

  @override
  Map<String, Object?> get generationParams => const {
        'maxTokens': _maxTokens,
      };

  @override
  Future<void> loadModel(String path) async {
    // Register the local .task file as the active inference model.
    await FlutterGemma.installModel(
      modelType: ModelType.gemmaIt,
      fileType: ModelFileType.task,
    ).fromFile(path).install();

    _model = await FlutterGemma.getActiveModel(maxTokens: _maxTokens);
    _loaded = true;
  }

  @override
  Stream<String> generate(String prompt,
      {List<String> stopSequences = const []}) async* {
    // flutter_gemma applies the model's own template and stop handling, so
    // [stopSequences] is intentionally ignored here.
    final model = _model;
    if (model == null) throw StateError('MediaPipeBackend: model not loaded');

    // Create a fresh chat session for each generation call.
    _chat = await model.createChat();
    await _chat!.addQueryChunk(Message.text(text: prompt, isUser: true));

    await for (final response in _chat!.generateChatResponseAsync()) {
      if (response is TextResponse) {
        yield response.token;
      }
    }
  }

  @override
  Future<void> unloadModel() async {
    await _chat?.stopGeneration();
    _chat = null;
    _model = null;
    _loaded = false;
  }
}
