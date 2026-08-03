import '../../documents/domain/document.dart';
import '../domain/tool.dart';

/// Lists documents the user has ingested into the knowledge base.
class ListDocumentsTool extends Tool {
  ListDocumentsTool({required List<Document> Function() listDocuments})
      : _listDocuments = listDocuments;

  final List<Document> Function() _listDocuments;

  @override
  String get name => 'list_documents';

  @override
  String get description =>
      'List the documents the user has imported for document search.';

  @override
  Map<String, Object?> get parameterSchema => const {};

  @override
  Future<String> call(Map<String, Object?> arguments) async {
    try {
      final docs = _listDocuments();
      if (docs.isEmpty) {
        return 'No documents have been imported yet.';
      }
      final buffer = StringBuffer();
      for (var i = 0; i < docs.length; i++) {
        final d = docs[i];
        buffer.write(
            '[${i + 1}] ${d.name} (${d.format}, ${d.chunkCount} chunks)');
        if (i < docs.length - 1) buffer.writeln();
      }
      return buffer.toString();
    } catch (e) {
      return 'Error listing documents: $e';
    }
  }
}
