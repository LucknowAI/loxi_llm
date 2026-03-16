import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/inference_provider.dart';
import '../data/conversation_repository.dart';
import '../data/message_repository.dart';
import '../domain/message.dart';
import '../domain/message_role.dart';
import 'conversation_list_notifier.dart';

part 'chat_notifier.g.dart';

/// UI state for a single conversation.
class ChatState {
  const ChatState({required this.messages, this.streamingText});

  final List<Message> messages;

  /// Non-null during active streaming; null when idle.
  final String? streamingText;

  bool get isStreaming => streamingText != null;

  ChatState copyWith({
    List<Message>? messages,
    String? streamingText,
    bool clearStreaming = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      streamingText:
          clearStreaming ? null : (streamingText ?? this.streamingText),
    );
  }
}

@riverpod
class ChatNotifier extends _$ChatNotifier {
  StreamSubscription<String>? _tokenSub;

  @override
  Future<ChatState> build(String conversationId) async {
    ref.onDispose(() => _tokenSub?.cancel());
    final messages =
        ref.watch(messageRepositoryProvider).getMessages(conversationId);
    return ChatState(messages: messages);
  }

  /// Send a user message and stream the assistant response.
  Future<void> send(String userText) async {
    if (userText.trim().isEmpty) return;

    final backend = ref.read(inferenceNotifierProvider).valueOrNull;
    if (backend == null) throw StateError('No model loaded');

    final convRepo = ref.read(conversationRepositoryProvider);
    final msgRepo = ref.read(messageRepositoryProvider);
    final now = DateTime.now().millisecondsSinceEpoch;

    // Persist user message
    final userMsg = Message(
      id: 'msg-$now',
      conversationId: conversationId,
      role: MessageRole.user,
      content: userText.trim(),
      createdAtMs: now,
    );
    msgRepo.save(userMsg);

    // Update conversation title if this is the first message
    final conversation = convRepo.getById(conversationId);
    if (conversation != null && conversation.title == 'New conversation') {
      final title = userText.trim().length > 50
          ? '${userText.trim().substring(0, 47)}...'
          : userText.trim();
      convRepo.save(conversation.copyWith(title: title, updatedAtMs: now));
      ref.invalidate(conversationListNotifierProvider);
    }

    // Update UI with user message + signal streaming start
    final current = state.requireValue;
    state = AsyncData(current.copyWith(
      messages: [...current.messages, userMsg],
      streamingText: '',
    ));

    // Build prompt from full history + system prompt
    final systemPrompt = conversation?.systemPrompt ?? '';
    final prompt = _buildPrompt(
      [...current.messages, userMsg],
      systemPrompt,
    );

    // Stream tokens
    final buffer = StringBuffer();
    _tokenSub?.cancel();
    _tokenSub = backend.generate(prompt).listen(
      (token) {
        buffer.write(token);
        state = AsyncData(
          state.requireValue.copyWith(streamingText: buffer.toString()),
        );
      },
      onDone: () {
        final assistantMs = DateTime.now().millisecondsSinceEpoch;
        final assistantMsg = Message(
          id: 'msg-$assistantMs',
          conversationId: conversationId,
          role: MessageRole.assistant,
          content: buffer.toString(),
          createdAtMs: assistantMs,
        );
        msgRepo.save(assistantMsg);

        // Update conversation updatedAt
        final conv = convRepo.getById(conversationId);
        if (conv != null) {
          convRepo.save(conv.copyWith(updatedAtMs: assistantMs));
        }

        state = AsyncData(state.requireValue.copyWith(
          messages: [...state.requireValue.messages, assistantMsg],
          clearStreaming: true,
        ));
      },
      onError: (Object e, StackTrace st) {
        state = AsyncError(e, st);
      },
    );
  }

  /// Build a simple chat prompt from history + system prompt.
  String _buildPrompt(List<Message> history, String systemPrompt) {
    final buffer = StringBuffer();
    if (systemPrompt.isNotEmpty) {
      buffer.writeln(systemPrompt);
      buffer.writeln();
    }
    for (final msg in history) {
      final prefix = msg.isUser ? 'Human: ' : 'Assistant: ';
      buffer.writeln('$prefix${msg.content}');
    }
    buffer.write('Assistant: ');
    return buffer.toString();
  }
}
