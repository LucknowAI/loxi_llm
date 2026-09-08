import '../domain/conversation.dart';
import '../domain/message.dart';
import '../domain/message_role.dart';

/// Formats a conversation transcript as Markdown for export or clipboard.
String exportConversationMarkdown({
  required Conversation conversation,
  required List<Message> messages,
  DateTime? exportedAt,
}) {
  final when = exportedAt ?? DateTime.now();
  final buffer = StringBuffer()
    ..writeln('# ${conversation.title}')
    ..writeln()
    ..writeln(
      '> Exported from Loki LLM · ${_formatTimestamp(when.millisecondsSinceEpoch)}',
    );

  if (conversation.systemPrompt.trim().isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('## System prompt')
      ..writeln()
      ..writeln(conversation.systemPrompt.trim());
  }

  buffer
    ..writeln()
    ..writeln('---')
    ..writeln();

  for (final msg in messages) {
    if (msg.role == MessageRole.system) continue;
    final label = msg.role == MessageRole.user ? 'User' : 'Assistant';
    buffer
      ..writeln('**$label** · ${_formatTimestamp(msg.createdAtMs)}')
      ..writeln();
    if (msg.imagePath != null) {
      buffer
        ..writeln('_[image attached]_')
        ..writeln();
    }
    buffer
      ..writeln(msg.content.trim())
      ..writeln();
  }

  return buffer.toString().trimRight();
}

String _formatTimestamp(int ms) {
  final dt = DateTime.fromMillisecondsSinceEpoch(ms);
  String two(int v) => v.toString().padLeft(2, '0');
  return '${dt.year}-${two(dt.month)}-${two(dt.day)} '
      '${two(dt.hour)}:${two(dt.minute)}';
}
