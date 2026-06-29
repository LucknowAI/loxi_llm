import '../../documents/domain/document_chunk.dart';
import '../domain/tool.dart';

/// Searches the user's ingested documents and returns the most relevant
/// passages. Dependencies are injected as functions so the tool stays decoupled
/// from the embedding service / ObjectBox and is trivially testable.
class DocumentSearchTool extends Tool {
  DocumentSearchTool({
    required Future<List<double>> Function(String query) embed,
    required List<DocumentChunk> Function(List<double> vector, int topK) search,
    this.topK = 5,
  })  : _embed = embed,
        _search = search;

  final Future<List<double>> Function(String query) _embed;
  final List<DocumentChunk> Function(List<double> vector, int topK) _search;
  final int topK;

  @override
  String get name => 'document_search';

  @override
  String get description =>
      "Search the user's ingested documents for passages relevant to a query. "
      'Use when the question may be answered from their documents.';

  @override
  Map<String, Object?> get parameterSchema => const {
        'query': 'string — what to look for in the documents',
      };

  @override
  Future<String> call(Map<String, Object?> arguments) async {
    final query = (arguments['query'] as String?)?.trim() ?? '';
    if (query.isEmpty) return 'Error: "query" argument is required.';
    try {
      final vector = await _embed(query);
      final chunks = _search(vector, topK);
      if (chunks.isEmpty) {
        return 'No matching passages found in the documents.';
      }
      final buffer = StringBuffer();
      for (var i = 0; i < chunks.length; i++) {
        buffer.write('[${i + 1}] ${chunks[i].content}');
        if (i < chunks.length - 1) buffer.writeln();
      }
      return buffer.toString();
    } catch (e) {
      return 'Error searching documents: $e';
    }
  }
}
