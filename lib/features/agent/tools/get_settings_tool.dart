import '../domain/tool.dart';

/// Reports the current RAG settings so the model can explain retrieval
/// behavior to the user.
class GetSettingsTool extends Tool {
  GetSettingsTool({required this.chunkSize, required this.topK});

  final int chunkSize;
  final int topK;

  @override
  String get name => 'get_settings';

  @override
  String get description =>
      'Report the current RAG settings (document chunk size and number of '
      'retrieved results) so you can explain retrieval behavior to the user.';

  @override
  Map<String, Object?> get parameterSchema => const {};

  @override
  Future<String> call(Map<String, Object?> arguments) async {
    return 'RAG chunk size: $chunkSize characters. '
        'Top K retrieved chunks: $topK.';
  }
}
