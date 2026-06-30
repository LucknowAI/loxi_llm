import 'package:flutter_test/flutter_test.dart';
import 'package:loki_llm/core/engine/chat_template.dart';
import 'package:loki_llm/features/chat/application/prompt_builder.dart';
import 'package:loki_llm/features/chat/domain/message_role.dart';

void main() {
  const template = ChatTemplate(ChatTemplateKind.phi3);
  final turns = [
    const ChatTurn(MessageRole.user, 'What is the capital of France?'),
  ];

  test('omits all system scaffolding when nothing is provided', () {
    final out = buildPrompt(template: template, turns: turns);
    expect(out, isNot(contains('<|system|>')));
    expect(out, contains('What is the capital of France?'));
  });

  test('injects the summary when present', () {
    final out = buildPrompt(
      template: template,
      turns: turns,
      summary: 'Earlier the user introduced themselves as Mohit.',
    );
    expect(out, contains('Summary of earlier conversation:'));
    expect(out, contains('Mohit'));
  });

  test('injects tool instructions and system prompt', () {
    final out = buildPrompt(
      template: template,
      turns: turns,
      toolInstructions: 'TOOLS: calculator',
      systemPrompt: 'You are terse.',
    );
    expect(out, contains('TOOLS: calculator'));
    expect(out, contains('You are terse.'));
  });

  test('orders tool instructions, system prompt, then summary', () {
    final out = buildPrompt(
      template: template,
      turns: turns,
      toolInstructions: 'TOOLINSTR',
      systemPrompt: 'PERSONA',
      summary: 'SUMMARYTEXT',
    );
    expect(out.indexOf('TOOLINSTR'), lessThan(out.indexOf('PERSONA')));
    expect(out.indexOf('PERSONA'),
        lessThan(out.indexOf('Summary of earlier conversation:')));
  });

  test('folds RAG context into the last user turn', () {
    final out = buildPrompt(
      template: template,
      turns: turns,
      ragContext: 'CONTEXT: Paris is the capital.',
    );
    expect(
      out,
      contains('<|user|>\n'
          'CONTEXT: Paris is the capital.\n\n'
          'What is the capital of France?<|end|>'),
    );
  });
}
