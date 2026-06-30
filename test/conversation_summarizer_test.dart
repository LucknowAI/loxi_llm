import 'package:flutter_test/flutter_test.dart';
import 'package:loki_llm/features/chat/application/conversation_summarizer.dart';
import 'package:loki_llm/features/chat/domain/message.dart';
import 'package:loki_llm/features/chat/domain/message_role.dart';

Message _msg(MessageRole role, String content) => Message(
      id: 'm',
      conversationId: 'c',
      role: role,
      content: content,
      createdAtMs: 0,
    );

void main() {
  group('ConversationSummarizer', () {
    test('returns the existing summary unchanged when nothing is new', () async {
      var called = false;
      final s = ConversationSummarizer(generate: (_) async {
        called = true;
        return 'x';
      });
      final out = await s.summarize(existingSummary: 'old', newMessages: []);
      expect(out, 'old');
      expect(called, isFalse);
    });

    test('passes the existing summary and new transcript to the model', () async {
      String? seen;
      final s = ConversationSummarizer(generate: (instruction) async {
        seen = instruction;
        return '  new summary  ';
      });
      final out = await s.summarize(
        existingSummary: 'prior summary',
        newMessages: [
          _msg(MessageRole.user, 'hello'),
          _msg(MessageRole.assistant, 'hi there'),
        ],
      );
      expect(out, 'new summary'); // trimmed
      expect(seen, contains('prior summary'));
      expect(seen, contains('User: hello'));
      expect(seen, contains('Assistant: hi there'));
    });

    test('notes when there is no prior summary', () async {
      String? seen;
      final s = ConversationSummarizer(generate: (i) async {
        seen = i;
        return 'summary';
      });
      await s.summarize(
        existingSummary: '',
        newMessages: [_msg(MessageRole.user, 'q')],
      );
      expect(seen, contains('No summary yet'));
    });

    test('mentions the word budget in the instruction', () async {
      String? seen;
      final s = ConversationSummarizer(generate: (i) async {
        seen = i;
        return 's';
      }, maxWords: 80);
      await s.summarize(
          existingSummary: '', newMessages: [_msg(MessageRole.user, 'q')]);
      expect(seen, contains('80 words'));
    });
  });
}
