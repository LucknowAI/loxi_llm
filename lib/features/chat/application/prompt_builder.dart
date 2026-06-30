import '../../../core/engine/chat_template.dart';

/// Assembles the final model prompt from its parts. Pure (no Riverpod / IO) so
/// both the streaming and agent paths share one tested implementation and the
/// eval harness can assert exactly what the model receives.
///
/// The system block is composed in order — tool instructions (how to behave),
/// the conversation's system prompt (persona), then the rolling [summary] of
/// earlier turns (context closest to the recent messages) — with empty parts
/// omitted. RAG context is folded into the last user turn by [ChatTemplate].
String buildPrompt({
  required ChatTemplate template,
  required List<ChatTurn> turns,
  String systemPrompt = '',
  String toolInstructions = '',
  String summary = '',
  String ragContext = '',
}) {
  final system = [
    if (toolInstructions.isNotEmpty) toolInstructions,
    if (systemPrompt.isNotEmpty) systemPrompt,
    if (summary.isNotEmpty) 'Summary of earlier conversation:\n$summary',
  ].join('\n\n');

  return template.format(turns, system, ragContext: ragContext);
}
