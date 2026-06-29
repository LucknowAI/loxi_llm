import 'package:flutter_test/flutter_test.dart';
import 'package:loki_llm/core/engine/chat_template.dart';
import 'package:loki_llm/features/agent/application/agent_loop.dart';
import 'package:loki_llm/features/agent/data/tool_registry.dart';
import 'package:loki_llm/features/agent/tools/calculator_tool.dart';
import 'package:loki_llm/features/chat/domain/message_role.dart';

/// A generateStream() that yields scripted token lists in order (one list per
/// generation), recording the turns it was given on each call.
class _ScriptedGenerate {
  _ScriptedGenerate(this.scripts);
  final List<List<String>> scripts;
  final List<List<ChatTurn>> calls = [];
  int _i = 0;

  Stream<String> call(List<ChatTurn> turns) async* {
    calls.add(List.of(turns));
    final tokens = scripts[_i++ % scripts.length];
    for (final token in tokens) {
      yield token;
    }
  }
}

void main() {
  final registry = ToolRegistry([CalculatorTool()]);
  final initial = [const ChatTurn(MessageRole.user, 'what is 12 * 7?')];

  group('ToolRegistry', () {
    test('byName finds and misses', () {
      expect(registry.byName('calculator'), isNotNull);
      expect(registry.byName('nope'), isNull);
    });
    test('promptDescription lists every tool and the protocol', () {
      final desc = registry.promptDescription();
      expect(desc, contains('calculator'));
      expect(desc, contains('tool_call'));
    });
  });

  group('AgentLoop', () {
    test('runs a tool then streams the final answer', () async {
      final gen = _ScriptedGenerate([
        ['```tool_call\n', '{"name":"calculator",', '"arguments":{"expression":"12*7"}}', '\n```'],
        ['12 ', 'times ', '7 ', 'is ', '84.'],
      ]);
      final answerTokens = <String>[];
      final result = await AgentLoop(
        generateStream: gen.call,
        registry: registry,
        onAnswerToken: answerTokens.add,
      ).run(initial);

      expect(result.hitIterationCap, isFalse);
      expect(result.answer, '12 times 7 is 84.');
      expect(result.steps, hasLength(1));
      expect(result.steps.first.observation, '84');
      // The tool_call generation did NOT stream any answer tokens; only the
      // final answer did.
      expect(answerTokens.join(), '12 times 7 is 84.');
      // The observation was fed back into the second generation.
      expect(
        gen.calls[1].any((t) => t.content.contains('Observation (calculator): 84')),
        isTrue,
      );
    });

    test('streams a plain answer from the first generation', () async {
      final gen = _ScriptedGenerate([
        ['The ', 'answer ', 'is ', '84.'],
      ]);
      final answerTokens = <String>[];
      final result = await AgentLoop(
        generateStream: gen.call,
        registry: registry,
        onAnswerToken: answerTokens.add,
      ).run(initial);
      expect(result.answer, 'The answer is 84.');
      expect(answerTokens.join(), 'The answer is 84.');
      expect(result.steps, isEmpty);
      expect(gen.calls, hasLength(1));
    });

    test('feeds back an error for an unknown tool', () async {
      final gen = _ScriptedGenerate([
        ['```tool_call\n{"name":"weather","arguments":{}}\n```'],
        ['Done.'],
      ]);
      final result =
          await AgentLoop(generateStream: gen.call, registry: registry).run(initial);
      expect(result.steps.first.observation, contains('unknown tool'));
      expect(result.answer, 'Done.');
    });

    test('stops at the iteration cap when tools never resolve', () async {
      final gen = _ScriptedGenerate([
        ['```tool_call\n{"name":"calculator","arguments":{"expression":"1+1"}}\n```'],
      ]);
      final result = await AgentLoop(
        generateStream: gen.call,
        registry: registry,
        maxIterations: 3,
      ).run(initial);

      expect(result.hitIterationCap, isTrue);
      expect(result.steps, hasLength(3));
      expect(gen.calls, hasLength(3));
      expect(result.answer, contains('could not finish'));
    });
  });
}
