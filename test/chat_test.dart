import 'package:flutter_test/flutter_test.dart';
import 'package:loki_llm/features/chat/domain/conversation.dart';
import 'package:loki_llm/features/chat/domain/message.dart';
import 'package:loki_llm/features/chat/domain/message_role.dart';
import 'package:loki_llm/features/chat/presentation/chat_notifier.dart';

void main() {
  group('MessageRole', () {
    test('user role name is user', () {
      expect(MessageRole.user.name, equals('user'));
    });

    test('assistant role name is assistant', () {
      expect(MessageRole.assistant.name, equals('assistant'));
    });

    test('system role name is system', () {
      expect(MessageRole.system.name, equals('system'));
    });
  });

  group('Message domain', () {
    test('isUser returns true for user role', () {
      const msg = Message(
        id: 'msg-1',
        conversationId: 'conv-1',
        role: MessageRole.user,
        content: 'Hello',
        createdAtMs: 0,
      );
      expect(msg.isUser, isTrue);
      expect(msg.isAssistant, isFalse);
    });

    test('isAssistant returns true for assistant role', () {
      const msg = Message(
        id: 'msg-2',
        conversationId: 'conv-1',
        role: MessageRole.assistant,
        content: 'Hi there',
        createdAtMs: 1,
      );
      expect(msg.isAssistant, isTrue);
      expect(msg.isUser, isFalse);
    });

    test('copyWith updates fields correctly', () {
      const msg = Message(
        id: 'msg-3',
        conversationId: 'conv-1',
        role: MessageRole.user,
        content: 'Original',
        createdAtMs: 0,
      );
      final updated = msg.copyWith(content: 'Updated');
      expect(updated.content, equals('Updated'));
      expect(updated.id, equals('msg-3')); // unchanged
    });
  });

  group('Conversation domain', () {
    test('default systemPrompt is empty string', () {
      const conv = Conversation(
        id: 'conv-1',
        title: 'Test',
        createdAtMs: 0,
        updatedAtMs: 0,
      );
      expect(conv.systemPrompt, equals(''));
    });

    test('default modelId is empty string', () {
      const conv = Conversation(
        id: 'conv-1',
        title: 'Test',
        createdAtMs: 0,
        updatedAtMs: 0,
      );
      expect(conv.modelId, equals(''));
    });

    test('copyWith updates title', () {
      const conv = Conversation(
        id: 'conv-1',
        title: 'Old title',
        createdAtMs: 0,
        updatedAtMs: 0,
      );
      final updated = conv.copyWith(title: 'New title');
      expect(updated.title, equals('New title'));
      expect(updated.id, equals('conv-1')); // unchanged
    });
  });

  group('ChatState', () {
    test('isStreaming is false when streamingText is null', () {
      const state = ChatState(messages: []);
      expect(state.isStreaming, isFalse);
    });

    test('isStreaming is true when streamingText is set', () {
      const state = ChatState(messages: [], streamingText: 'hello');
      expect(state.isStreaming, isTrue);
    });

    test('isStreaming is true when streamingText is empty string', () {
      const state = ChatState(messages: [], streamingText: '');
      expect(state.isStreaming, isTrue);
    });

    test('copyWith with clearStreaming=true clears streamingText', () {
      const state = ChatState(messages: [], streamingText: 'streaming...');
      final cleared = state.copyWith(clearStreaming: true);
      expect(cleared.isStreaming, isFalse);
      expect(cleared.streamingText, isNull);
    });

    test('copyWith updates messages list', () {
      const state = ChatState(messages: []);
      const msg = Message(
        id: 'm1',
        conversationId: 'c1',
        role: MessageRole.user,
        content: 'Hi',
        createdAtMs: 0,
      );
      final updated = state.copyWith(messages: [msg]);
      expect(updated.messages.length, equals(1));
    });

    test('copyWith preserves streamingText when not cleared', () {
      const state = ChatState(messages: [], streamingText: 'partial');
      final updated = state.copyWith(messages: []);
      expect(updated.streamingText, equals('partial'));
    });

    test('copyWith can update streamingText', () {
      const state = ChatState(messages: [], streamingText: 'old');
      final updated = state.copyWith(streamingText: 'new');
      expect(updated.streamingText, equals('new'));
    });
  });
}
