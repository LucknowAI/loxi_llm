import 'package:flutter_test/flutter_test.dart';
import 'package:loki_llm/core/engine/chat_template.dart';
import 'package:loki_llm/features/agent/application/agent_loop.dart';
import 'package:loki_llm/features/agent/data/tool_registry.dart';
import 'package:loki_llm/features/agent/tools/calculator_tool.dart';
import 'package:loki_llm/features/chat/domain/message_role.dart';

/// A generate() that returns scripted outputs in order, recording the turns it
/// was given on each call.
class _ScriptedGenerate {
  _ScriptedGenerate(this.outputs);
  final List<String> outputs;
  final List<List<ChatTurn>> calls = [];
  int _i = 0;

  Future<String> call(List<ChatTurn> turns) async {
    calls.add(List.of(turns));
    return outputs[_i++ % outputs.length];
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
    test('runs a tool then returns the final answer', () async {
      final gen = _ScriptedGenerate([
        '```tool_call\n{"name":"calculator","arguments":{"expression":"12*7"}}\n```',
        '12 times 7 is 84.',
      ]);
      final result =
          await AgentLoop(generate: gen.call, registry: registry).run(initial);

      expect(result.hitIterationCap, isFalse);
      expect(result.answer, '12 times 7 is 84.');
      expect(result.steps, hasLength(1));
      expect(result.steps.first.observation, '84');
      // The observation was fed back into the second generate call.
      expect(
        gen.calls[1].any((t) => t.content.contains('Observation (calculator): 84')),
        isTrue,
      );
    });

    test('returns immediately when the first output is a plain answer', () async {
      final gen = _ScriptedGenerate(['The answer is 84.']);
      final result =
          await AgentLoop(generate: gen.call, registry: registry).run(initial);
      expect(result.answer, 'The answer is 84.');
      expect(result.steps, isEmpty);
      expect(gen.calls, hasLength(1));
    });

    test('feeds back an error for an unknown tool', () async {
      final gen = _ScriptedGenerate([
        '```tool_call\n{"name":"weather","arguments":{}}\n```',
        'Done.',
      ]);
      final result =
          await AgentLoop(generate: gen.call, registry: registry).run(initial);
      expect(result.steps.first.observation, contains('unknown tool'));
      expect(result.answer, 'Done.');
    });

    test('stops at the iteration cap when tools never resolve', () async {
      // Always returns a tool call → never a final answer.
      final gen = _ScriptedGenerate([
        '```tool_call\n{"name":"calculator","arguments":{"expression":"1+1"}}\n```',
      ]);
      final result = await AgentLoop(
        generate: gen.call,
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
