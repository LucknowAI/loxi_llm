import '../../features/chat/domain/message_role.dart';

/// Per-model chat templates.
///
/// Instruction-tuned models are trained with a specific turn format (control
/// tokens like `<start_of_turn>`, `<|end|>`, `<|eot_id|>`) and only behave well
/// when fed that exact format. Feeding the wrong format pushes the model
/// off-distribution and — with no stop sequence — makes it hallucinate both
/// sides of the conversation. [ChatTemplate] formats the prompt correctly per
/// model family and supplies the matching [stopSequences].
///
/// Selection is by [ChatTemplate.forModelId]; [generic] is the safe fallback
/// (today's `Human:/Assistant:` behavior) for unknown models.
enum ChatTemplateKind { gemma, phi3, llama3, generic }

/// A single conversation turn (system prompt is passed separately, matching
/// the app's Conversation.systemPrompt field).
class ChatTurn {
  const ChatTurn(this.role, this.content);
  final MessageRole role;
  final String content;
}

class ChatTemplate {
  const ChatTemplate(this.kind);

  final ChatTemplateKind kind;

  /// Pick a template from a model id (mirrors kCuratedModels ids).
  factory ChatTemplate.forModelId(String modelId) {
    final id = modelId.toLowerCase();
    if (id.contains('gemma')) return const ChatTemplate(ChatTemplateKind.gemma);
    if (id.contains('phi')) return const ChatTemplate(ChatTemplateKind.phi3);
    if (id.contains('llama')) return const ChatTemplate(ChatTemplateKind.llama3);
    return const ChatTemplate(ChatTemplateKind.generic);
  }

  /// Sequences that should halt generation for this template.
  List<String> get stopSequences => switch (kind) {
        ChatTemplateKind.gemma => const ['<end_of_turn>'],
        ChatTemplateKind.phi3 => const ['<|end|>'],
        ChatTemplateKind.llama3 => const ['<|eot_id|>'],
        ChatTemplateKind.generic => const ['\nHuman:', '\nUser:'],
      };

  /// Format [turns] (oldest first) into the prompt string for this model
  /// family, priming exactly one assistant/model turn at the end.
  ///
  /// [systemPrompt] is placed per family (Gemma has no system role, so it folds
  /// into the first user turn). When [ragContext] is non-empty it is folded into
  /// the **last user turn** — context the user is implicitly providing for this
  /// question — so retrieval stays inside the model's real user-turn markers.
  String format(
    List<ChatTurn> turns,
    String systemPrompt, {
    String ragContext = '',
  }) {
    final effective =
        ragContext.isEmpty ? turns : _foldRagIntoLastUserTurn(turns, ragContext);
    return switch (kind) {
      ChatTemplateKind.gemma => _gemma(effective, systemPrompt),
      ChatTemplateKind.phi3 => _phi3(effective, systemPrompt),
      ChatTemplateKind.llama3 => _llama3(effective, systemPrompt),
      ChatTemplateKind.generic => _generic(effective, systemPrompt),
    };
  }

  /// Prepend [ragContext] to the content of the most recent user turn.
  static List<ChatTurn> _foldRagIntoLastUserTurn(
    List<ChatTurn> turns,
    String ragContext,
  ) {
    var lastUser = -1;
    for (var i = 0; i < turns.length; i++) {
      if (turns[i].role == MessageRole.user) lastUser = i;
    }
    if (lastUser == -1) return turns;
    final out = [...turns];
    out[lastUser] = ChatTurn(
      MessageRole.user,
      '$ragContext\n\n${turns[lastUser].content}',
    );
    return out;
  }

  // Gemma has no system role — the system prompt is folded into the first
  // user turn. Generation is primed with a trailing `<start_of_turn>model`.
  String _gemma(List<ChatTurn> turns, String systemPrompt) {
    final b = StringBuffer();
    var firstUser = true;
    for (final t in turns) {
      if (t.role == MessageRole.user) {
        b.writeln('<start_of_turn>user');
        if (firstUser && systemPrompt.isNotEmpty) {
          b.writeln('$systemPrompt\n');
          firstUser = false;
        }
        b.writeln('${t.content}<end_of_turn>');
      } else {
        b.writeln('<start_of_turn>model');
        b.writeln('${t.content}<end_of_turn>');
      }
    }
    b.write('<start_of_turn>model\n');
    return b.toString();
  }

  String _phi3(List<ChatTurn> turns, String systemPrompt) {
    final b = StringBuffer();
    if (systemPrompt.isNotEmpty) {
      b.writeln('<|system|>');
      b.writeln('$systemPrompt<|end|>');
    }
    for (final t in turns) {
      final tag = t.role == MessageRole.user ? 'user' : 'assistant';
      b.writeln('<|$tag|>');
      b.writeln('${t.content}<|end|>');
    }
    b.write('<|assistant|>\n');
    return b.toString();
  }

  String _llama3(List<ChatTurn> turns, String systemPrompt) {
    final b = StringBuffer();
    b.write('<|begin_of_text|>');
    if (systemPrompt.isNotEmpty) {
      b.write('<|start_header_id|>system<|end_header_id|>\n\n');
      b.write('$systemPrompt<|eot_id|>');
    }
    for (final t in turns) {
      final role = t.role == MessageRole.user ? 'user' : 'assistant';
      b.write('<|start_header_id|>$role<|end_header_id|>\n\n');
      b.write('${t.content}<|eot_id|>');
    }
    b.write('<|start_header_id|>assistant<|end_header_id|>\n\n');
    return b.toString();
  }

  // The app's CURRENT format, for before/after comparison.
  String _generic(List<ChatTurn> turns, String systemPrompt) {
    final b = StringBuffer();
    if (systemPrompt.isNotEmpty) {
      b.writeln(systemPrompt);
      b.writeln();
    }
    for (final t in turns) {
      final prefix = t.role == MessageRole.user ? 'Human: ' : 'Assistant: ';
      b.writeln('$prefix${t.content}');
    }
    b.write('Assistant: ');
    return b.toString();
  }
}
