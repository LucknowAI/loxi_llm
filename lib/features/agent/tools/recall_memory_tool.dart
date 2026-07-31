import '../../chat/domain/message.dart';
import '../../chat/domain/message_role.dart';
import '../domain/tool.dart';

/// Searches conversation messages that fall outside the active prompt window
/// so the model can recover earlier context without relying on the rolling
/// summary alone.
class RecallMemoryTool extends Tool {
  RecallMemoryTool({
    required this.conversationId,
    required List<Message> Function(String conversationId) getMessages,
    this.summary = '',
    this.historyWindow = 20,
    this.maxResults = 5,
  }) : _getMessages = getMessages;

  final String conversationId;
  final List<Message> Function(String conversationId) _getMessages;
  final String summary;
  final int historyWindow;
  final int maxResults;

  @override
  String get name => 'recall_memory';

  @override
  String get description =>
      'Search older messages in this conversation that are no longer in the '
      'recent context window. Use when the user refers to something said earlier.';

  @override
  Map<String, Object?> get parameterSchema => const {
        'query': 'string — keywords to search for in older messages',
      };

  @override
  Future<String> call(Map<String, Object?> arguments) async {
    final query = (arguments['query'] as String?)?.trim() ?? '';
    if (query.isEmpty) return 'Error: "query" argument is required.';

    try {
      final all = _getMessages(conversationId);
      final outsideWindow = all.length > historyWindow
          ? all.sublist(0, all.length - historyWindow)
          : <Message>[];

      final needle = query.toLowerCase();
      final matches = outsideWindow
          .where((m) => m.content.toLowerCase().contains(needle))
          .take(maxResults)
          .toList();

      if (matches.isEmpty) {
        if (summary.isNotEmpty && summary.toLowerCase().contains(needle)) {
          return 'Rolling summary of older turns:\n$summary';
        }
        if (outsideWindow.isEmpty) {
          return 'No older messages outside the recent window yet.';
        }
        return 'No matching messages found in older conversation history.';
      }

      final buffer = StringBuffer();
      for (var i = 0; i < matches.length; i++) {
        final m = matches[i];
        final role = m.role == MessageRole.user ? 'user' : 'assistant';
        buffer.write('[${i + 1}] ($role) ${m.content}');
        if (i < matches.length - 1) buffer.writeln();
      }
      return buffer.toString();
    } catch (e) {
      return 'Error recalling memory: $e';
    }
  }
}
