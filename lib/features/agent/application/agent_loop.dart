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
    required this.generateStream,
    required this.registry,
    this.maxIterations = 5,
    this.onToolCall,
    this.onAnswerToken,
  });

  /// Streams one model generation for the given turns (formatted by the caller).
  final Stream<String> Function(List<ChatTurn> turns) generateStream;
  final ToolRegistry registry;
  final int maxIterations;

  /// Called with the tool name just before each tool runs (for UI status).
  final void Function(String toolName)? onToolCall;

  /// Called with each token of the final answer as it streams to the UI.
  final void Function(String token)? onAnswerToken;

  Future<AgentResult> run(List<ChatTurn> initialTurns) async {
    final turns = [...initialTurns];
    final steps = <AgentStep>[];

    for (var i = 0; i < maxIterations; i++) {
      // Consume one generation, peeking at the start to decide whether it is a
      // tool call (buffer silently) or the final answer (stream it).
      final buffer = StringBuffer();
      var decided = false;
      var answerMode = false;

      await for (final token in generateStream(turns)) {
        buffer.write(token);
        if (!decided) {
          final trimmed = buffer.toString().trimLeft();
          if (trimmed.isEmpty) continue; // only whitespace so far
          decided = true;
          final first = trimmed[0];
          answerMode = first != '`' && first != '{';
          if (answerMode) onAnswerToken?.call(trimmed);
        } else if (answerMode) {
          onAnswerToken?.call(token);
        }
        // Tool mode: keep buffering silently.
      }

      final output = buffer.toString();

      // Answer mode → the final answer already streamed.
      if (answerMode) {
        return AgentResult(
          answer: output.trim(),
          steps: steps,
          hitIterationCap: false,
        );
      }

      // Tool mode (or empty): parse the tool call. If it does not parse, it was
      // not really a tool call — surface the withheld text as the answer.
      final call = parseToolCall(output);
      if (call == null) {
        final answer = output.trim();
        onAnswerToken?.call(answer);
        return AgentResult(answer: answer, steps: steps, hitIterationCap: false);
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
    final answer = 'I could not finish within $maxIterations steps.'
        '${lastObservation != null ? '\n\nLast result: $lastObservation' : ''}';
    onAnswerToken?.call(answer);
    return AgentResult(answer: answer, steps: steps, hitIterationCap: true);
  }
}
