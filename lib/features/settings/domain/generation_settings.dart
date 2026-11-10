import '../../../core/engine/chat_template.dart';

/// Sampling and load settings for one model.
///
/// Missing saved values fall back to [defaultsFor]. Reply length stays at
/// least [promptRoom] tokens under the context size.
class GenerationSettings {
  const GenerationSettings({
    required this.temperature,
    required this.maxTokens,
    required this.topK,
    required this.topP,
    required this.repeatPenalty,
    required this.nThreads,
    required this.contextSize,
    required this.batchSize,
  });

  static const promptRoom = 256;
  static const summarizerMaxTokens = 512;
  static const contextChoices = [512, 1024, 2048, 4096];
  static const batchChoices = [128, 256, 512];

  final double temperature;
  final int maxTokens;
  final int topK;
  final double topP;
  final double repeatPenalty;
  final int nThreads;
  final int contextSize;
  final int batchSize;

  /// True when threads, context, or batch differ from the model that is loaded.
  bool differsFromLoaded({
    required int nThreads,
    required int contextSize,
    required int batchSize,
  }) =>
      this.nThreads != nThreads ||
      this.contextSize != contextSize ||
      this.batchSize != batchSize;

  /// Reply length that fits [loadedContext], the context from the last load.
  /// A larger context saved for the next load does not raise this.
  int maxTokensForLoadedContext(int loadedContext) {
    final limit = loadedContext - promptRoom;
    return maxTokens.clamp(64, limit < 64 ? 64 : limit);
  }

  factory GenerationSettings.defaultsFor(String modelId) {
    final lfm3 = ChatTemplate.forModelId(modelId).kind == ChatTemplateKind.lfm3;
    return GenerationSettings(
      temperature: lfm3 ? 0.1 : 0.7,
      maxTokens: 512,
      topK: 40,
      topP: 0.95,
      repeatPenalty: 1.1,
      nThreads: 4,
      contextSize: 2048,
      batchSize: 512,
    );
  }

  GenerationSettings clamped() {
    final context = _nearest(contextSize, contextChoices);
    final batch = _nearest(batchSize, batchChoices);
    return GenerationSettings(
      temperature: temperature.clamp(0, 2),
      maxTokens: maxTokens.clamp(64, context - promptRoom),
      topK: topK.clamp(1, 100),
      topP: topP.clamp(0.05, 1),
      repeatPenalty: repeatPenalty.clamp(1, 1.5),
      nThreads: nThreads.clamp(1, 8),
      contextSize: context,
      batchSize: batch,
    );
  }

  GenerationSettings copyWith({
    double? temperature,
    int? maxTokens,
    int? topK,
    double? topP,
    double? repeatPenalty,
    int? nThreads,
    int? contextSize,
    int? batchSize,
  }) {
    return GenerationSettings(
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      topK: topK ?? this.topK,
      topP: topP ?? this.topP,
      repeatPenalty: repeatPenalty ?? this.repeatPenalty,
      nThreads: nThreads ?? this.nThreads,
      contextSize: contextSize ?? this.contextSize,
      batchSize: batchSize ?? this.batchSize,
    );
  }
}

int _nearest(int value, List<int> choices) {
  var best = choices.first;
  for (final choice in choices) {
    if ((choice - value).abs() < (best - value).abs()) best = choice;
  }
  return best;
}
