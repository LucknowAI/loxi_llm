/// Metadata for built-in agent tools (settings UI + defaults).
class AgentToolInfo {
  const AgentToolInfo({required this.name, required this.label});

  final String name;
  final String label;
}

/// All built-in agent tools in registration order.
const kAgentToolCatalog = [
  AgentToolInfo(name: 'calculator', label: 'Calculator'),
  AgentToolInfo(name: 'datetime', label: 'Date & time'),
  AgentToolInfo(name: 'document_search', label: 'Document search'),
  AgentToolInfo(name: 'recall_memory', label: 'Recall memory'),
  AgentToolInfo(name: 'list_documents', label: 'List documents'),
  AgentToolInfo(name: 'unit_convert', label: 'Unit converter'),
];

/// Default enabled tool names (all on).
Set<String> defaultEnabledToolNames() =>
    kAgentToolCatalog.map((t) => t.name).toSet();
