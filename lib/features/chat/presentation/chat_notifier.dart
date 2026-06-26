import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/engine/chat_template.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/logging/model_io_logger.dart';
import '../../../core/logging/model_io_trace.dart';
import '../../../core/providers/embedding_provider.dart';
import '../../../core/providers/inference_provider.dart';
import '../data/conversation_repository.dart';
import '../data/message_repository.dart';
import '../domain/message.dart';
import '../domain/message_role.dart';
import '../../documents/data/document_chunk_repository.dart';
import '../../documents/domain/document_chunk.dart';
import '../../settings/presentation/settings_notifier.dart';
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

  /// True between a user Stop request and the stream actually ending, so the
  /// trace can be tagged [TraceOutcome.stopped] rather than `done`.
  bool _stopRequested = false;

  @override
  Future<ChatState> build(String conversationId) async {
    ref.onDispose(() => _tokenSub?.cancel());
    final messages =
        ref.watch(messageRepositoryProvider).getMessages(conversationId);
    return ChatState(messages: messages);
  }

  static const _logTag = 'ChatNotifier';

  /// Send a user message and stream the assistant response.
  Future<void> send(String userText) async {
    final log = AppLogger.instance;
    if (userText.trim().isEmpty) return;
    _stopRequested = false;

    log.info(_logTag,
        'send() conversation=$conversationId userTextLen=${userText.trim().length}');

    final backend = ref.read(inferenceNotifierProvider).valueOrNull;
    if (backend == null) {
      log.warn(_logTag, 'send() aborted — no model loaded');
      throw StateError('No model loaded');
    }
    log.debug(_logTag, 'backend=${backend.runtimeType} isLoaded=${backend.isLoaded}');

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

    // Build RAG context if enabled for this conversation
    final ragEnabled = conversation?.ragEnabled ?? false;
    log.debug(_logTag,
        'ragEnabled=$ragEnabled historyMessages=${current.messages.length}');
    List<DocumentChunk> ragChunks = const [];
    if (ragEnabled) {
      final embService = ref.read(embeddingServiceProvider).valueOrNull;
      if (embService != null && embService.isInitialized) {
        try {
          log.debug(_logTag, 'RAG: embedding query');
          final queryVec = await embService.embedQuery(userMsg.content);
          final topK = ref.read(settingsNotifierProvider).topK;
          ragChunks = ref
              .read(documentChunkRepositoryProvider)
              .findSimilar(queryVec, topK: topK);
          log.debug(_logTag, 'RAG: retrieved ${ragChunks.length} chunks');
        } catch (e, st) {
          // RAG retrieval failure is non-fatal — continue without context
          log.warn(_logTag, 'RAG retrieval failed (continuing): $e\n$st');
        }
      } else {
        log.debug(_logTag, 'RAG: embedding service unavailable, skipping');
      }
    }

    // Resolve the model that will actually run this generation from the
    // authoritative source — the model loaded into the backend. The persisted
    // ModelStatus.loaded flag is unreliable (reset on startup reconciliation),
    // and conversation.modelId is often empty. The chat template + stop
    // sequences must match the running model. Precedence: loaded model →
    // conversation.modelId → generic fallback.
    final loadedModel = ref.read(inferenceNotifierProvider.notifier).loadedModel;
    final modelName = loadedModel?.name ?? 'unknown';
    final modelId = loadedModel?.id ?? (conversation?.modelId ?? '');
    final template = ChatTemplate.forModelId(modelId);

    // Build the prompt using the model's real chat template. RAG chunks fold
    // into the last user turn (see ChatTemplate.format).
    final systemPrompt = conversation?.systemPrompt ?? '';
    final prompt = template.format(
      _historyTurns([...current.messages, userMsg]),
      systemPrompt,
      ragContext: _buildRagContext(ragChunks),
    );
    // ~4 chars/token is a rough heuristic for spotting context-window issues.
    log.info(_logTag,
        'prompt built (${template.kind.name}): ${prompt.length} chars '
        '(~${(prompt.length / 4).round()} tokens est)');

    // Stream tokens (60-second timeout resets after each token)
    final buffer = StringBuffer();
    var tokenCount = 0;
    _tokenSub?.cancel();

    // Model I/O trace capture — only when the setting is enabled (zero cost
    // otherwise). Reading the setting also syncs ModelIoLogger.enabled.
    // Snapshot the inputs now; metrics are filled in as we stream.
    final ioLogger = ModelIoLogger.instance;
    final captureIo =
        ref.read(settingsNotifierProvider).modelIoLoggingEnabled;
    final genStartMs = DateTime.now().millisecondsSinceEpoch;
    int? firstTokenMs;

    void recordIo(TraceOutcome outcome, {String? error}) {
      if (!captureIo) return;
      ioLogger.record(ModelIoTrace(
        timestampMs: genStartMs,
        conversationId: conversationId,
        modelName: modelName,
        backendType: backend.runtimeType.toString(),
        inputPrompt: prompt,
        generationParams: backend.generationParams,
        ragEnabled: ragEnabled,
        ragChunks: ragChunks.map((c) => c.content).toList(),
        outputText: buffer.toString(),
        tokenCount: tokenCount,
        timeToFirstTokenMs: firstTokenMs,
        totalDurationMs: DateTime.now().millisecondsSinceEpoch - genStartMs,
        outcome: outcome,
        error: error,
      ));
    }

    // Flush logs to disk BEFORE entering native inference — a native crash
    // aborts the process and Dart cannot catch it, but bytes already flushed
    // survive, so the last line tells us we reached the native call.
    log.info(_logTag, 'invoking native generate()');
    await log.flush();

    _tokenSub = backend
        .generate(prompt, stopSequences: template.stopSequences)
        .timeout(const Duration(seconds: 60))
        .listen(
      (token) {
        if (tokenCount == 0) {
          log.info(_logTag, 'first token received');
          firstTokenMs = DateTime.now().millisecondsSinceEpoch - genStartMs;
        }
        tokenCount++;
        buffer.write(token);
        state = AsyncData(
          state.requireValue.copyWith(streamingText: buffer.toString()),
        );
      },
      onDone: () {
        log.info(_logTag,
            'generation ${_stopRequested ? 'stopped' : 'done'}: '
            '$tokenCount tokens, ${buffer.length} chars');
        recordIo(_stopRequested ? TraceOutcome.stopped : TraceOutcome.done);
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
        AppLogger.instance
            .error(_logTag, 'generation error after $tokenCount tokens', e, st);
        recordIo(
          e is TimeoutException ? TraceOutcome.timeout : TraceOutcome.error,
          error: e.toString(),
        );
        state = AsyncError(e, st);
      },
      cancelOnError: true,
    );
  }

  /// Most recent conversation messages to include in the prompt. Older turns
  /// are dropped so a long conversation never produces a prompt that overflows
  /// the model's context window (the native backend hard-truncates beyond
  /// this, but windowing here preserves the system prompt + RAG context).
  static const int _maxHistoryMessages = 20;

  /// Stop the in-flight generation. The partial reply already streamed is kept
  /// (the stream's onDone saves it). No-op when nothing is streaming.
  Future<void> stop() async {
    if (!(state.valueOrNull?.isStreaming ?? false)) return;
    _stopRequested = true;
    AppLogger.instance.info(_logTag, 'stop() requested');
    final backend = ref.read(inferenceNotifierProvider).valueOrNull;
    await backend?.stop();
  }

  /// Map the most recent [history] messages to template turns, dropping older
  /// turns so a long conversation never overflows the context window.
  List<ChatTurn> _historyTurns(List<Message> history) {
    final windowed = history.length > _maxHistoryMessages
        ? history.sublist(history.length - _maxHistoryMessages)
        : history;
    return [for (final m in windowed) ChatTurn(m.role, m.content)];
  }

  /// Assemble retrieved RAG chunks into a labeled context block, or '' when
  /// there are none. ChatTemplate folds this into the last user turn.
  String _buildRagContext(List<DocumentChunk> ragChunks) {
    if (ragChunks.isEmpty) return '';
    final buffer = StringBuffer();
    buffer.writeln('Use the following context to answer the question:');
    for (int i = 0; i < ragChunks.length; i++) {
      buffer.write('[${i + 1}] ${ragChunks[i].content}');
      if (i < ragChunks.length - 1) buffer.writeln();
    }
    return buffer.toString();
  }
}
