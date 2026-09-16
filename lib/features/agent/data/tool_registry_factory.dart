import '../../chat/data/message_repository.dart';
import '../../documents/data/document_chunk_repository.dart';
import '../../documents/data/document_repository.dart';
import '../tools/calculator_tool.dart';
import '../tools/datetime_tool.dart';
import '../tools/document_search_tool.dart';
import '../tools/get_settings_tool.dart';
import '../tools/list_documents_tool.dart';
import '../tools/recall_memory_tool.dart';
import '../tools/unit_convert_tool.dart';
import '../agent_tool_catalog.dart';
import '../domain/tool.dart';
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
    required this.chunkSize,
    this.summary = '',
    this.historyWindow = 20,
  });

  final String conversationId;
  final MessageRepository messageRepo;
  final DocumentRepository documentRepo;
  final DocumentChunkRepository chunkRepo;
  final Future<List<double>> Function(String query) embedQuery;
  final int topK;
  final int chunkSize;
  final String summary;
  final int historyWindow;
}

/// Builds the default tool registry for agent-mode conversations.
ToolRegistry buildDefaultToolRegistry(
  ToolRegistryDeps deps, {
  Set<String>? enabledToolNames,
}) {
  final enabled = enabledToolNames ?? defaultEnabledToolNames();
  final tools = <Tool>[
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
    GetSettingsTool(chunkSize: deps.chunkSize, topK: deps.topK),
  ].where((t) => enabled.contains(t.name)).toList();

  return ToolRegistry(tools);
}
