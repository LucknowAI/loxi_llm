import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/engine/chat_template.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/logging/model_io_logger.dart';
import '../../../core/logging/model_io_trace.dart';
import '../../../core/providers/embedding_provider.dart';
import '../../../core/providers/inference_provider.dart';
import '../../agent/application/agent_loop.dart';
import '../../agent/agent_model_support.dart';
import '../../agent/data/tool_registry_factory.dart';
import '../../agent/domain/tool_call_grammar.dart';
import '../application/conversation_summarizer.dart';
import '../application/prompt_builder.dart';
import '../data/conversation_repository.dart';
import '../data/message_repository.dart';
import '../domain/message.dart';
import '../domain/message_role.dart';
import '../../documents/data/document_chunk_repository.dart';
import '../../documents/data/document_repository.dart';
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

    // Resolve the running model + template once — used by summarization and by
    // both the agent and streaming paths. The loaded model is authoritative
    // (the persisted ModelStatus.loaded flag is reset on startup, and
    // conversation.modelId is often empty). Precedence: loaded → conversation →
    // generic fallback.
    final loadedModel = ref.read(inferenceNotifierProvider.notifier).loadedModel;
    final modelName = loadedModel?.name ?? 'unknown';
    final modelId = loadedModel?.id ?? (conversation?.modelId ?? '');
    final template = ChatTemplate.forModelId(modelId);

    // Rolling memory: fold any newly-evicted (beyond-window) messages into the
    // conversation summary before building the prompt.
    final allMessages = [...current.messages, userMsg];
    final summary = await _ensureSummary(
      allMessages: allMessages,
      existingSummary: conversation?.summary ?? '',
      summarizedCount: conversation?.summarizedCount ?? 0,
      template: template,
    );

    // Tool-calling agent path (per-conversation toggle). When enabled and the
    // loaded model supports tools, the model decides which tools to call; the
    // auto-RAG/streaming path below is skipped. Plain chat is unchanged.
    if (conversation?.toolsEnabled ?? false) {
      final loadedModel =
          ref.read(inferenceNotifierProvider.notifier).loadedModel;
      if (isAgentCapableModel(loadedModel?.id)) {
        final ragEnabled = conversation?.ragEnabled ?? false;
        final ragChunks =
            await _retrieveRagChunks(userMsg.content, ragEnabled);
        await _runAgentTurn(
          allMessages,
          template,
          modelName,
          summary,
          ragEnabled: ragEnabled,
          ragChunks: ragChunks,
        );
        return;
      }
      log.warn(_logTag,
          'tools enabled but model ${loadedModel?.id ?? "none"} does not support agent mode; using plain chat');
    }

    // Build RAG context if enabled for this conversation
    final ragEnabled = conversation?.ragEnabled ?? false;
    log.debug(_logTag,
        'ragEnabled=$ragEnabled historyMessages=${current.messages.length}');
    List<DocumentChunk> ragChunks = const [];
    if (ragEnabled) {
      ragChunks = await _retrieveRagChunks(userMsg.content, ragEnabled);
    }

    // Build the prompt with the model's real chat template + rolling summary.
    // RAG chunks fold into the last user turn (see ChatTemplate.format).
    final prompt = buildPrompt(
      template: template,
      turns: _historyTurns(allMessages),
      systemPrompt: conversation?.systemPrompt ?? '',
      summary: summary,
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

  /// Fold any messages that have fallen outside the prompt window into the
  /// conversation's rolling summary, persisting it. Returns the (possibly
  /// updated) summary. Lazy: only runs when the conversation outgrows the window
  /// and only summarizes the newly-evicted delta. Failures are non-fatal.
  Future<String> _ensureSummary({
    required List<Message> allMessages,
    required String existingSummary,
    required int summarizedCount,
    required ChatTemplate template,
  }) async {
    final evictBoundary = allMessages.length - _maxHistoryMessages;
    if (evictBoundary <= summarizedCount) return existingSummary;

    final backend = ref.read(inferenceNotifierProvider).valueOrNull;
    if (backend == null) return existingSummary;

    final evicted = allMessages.sublist(summarizedCount, evictBoundary);
    final log = AppLogger.instance;
    log.info(_logTag, 'summarizing ${evicted.length} evicted message(s)');

    final summarizer = ConversationSummarizer(
      generate: (instruction) async {
        final prompt = buildPrompt(
          template: template,
          turns: [ChatTurn(MessageRole.user, instruction)],
        );
        final buffer = StringBuffer();
        await for (final token in backend
            .generate(prompt, stopSequences: template.stopSequences)
            .timeout(const Duration(seconds: 120))) {
          buffer.write(token);
        }
        return buffer.toString();
      },
    );

    try {
      final summary = await summarizer.summarize(
        existingSummary: existingSummary,
        newMessages: evicted,
      );
      final conv =
          ref.read(conversationRepositoryProvider).getById(conversationId);
      if (conv != null) {
        ref.read(conversationRepositoryProvider).save(
              conv.copyWith(summary: summary, summarizedCount: evictBoundary),
            );
      }
      return summary;
    } catch (e, st) {
      log.warn(_logTag, 'summarization failed (continuing): $e\n$st');
      return existingSummary;
    }
  }

  /// Run one tool-calling agent turn over [history] (the user message is the
  /// last entry). Each generation is peeked: tool-call generations are buffered
  /// silently while a "Using <tool>…" status shows, and the final answer streams
  /// token-by-token, then is saved as the assistant message.
  Future<void> _runAgentTurn(
    List<Message> history,
    ChatTemplate template,
    String modelName,
    String summary, {
    required bool ragEnabled,
    required List<DocumentChunk> ragChunks,
  }) async {
    final log = AppLogger.instance;
    final backend = ref.read(inferenceNotifierProvider).valueOrNull;
    if (backend == null) return;

    final conversation =
        ref.read(conversationRepositoryProvider).getById(conversationId);

    final settings = ref.read(settingsNotifierProvider);
    final embService = ref.read(embeddingServiceProvider).valueOrNull;
    final chunkRepo = ref.read(documentChunkRepositoryProvider);
    final registry = buildDefaultToolRegistry(
      ToolRegistryDeps(
        conversationId: conversationId,
        messageRepo: ref.read(messageRepositoryProvider),
        documentRepo: ref.read(documentRepositoryProvider),
        chunkRepo: chunkRepo,
        embedQuery: (q) async {
          if (embService == null || !embService.isInitialized) {
            throw StateError('embedding service unavailable');
          }
          return embService.embedQuery(q);
        },
        topK: settings.topK,
        chunkSize: settings.chunkSize,
        summary: summary,
        historyWindow: _maxHistoryMessages,
      ),
      enabledToolNames: settings.enabledToolNames,
    );
    final grammar = ToolCallGrammar.build(registry);
    final ragContext = _buildRagContext(ragChunks);
    final ragChunkTexts = ragChunks.map((c) => c.content).toList();

    final captureIo = settings.modelIoLoggingEnabled;
    var agentIteration = 0;

    if (state.valueOrNull != null) {
      state = AsyncData(
        state.requireValue.copyWith(streamingText: 'Thinking…'),
      );
    }

    // One model call, streamed:
    Stream<String> generateStream(List<ChatTurn> turns) async* {
      final iteration = agentIteration++;
      final prompt = buildPrompt(
        template: template,
        turns: turns,
        systemPrompt: conversation?.systemPrompt ?? '',
        toolInstructions: registry.promptDescription(),
        summary: summary,
        ragContext: ragContext,
      );
      log.info(_logTag,
          'agent generate (${template.kind.name}): ${prompt.length} chars');
      await log.flush();
      final startMs = DateTime.now().millisecondsSinceEpoch;
      final buffer = StringBuffer();
      var tokens = 0;
      await for (final token in backend
          .generate(
            prompt,
            stopSequences: template.stopSequences,
            grammar: grammar,
          )
          .timeout(const Duration(seconds: 120))) {
        buffer.write(token);
        tokens++;
        yield token;
      }
      if (captureIo) {
        ModelIoLogger.instance.record(ModelIoTrace(
          timestampMs: startMs,
          conversationId: conversationId,
          modelName: modelName,
          backendType: backend.runtimeType.toString(),
          inputPrompt: prompt,
          generationParams: backend.generationParams,
          ragEnabled: ragEnabled,
          ragChunks: ragChunkTexts,
          outputText: buffer.toString(),
          tokenCount: tokens,
          timeToFirstTokenMs: null,
          totalDurationMs: DateTime.now().millisecondsSinceEpoch - startMs,
          outcome: TraceOutcome.done,
          agentIteration: iteration,
        ));
      }
    }

    // Accumulates the streamed final answer so the UI shows it live.
    final answerBuffer = StringBuffer();
    final loop = AgentLoop(
      generateStream: generateStream,
      registry: registry,
      onToolCall: (toolName) {
        if (state.valueOrNull != null) {
          state = AsyncData(
            state.requireValue.copyWith(streamingText: 'Using $toolName…'),
          );
        }
      },
      onAnswerToken: (token) {
        answerBuffer.write(token);
        if (state.valueOrNull != null) {
          state = AsyncData(
            state.requireValue.copyWith(streamingText: answerBuffer.toString()),
          );
        }
      },
      onToolResult: (toolName, observation, iteration) {
        if (!captureIo) return;
        ModelIoLogger.instance.record(ModelIoTrace(
          timestampMs: DateTime.now().millisecondsSinceEpoch,
          conversationId: conversationId,
          modelName: modelName,
          backendType: backend.runtimeType.toString(),
          inputPrompt: '',
          generationParams: const {},
          ragEnabled: ragEnabled,
          ragChunks: ragChunkTexts,
          outputText: '',
          tokenCount: 0,
          timeToFirstTokenMs: null,
          totalDurationMs: 0,
          outcome: TraceOutcome.done,
          agentIteration: iteration,
          toolName: toolName,
          toolResult: observation,
        ));
      },
    );

    try {
      final result = await loop.run(_historyTurns(history));
      final assistantMs = DateTime.now().millisecondsSinceEpoch;
      final assistantMsg = Message(
        id: 'msg-$assistantMs',
        conversationId: conversationId,
        role: MessageRole.assistant,
        content: result.answer,
        createdAtMs: assistantMs,
      );
      ref.read(messageRepositoryProvider).save(assistantMsg);
      final conv = ref.read(conversationRepositoryProvider).getById(conversationId);
      if (conv != null) {
        ref
            .read(conversationRepositoryProvider)
            .save(conv.copyWith(updatedAtMs: assistantMs));
      }
      state = AsyncData(state.requireValue.copyWith(
        messages: [...state.requireValue.messages, assistantMsg],
        clearStreaming: true,
      ));
      log.info(_logTag,
          'agent done: ${result.steps.length} tool step(s), cap=${result.hitIterationCap}');
    } catch (e, st) {
      log.error(_logTag, 'agent loop failed', e, st);
      state = AsyncError(e, st);
    }
  }

  /// Retrieve similar document chunks for [query] when [ragEnabled] is true.
  /// Failures are non-fatal — returns an empty list.
  Future<List<DocumentChunk>> _retrieveRagChunks(
    String query,
    bool ragEnabled,
  ) async {
    if (!ragEnabled) return const [];
    final log = AppLogger.instance;
    final embService = ref.read(embeddingServiceProvider).valueOrNull;
    if (embService == null || !embService.isInitialized) {
      log.debug(_logTag, 'RAG: embedding service unavailable, skipping');
      return const [];
    }
    try {
      log.debug(_logTag, 'RAG: embedding query');
      final queryVec = await embService.embedQuery(query);
      final topK = ref.read(settingsNotifierProvider).topK;
      final chunks = ref
          .read(documentChunkRepositoryProvider)
          .findSimilar(queryVec, topK: topK);
      log.debug(_logTag, 'RAG: retrieved ${chunks.length} chunks');
      return chunks;
    } catch (e, st) {
      log.warn(_logTag, 'RAG retrieval failed (continuing): $e\n$st');
      return const [];
    }
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
