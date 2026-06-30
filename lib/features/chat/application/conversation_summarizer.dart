import '../domain/message.dart';

/// Maintains a rolling, model-generated summary of conversation turns that have
/// been evicted from the prompt window, so long conversations stay coherent.
///
/// [generate] is injected — it takes an instruction string, runs the model to
/// completion (formatting it as a single user turn), and returns the output.
/// This keeps the summarizer backend-agnostic and unit-testable with a fake.
class ConversationSummarizer {
  ConversationSummarizer({required this.generate, this.maxWords = 150});

  final Future<String> Function(String instruction) generate;
  final int maxWords;

  /// Fold [newMessages] into [existingSummary]. Returns [existingSummary]
  /// unchanged when there is nothing new to summarize.
  Future<String> summarize({
    required String existingSummary,
    required List<Message> newMessages,
  }) async {
    if (newMessages.isEmpty) return existingSummary;

    final transcript = newMessages
        .map((m) => '${m.isUser ? 'User' : 'Assistant'}: ${m.content}')
        .join('\n');

    final instruction = StringBuffer()
      ..writeln('You maintain a running summary of an ongoing conversation.')
      ..writeln('Update the summary to incorporate the new messages below. '
          'Keep it factual and concise — under $maxWords words. '
          'Respond with only the updated summary.')
      ..writeln()
      ..writeln(existingSummary.isEmpty
          ? '(No summary yet.)'
          : 'Current summary:\n$existingSummary')
      ..writeln()
      ..writeln('New messages:\n$transcript')
      ..writeln()
      ..write('Updated summary:');

    final result = await generate(instruction.toString());
    return result.trim();
  }
}
