import '../../../core/engine/chat_template.dart';
import '../../chat/domain/message_role.dart';
import '../data/tool_registry.dart';
import '../domain/tool.dart';
import '../domain/tool_call_parser.dart';

/// One generate→tool→observation step, kept for tracing/UI.
class AgentStep {
  const AgentStep({
    required this.generation,
    required this.toolCall,
    required this.observation,
  });

  final String generation;
  final ToolCall toolCall;
  final String observation;
}

/// Outcome of [AgentLoop.run].
class AgentResult {
  const AgentResult({
    required this.answer,
    required this.steps,
    required this.hitIterationCap,
  });

  final String answer;
  final List<AgentStep> steps;
  final bool hitIterationCap;
}

/// A bounded tool-calling loop: generate → parse a tool call → execute it →
/// feed the observation back → repeat, until the model answers in plain text or
/// the iteration cap is reached.
///
/// [generate] is injected (it formats the turns and runs the model to
/// completion), so the loop is backend-agnostic and unit-testable with a fake.
class AgentLoop {
  AgentLoop({
    required this.generate,
    required this.registry,
    this.maxIterations = 5,
    this.onToolCall,
  });

  final Future<String> Function(List<ChatTurn> turns) generate;
  final ToolRegistry registry;
  final int maxIterations;

  /// Called with the tool name just before each tool runs (for UI status).
  final void Function(String toolName)? onToolCall;

  Future<AgentResult> run(List<ChatTurn> initialTurns) async {
    final turns = [...initialTurns];
    final steps = <AgentStep>[];

    for (var i = 0; i < maxIterations; i++) {
      final output = await generate(turns);
      final call = parseToolCall(output);

      // No tool call → this is the final answer.
      if (call == null) {
        return AgentResult(
          answer: output.trim(),
          steps: steps,
          hitIterationCap: false,
        );
      }

      // Execute the tool (never throws by contract).
      onToolCall?.call(call.name);
      final tool = registry.byName(call.name);
      final observation = tool == null
          ? 'Error: unknown tool "${call.name}".'
          : await tool.call(call.arguments);

      steps.add(AgentStep(
        generation: output,
        toolCall: call,
        observation: observation,
      ));

      // Record the assistant's tool_call and the observation so the next
      // generation can use the result.
      turns.add(ChatTurn(MessageRole.assistant, output.trim()));
      turns.add(ChatTurn(
        MessageRole.user,
        'Observation (${call.name}): $observation',
      ));
    }

    // Cap reached: the model kept calling tools. Return a best-effort answer.
    final lastObservation = steps.isNotEmpty ? steps.last.observation : null;
    return AgentResult(
      answer: 'I could not finish within $maxIterations steps.'
          '${lastObservation != null ? '\n\nLast result: $lastObservation' : ''}',
      steps: steps,
      hitIterationCap: true,
    );
  }
}
