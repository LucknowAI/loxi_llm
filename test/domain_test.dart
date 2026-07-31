import 'package:flutter_test/flutter_test.dart';
import 'package:loki_llm/features/chat/domain/conversation.dart';
import 'package:loki_llm/features/chat/domain/message.dart';
import 'package:loki_llm/features/chat/domain/message_role.dart';
import 'package:loki_llm/features/chat/presentation/chat_notifier.dart';
import 'package:loki_llm/features/documents/domain/document.dart';

void main() {
  const kNow = 1700000000000;

  // ──────────────────────────────────────────
  // Message
  // ──────────────────────────────────────────
  group('Message domain', () {
    test('isUser is true for MessageRole.user', () {
      const msg = Message(
        id: 'msg-1',
        conversationId: 'conv-1',
        role: MessageRole.user,
        content: 'Hello',
        createdAtMs: kNow,
      );
      expect(msg.isUser, isTrue);
      expect(msg.isAssistant, isFalse);
    });

    test('isAssistant is true for MessageRole.assistant', () {
      const msg = Message(
        id: 'msg-2',
        conversationId: 'conv-1',
        role: MessageRole.assistant,
        content: 'Hi there!',
        createdAtMs: kNow,
      );
      expect(msg.isAssistant, isTrue);
      expect(msg.isUser, isFalse);
    });

    test('isUser and isAssistant are both false for system role', () {
      const msg = Message(
        id: 'msg-3',
        conversationId: 'conv-1',
        role: MessageRole.system,
        content: 'You are a helpful assistant.',
        createdAtMs: kNow,
      );
      expect(msg.isUser, isFalse);
      expect(msg.isAssistant, isFalse);
    });

    test('copyWith updates content while preserving all other fields', () {
      const msg = Message(
        id: 'msg-4',
        conversationId: 'conv-1',
        role: MessageRole.user,
        content: 'Original',
        createdAtMs: kNow,
      );
      final updated = msg.copyWith(content: 'Updated');

      expect(updated.content, equals('Updated'));
      expect(updated.id, equals('msg-4'));
      expect(updated.conversationId, equals('conv-1'));
      expect(updated.role, equals(MessageRole.user));
      expect(updated.createdAtMs, equals(kNow));
    });

    test('copyWith with no arguments returns an equal Message', () {
      const msg = Message(
        id: 'msg-5',
        conversationId: 'conv-1',
        role: MessageRole.assistant,
        content: 'No change',
        createdAtMs: kNow,
      );
      expect(msg.copyWith(), equals(msg));
    });

    test('two Messages with identical fields are equal (value semantics)', () {
      const a = Message(
        id: 'msg-6',
        conversationId: 'conv-1',
        role: MessageRole.user,
        content: 'Same',
        createdAtMs: kNow,
      );
      const b = Message(
        id: 'msg-6',
        conversationId: 'conv-1',
        role: MessageRole.user,
        content: 'Same',
        createdAtMs: kNow,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('Messages with different ids are not equal', () {
      const a = Message(
        id: 'msg-7',
        conversationId: 'conv-1',
        role: MessageRole.user,
        content: 'Hello',
        createdAtMs: kNow,
      );
      const b = Message(
        id: 'msg-8',
        conversationId: 'conv-1',
        role: MessageRole.user,
        content: 'Hello',
        createdAtMs: kNow,
      );
      expect(a, isNot(equals(b)));
    });
  });

  // ──────────────────────────────────────────
  // Conversation
  // ──────────────────────────────────────────
  group('Conversation domain', () {
    test('default systemPrompt is an empty string', () {
      const conv = Conversation(
        id: 'conv-1',
        title: 'Test',
        createdAtMs: kNow,
        updatedAtMs: kNow,
      );
      expect(conv.systemPrompt, equals(''));
    });

    test('default modelId is an empty string', () {
      const conv = Conversation(
        id: 'conv-1',
        title: 'Test',
        createdAtMs: kNow,
        updatedAtMs: kNow,
      );
      expect(conv.modelId, equals(''));
    });

    test('default ragEnabled is false', () {
      const conv = Conversation(
        id: 'conv-1',
        title: 'Test',
        createdAtMs: kNow,
        updatedAtMs: kNow,
      );
      expect(conv.ragEnabled, isFalse);
    });

    test('copyWith enables ragEnabled', () {
      const conv = Conversation(
        id: 'conv-1',
        title: 'Test',
        createdAtMs: kNow,
        updatedAtMs: kNow,
      );
      final withRag = conv.copyWith(ragEnabled: true);
      expect(withRag.ragEnabled, isTrue);
      expect(withRag.id, equals('conv-1'));
    });

    test('copyWith updates systemPrompt and preserves all other fields', () {
      const conv = Conversation(
        id: 'conv-1',
        title: 'Test',
        createdAtMs: kNow,
        updatedAtMs: kNow,
      );
      final updated = conv.copyWith(systemPrompt: 'You are helpful.');
      expect(updated.systemPrompt, equals('You are helpful.'));
      expect(updated.title, equals('Test'));
      expect(updated.ragEnabled, isFalse);
    });

    test('copyWith updates title', () {
      const conv = Conversation(
        id: 'conv-1',
        title: 'Old Title',
        createdAtMs: kNow,
        updatedAtMs: kNow,
      );
      final updated = conv.copyWith(title: 'New Title');
      expect(updated.title, equals('New Title'));
    });

    test('copyWith updates updatedAtMs for timestamp bumping', () {
      const later = kNow + 5000;
      const conv = Conversation(
        id: 'conv-1',
        title: 'Test',
        createdAtMs: kNow,
        updatedAtMs: kNow,
      );
      final updated = conv.copyWith(updatedAtMs: later);
      expect(updated.updatedAtMs, equals(later));
      expect(updated.createdAtMs, equals(kNow)); // created stays unchanged
    });

    test('two Conversations with identical fields are equal (value semantics)', () {
      const a = Conversation(
        id: 'conv-2',
        title: 'Same',
        systemPrompt: 'Prompt',
        modelId: 'llama',
        createdAtMs: kNow,
        updatedAtMs: kNow,
        ragEnabled: true,
      );
      const b = Conversation(
        id: 'conv-2',
        title: 'Same',
        systemPrompt: 'Prompt',
        modelId: 'llama',
        createdAtMs: kNow,
        updatedAtMs: kNow,
        ragEnabled: true,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  // ──────────────────────────────────────────
  // Document
  // ──────────────────────────────────────────
  group('Document domain', () {
    test('default format is txt', () {
      const doc = Document(id: 'doc-1', name: 'notes.txt', createdAtMs: kNow);
      expect(doc.format, equals('txt'));
    });

    test('default chunkCount is 0', () {
      const doc = Document(id: 'doc-1', name: 'notes.txt', createdAtMs: kNow);
      expect(doc.chunkCount, equals(0));
    });

    test('copyWith updates chunkCount after ingestion', () {
      const doc = Document(id: 'doc-1', name: 'notes.txt', createdAtMs: kNow);
      final ingested = doc.copyWith(chunkCount: 42);
      expect(ingested.chunkCount, equals(42));
      expect(ingested.name, equals('notes.txt'));
    });

    test('copyWith updates format to pdf', () {
      const doc = Document(id: 'doc-2', name: 'report.pdf', createdAtMs: kNow);
      final updated = doc.copyWith(format: 'pdf');
      expect(updated.format, equals('pdf'));
    });

    test('copyWith updates format to docx', () {
      const doc = Document(id: 'doc-3', name: 'doc.docx', createdAtMs: kNow);
      final updated = doc.copyWith(format: 'docx');
      expect(updated.format, equals('docx'));
    });

    test('two Documents with identical fields are equal (value semantics)', () {
      const a = Document(id: 'doc-4', name: 'file.txt', createdAtMs: kNow);
      const b = Document(id: 'doc-4', name: 'file.txt', createdAtMs: kNow);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('Documents with different ids are not equal', () {
      const a = Document(id: 'doc-5', name: 'file.txt', createdAtMs: kNow);
      const b = Document(id: 'doc-6', name: 'file.txt', createdAtMs: kNow);
      expect(a, isNot(equals(b)));
    });
  });

  // ──────────────────────────────────────────
  // ChatState
  // ──────────────────────────────────────────
  group('ChatState', () {
    test('isStreaming is false when streamingText is null', () {
      const state = ChatState(messages: []);
      expect(state.isStreaming, isFalse);
    });

    test('isStreaming is true for empty string streamingText (stream just started)', () {
      const state = ChatState(messages: [], streamingText: '');
      expect(state.isStreaming, isTrue);
    });

    test('isStreaming is true for non-empty streamingText', () {
      const state = ChatState(messages: [], streamingText: 'partial');
      expect(state.isStreaming, isTrue);
    });

    test('copyWith clearStreaming:true sets streamingText to null', () {
      const state = ChatState(messages: [], streamingText: 'partial response');
      final cleared = state.copyWith(clearStreaming: true);
      expect(cleared.streamingText, isNull);
      expect(cleared.isStreaming, isFalse);
    });

    test('clearStreaming takes precedence — overrides any provided streamingText', () {
      // clearStreaming=true means "stop streaming", even if a value is passed
      const state = ChatState(messages: [], streamingText: 'old');
      final cleared = state.copyWith(streamingText: 'new', clearStreaming: true);
      // Per the implementation: clearStreaming ? null : ...
      expect(cleared.streamingText, isNull);
    });

    test('copyWith updates streamingText when clearStreaming is false (default)', () {
      const state = ChatState(messages: [], streamingText: 'tok');
      final updated = state.copyWith(streamingText: 'token one');
      expect(updated.streamingText, equals('token one'));
      expect(updated.isStreaming, isTrue);
    });

    test('copyWith with no arguments preserves all fields', () {
      const state = ChatState(messages: [], streamingText: 'hello');
      final copy = state.copyWith();
      expect(copy.streamingText, equals('hello'));
      expect(copy.messages, isEmpty);
    });

    test('copyWith updates messages list', () {
      const msg = Message(
        id: 'msg-1',
        conversationId: 'conv-1',
        role: MessageRole.user,
        content: 'Hi',
        createdAtMs: kNow,
      );
      const state = ChatState(messages: []);
      final updated = state.copyWith(messages: [msg]);
      expect(updated.messages, equals([msg]));
    });

    test('copyWith preserves existing messages when not provided', () {
      const msg = Message(
        id: 'msg-1',
        conversationId: 'conv-1',
        role: MessageRole.user,
        content: 'Hi',
        createdAtMs: kNow,
      );
      const state = ChatState(messages: [msg]);
      final updated = state.copyWith(streamingText: 'streaming...');
      expect(updated.messages, equals([msg]));
    });
  });
}
