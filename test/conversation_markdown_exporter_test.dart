import 'package:flutter_test/flutter_test.dart';
import 'package:loki_llm/features/chat/application/conversation_markdown_exporter.dart';
import 'package:loki_llm/features/chat/domain/conversation.dart';
import 'package:loki_llm/features/chat/domain/message.dart';
import 'package:loki_llm/features/chat/domain/message_role.dart';

void main() {
  group('exportConversationMarkdown', () {
    const conversation = Conversation(
      id: 'conv-1',
      title: 'Test chat',
      systemPrompt: 'You are helpful.',
      modelId: '',
      createdAtMs: 1700000000000,
      updatedAtMs: 1700000100000,
    );

    const messages = [
      Message(
        id: 'm1',
        conversationId: 'conv-1',
        role: MessageRole.user,
        content: 'Hello',
        createdAtMs: 1700000200000,
      ),
      Message(
        id: 'm2',
        conversationId: 'conv-1',
        role: MessageRole.assistant,
        content: 'Hi there!',
        createdAtMs: 1700000300000,
      ),
    ];

    test('includes title, system prompt, and message turns', () {
      final md = exportConversationMarkdown(
        conversation: conversation,
        messages: messages,
        exportedAt: DateTime.utc(2026, 8, 1, 12, 0),
      );

      expect(md, contains('# Test chat'));
      expect(md, contains('## System prompt'));
      expect(md, contains('You are helpful.'));
      expect(md, contains('**User**'));
      expect(md, contains('Hello'));
      expect(md, contains('**Assistant**'));
      expect(md, contains('Hi there!'));
    });

    test('omits system prompt section when empty', () {
      final md = exportConversationMarkdown(
        conversation: conversation.copyWith(systemPrompt: ''),
        messages: messages,
        exportedAt: DateTime.utc(2026, 8, 1, 12, 0),
      );

      expect(md, isNot(contains('## System prompt')));
    });

    test('skips system-role messages', () {
      final md = exportConversationMarkdown(
        conversation: conversation.copyWith(systemPrompt: ''),
        messages: [
          ...messages,
          const Message(
            id: 'm3',
            conversationId: 'conv-1',
            role: MessageRole.system,
            content: 'hidden',
            createdAtMs: 1700000400000,
          ),
        ],
        exportedAt: DateTime.utc(2026, 8, 1, 12, 0),
      );

      expect(md, isNot(contains('hidden')));
    });

    test('notes an attachment for messages with an imagePath', () {
      final md = exportConversationMarkdown(
        conversation: conversation.copyWith(systemPrompt: ''),
        messages: const [
          Message(
            id: 'm1',
            conversationId: 'conv-1',
            role: MessageRole.user,
            content: 'what is this?',
            createdAtMs: 1700000200000,
            imagePath: '/tmp/img-1.jpg',
          ),
        ],
        exportedAt: DateTime.utc(2026, 8, 1, 12, 0),
      );

      expect(md, contains('_[image attached]_'));
    });

    test('omits the attachment note when imagePath is null', () {
      final md = exportConversationMarkdown(
        conversation: conversation.copyWith(systemPrompt: ''),
        messages: messages,
        exportedAt: DateTime.utc(2026, 8, 1, 12, 0),
      );

      expect(md, isNot(contains('[image attached]')));
    });
  });
}
