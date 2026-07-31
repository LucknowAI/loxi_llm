import '../../chat/data/message_repository.dart';
import '../../documents/data/document_chunk_repository.dart';
import '../../documents/data/document_repository.dart';
import '../tools/calculator_tool.dart';
import '../tools/datetime_tool.dart';
import '../tools/document_search_tool.dart';
import '../tools/list_documents_tool.dart';
import '../tools/recall_memory_tool.dart';
import '../tools/unit_convert_tool.dart';
import 'tool_registry.dart';

/// Dependencies required to assemble the default [ToolRegistry].
class ToolRegistryDeps {
  const ToolRegistryDeps({
    required this.conversationId,
    required this.messageRepo,
    required this.documentRepo,
    required this.chunkRepo,
    required this.embedQuery,
    required this.topK,
    this.summary = '',
    this.historyWindow = 20,
  });

  final String conversationId;
  final MessageRepository messageRepo;
  final DocumentRepository documentRepo;
  final DocumentChunkRepository chunkRepo;
  final Future<List<double>> Function(String query) embedQuery;
  final int topK;
  final String summary;
  final int historyWindow;
}

/// Builds the default tool registry for agent-mode conversations.
ToolRegistry buildDefaultToolRegistry(ToolRegistryDeps deps) {
  return ToolRegistry([
    CalculatorTool(),
    DateTimeTool(),
    DocumentSearchTool(
      embed: deps.embedQuery,
      search: (vec, k) => deps.chunkRepo.findSimilar(vec, topK: k),
      topK: deps.topK,
    ),
    RecallMemoryTool(
      conversationId: deps.conversationId,
      getMessages: deps.messageRepo.getMessages,
      summary: deps.summary,
      historyWindow: deps.historyWindow,
    ),
    ListDocumentsTool(listDocuments: deps.documentRepo.getAll),
    UnitConvertTool(),
  ]);
}
