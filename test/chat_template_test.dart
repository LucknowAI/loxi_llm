import 'package:flutter_test/flutter_test.dart';
import 'package:loki_llm/core/engine/chat_template.dart';
import 'package:loki_llm/features/chat/domain/message_role.dart';

void main() {
  // A fixed two-turn exchange reused across the golden assertions.
  final turns = <ChatTurn>[
    const ChatTurn(MessageRole.user, 'What is the capital of France?'),
    const ChatTurn(MessageRole.assistant, 'Paris.'),
    const ChatTurn(MessageRole.user, 'And its population?'),
  ];
  const system = 'You are a helpful assistant.';

  group('Golden format per family', () {
    test('Gemma folds system into first user turn + primes model turn', () {
      final out =
          const ChatTemplate(ChatTemplateKind.gemma).format(turns, system);
      expect(out, '''
<start_of_turn>user
You are a helpful assistant.

What is the capital of France?<end_of_turn>
<start_of_turn>model
Paris.<end_of_turn>
<start_of_turn>user
And its population?<end_of_turn>
<start_of_turn>model
''');
      expect(out, isNot(contains('<|system|>')));
      expect(out, isNot(contains('Human:')));
    });

    test('Phi-3 emits a system block + primes assistant', () {
      final out =
          const ChatTemplate(ChatTemplateKind.phi3).format(turns, system);
      expect(out, '''
<|system|>
You are a helpful assistant.<|end|>
<|user|>
What is the capital of France?<|end|>
<|assistant|>
Paris.<|end|>
<|user|>
And its population?<|end|>
<|assistant|>
''');
    });

    test('Llama 3.2 uses header turns + begin_of_text', () {
      final out =
          const ChatTemplate(ChatTemplateKind.llama3).format(turns, system);
      expect(out.startsWith('<|begin_of_text|>'), isTrue);
      expect(
        out,
        contains(
            '<|start_header_id|>system<|end_header_id|>\n\nYou are a helpful assistant.<|eot_id|>'),
      );
      expect(out.endsWith('<|start_header_id|>assistant<|end_header_id|>\n\n'),
          isTrue);
    });

    test('generic keeps the legacy Human:/Assistant: behaviour', () {
      final out =
          const ChatTemplate(ChatTemplateKind.generic).format(turns, system);
      expect(out, '''
You are a helpful assistant.

Human: What is the capital of France?
Assistant: Paris.
Human: And its population?
Assistant: ''');
    });
  });

  group('Empty system prompt emits no scaffolding', () {
    test('Gemma', () {
      final out = const ChatTemplate(ChatTemplateKind.gemma).format(turns, '');
      expect(out.startsWith('<start_of_turn>user\nWhat is the capital'), isTrue);
    });
    test('Phi-3', () {
      final out = const ChatTemplate(ChatTemplateKind.phi3).format(turns, '');
      expect(out, isNot(contains('<|system|>')));
    });
    test('Llama 3.2', () {
      final out = const ChatTemplate(ChatTemplateKind.llama3).format(turns, '');
      expect(out, isNot(contains('system<|end_header_id|>')));
    });
  });

  group('RAG context folds into the last user turn', () {
    const rag = 'Use the following context to answer the question:\n'
        '[1] Paris has 2.1M residents.';

    test('Gemma: context sits inside the final user markers', () {
      final out = const ChatTemplate(ChatTemplateKind.gemma)
          .format(turns, '', ragContext: rag);
      // Context appears before the original last user message, within the turn.
      expect(
        out,
        contains('<start_of_turn>user\n'
            'Use the following context to answer the question:\n'
            '[1] Paris has 2.1M residents.\n\n'
            'And its population?<end_of_turn>'),
      );
      // The earlier user turn is untouched.
      expect(out, contains('What is the capital of France?<end_of_turn>'));
    });

    test('Phi-3: context folded into last <|user|> block', () {
      final out = const ChatTemplate(ChatTemplateKind.phi3)
          .format(turns, '', ragContext: rag);
      expect(
        out,
        contains('<|user|>\n'
            'Use the following context to answer the question:\n'
            '[1] Paris has 2.1M residents.\n\n'
            'And its population?<|end|>'),
      );
    });

    test('empty ragContext leaves turns unchanged', () {
      final withEmpty = const ChatTemplate(ChatTemplateKind.gemma)
          .format(turns, '', ragContext: '');
      final without =
          const ChatTemplate(ChatTemplateKind.gemma).format(turns, '');
      expect(withEmpty, without);
    });
  });

  group('Stop sequences per kind', () {
    test('gemma', () {
      expect(const ChatTemplate(ChatTemplateKind.gemma).stopSequences,
          const ['<end_of_turn>']);
    });
    test('phi3', () {
      expect(const ChatTemplate(ChatTemplateKind.phi3).stopSequences,
          const ['<|end|>']);
    });
    test('llama3', () {
      expect(const ChatTemplate(ChatTemplateKind.llama3).stopSequences,
          const ['<|eot_id|>']);
    });
    test('generic', () {
      expect(const ChatTemplate(ChatTemplateKind.generic).stopSequences,
          const ['\nHuman:', '\nUser:']);
    });
  });

  group('forModelId routing', () {
    test('catalog ids route to the right family', () {
      expect(ChatTemplate.forModelId('gemma3-270m-it').kind,
          ChatTemplateKind.gemma);
      expect(ChatTemplate.forModelId('phi3-mini-4k-q4km').kind,
          ChatTemplateKind.phi3);
      expect(ChatTemplate.forModelId('llama32-3b-q4km').kind,
          ChatTemplateKind.llama3);
    });
    test('future gemma-4 still routes to gemma', () {
      expect(
          ChatTemplate.forModelId('gemma-4-9b-it').kind, ChatTemplateKind.gemma);
    });
    test('gemma4-e2b-it and gemma4-e4b-it catalog ids route to gemma', () {
      expect(ChatTemplate.forModelId('gemma4-e2b-it').kind,
          ChatTemplateKind.gemma);
      expect(ChatTemplate.forModelId('gemma4-e4b-it').kind,
          ChatTemplateKind.gemma);
    });
    test('unknown id falls back to generic', () {
      expect(ChatTemplate.forModelId('mystery-model').kind,
          ChatTemplateKind.generic);
      expect(ChatTemplate.forModelId('').kind, ChatTemplateKind.generic);
    });
  });

  group('Single assistant primer (no double-priming)', () {
    test('exactly one trailing model primer for Gemma', () {
      final out =
          const ChatTemplate(ChatTemplateKind.gemma).format(turns, system);
      expect('<start_of_turn>model\n'.allMatches(out).length, 2,
          reason: 'one for the prior answer, one trailing primer');
      expect(out.trimRight().endsWith('<start_of_turn>model'), isTrue);
    });
    test('Phi-3 ends with a single assistant primer', () {
      final out =
          const ChatTemplate(ChatTemplateKind.phi3).format(turns, system);
      expect(out.trimRight().endsWith('<|assistant|>'), isTrue);
    });
  });
}
