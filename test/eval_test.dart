import 'package:flutter_test/flutter_test.dart';
import 'package:loki_llm/core/engine/chat_template.dart';
import 'package:loki_llm/features/agent/application/agent_loop.dart';
import 'package:loki_llm/features/agent/data/tool_registry.dart';
import 'package:loki_llm/features/agent/tools/calculator_tool.dart';
import 'package:loki_llm/features/chat/application/prompt_builder.dart';
import 'package:loki_llm/features/chat/domain/message_role.dart';

/// Eval harness: deterministic, CI-runnable scenarios that lock down the exact
/// prompt the model receives and how the agent loop routes. These guard against
/// regressions in template selection, tool-instruction / summary / RAG
/// injection, windowing, and tool routing — the parts CI *can* judge without a
/// real model.

/// A fake backend `generateStream` that records the prompts it was asked to run
/// and replays a scripted token list per call.
class _CapturingBackend {
  _CapturingBackend(this.scripts);
  final List<List<String>> scripts;
  final List<String> prompts = [];
  int _i = 0;

  Stream<String> stream(String prompt) async* {
    prompts.add(prompt);
    for (final t in scripts[_i++ % scripts.length]) {
      yield t;
    }
  }
}

void main() {
  group('eval: prompt assembly', () {
    final turns = [const ChatTurn(MessageRole.user, 'hi there')];

    test('template is chosen per model id', () {
      expect(ChatTemplate.forModelId('gemma3-270m-it').kind,
          ChatTemplateKind.gemma);
      expect(ChatTemplate.forModelId('phi3-mini-4k-q4km').kind,
          ChatTemplateKind.phi3);
      expect(ChatTemplate.forModelId('llama32-3b-q4km').kind,
          ChatTemplateKind.llama3);
      expect(ChatTemplate.forModelId('mystery').kind, ChatTemplateKind.generic);
    });

    test('tool instructions appear only when tools are enabled', () {
      final withTools = buildPrompt(
        template: const ChatTemplate(ChatTemplateKind.phi3),
        turns: turns,
        toolInstructions: 'AVAILABLE TOOLS: calculator',
      );
      final withoutTools = buildPrompt(
        template: const ChatTemplate(ChatTemplateKind.phi3),
        turns: turns,
      );
      expect(withTools, contains('AVAILABLE TOOLS: calculator'));
      expect(withoutTools, isNot(contains('AVAILABLE TOOLS')));
    });

    test('summary is injected only when non-empty', () {
      final withSummary = buildPrompt(
        template: const ChatTemplate(ChatTemplateKind.phi3),
        turns: turns,
        summary: 'User is named Mohit.',
      );
      final withoutSummary = buildPrompt(
        template: const ChatTemplate(ChatTemplateKind.phi3),
        turns: turns,
      );
      expect(withSummary, contains('Summary of earlier conversation:'));
      expect(withSummary, contains('Mohit'));
      expect(withoutSummary, isNot(contains('Summary of earlier conversation')));
    });

    test('RAG context lands inside the last user turn', () {
      final out = buildPrompt(
        template: const ChatTemplate(ChatTemplateKind.gemma),
        turns: turns,
        ragContext: 'CTX: relevant passage',
      );
      expect(
        out,
        contains('<start_of_turn>user\nCTX: relevant passage\n\nhi there<end_of_turn>'),
      );
    });
  });

  group('eval: agent routing', () {
    test('a tool_call routes to the tool and feeds the observation back', () async {
      final registry = ToolRegistry([CalculatorTool()]);
      final backend = _CapturingBackend([
        ['```tool_call\n{"name":"calculator","arguments":{"expression":"6*7"}}\n```'],
        ['The result is 42.'],
      ]);
      const template = ChatTemplate(ChatTemplateKind.phi3);

      final result = await AgentLoop(
        generateStream: (turns) => backend.stream(
          buildPrompt(
            template: template,
            turns: turns,
            toolInstructions: registry.promptDescription(),
          ),
        ),
        registry: registry,
      ).run([const ChatTurn(MessageRole.user, 'what is 6 times 7?')]);

      expect(result.answer, 'The result is 42.');
      expect(result.steps.single.observation, '42');
      // The second prompt (after the tool ran) must carry the observation and
      // the tool instructions.
      expect(backend.prompts[1], contains('Observation (calculator): 42'));
      expect(backend.prompts[1], contains('tool_call'));
    });
  });
}
