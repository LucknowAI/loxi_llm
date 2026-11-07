import '../domain/tool.dart';

/// Reports the loaded model so the agent can answer "what am I talking to?"
class ModelInfoTool extends Tool {
  ModelInfoTool({
    required this.modelName,
    required this.backendName,
    required this.agentCapable,
    required this.ragEnabled,
    this.contextSize,
  });

  final String modelName;
  final String backendName;
  final int? contextSize;
  final bool agentCapable;
  final bool ragEnabled;

  @override
  String get name => 'model_info';

  @override
  String get description =>
      'Report the currently loaded model, inference backend, context size, '
      'whether this model supports agent/tool-calling, and whether '
      'retrieval-augmented generation (RAG) is enabled for this conversation.';

  @override
  Map<String, Object?> get parameterSchema => const {};

  @override
  Future<String> call(Map<String, Object?> arguments) async {
    if (modelName.isEmpty) return 'No model is currently loaded.';
    return 'Model: $modelName\n'
        'Backend: $backendName\n'
        'Context size: ${contextSize ?? 'unknown'}\n'
        'Agent capable: ${agentCapable ? 'yes' : 'no'}\n'
        'Retrieval-augmented generation (RAG) enabled for this chat: '
        '${ragEnabled ? 'yes' : 'no'}';
  }
}
