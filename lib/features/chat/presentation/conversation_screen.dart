import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/engine/inference_backend.dart';
import '../../../core/providers/download_provider.dart';
import '../../../core/providers/inference_provider.dart';
import '../../../core/providers/tts_provider.dart';
import '../../agent/agent_model_support.dart';
import '../../models/domain/model.dart';
import '../application/conversation_markdown_exporter.dart';
import '../data/conversation_repository.dart';
import '../domain/conversation.dart';
import '../domain/message.dart';
import '../domain/message_role.dart';
import 'chat_notifier.dart';
import 'conversation_list_notifier.dart';
import 'widgets/message_bubble.dart';

/// Whether a pending image attachment should survive an inference-state
/// change. True while a load is in flight ([next] is [AsyncLoading]) — only
/// a settled `AsyncData`/`AsyncError` should ever decide to drop an
/// attachment, otherwise reloading (or switching between) vision-capable
/// models would wipe it on every transient loading tick. Once settled, true
/// only when [loadedModel] is both catalog-multimodal and the new backend
/// itself reports vision support.
bool stillAllowsAttachment(
  AsyncValue<InferenceBackend?> next,
  Model? loadedModel,
) {
  if (next is AsyncLoading) return true;
  return loadedModel != null &&
      isMultimodalModel(loadedModel) &&
      (next.valueOrNull?.supportsVision ?? false);
}

/// Path to put back into the composer after [ChatNotifier.send] throws, or
/// null to leave the attachment cleared.
///
/// `send()` throws before persisting in two cases today: no model loaded
/// (file still on disk — restore so the user can retry) and attached image
/// missing (file gone — leave cleared; restoring would show a broken
/// thumbnail while the SnackBar already asked them to re-attach).
Future<String?> attachedPathToRestoreAfterSendError(String? imagePath) async {
  if (imagePath == null) return null;
  if (!await File(imagePath).exists()) return null;
  return imagePath;
}

/// Whether `_sendMessage`'s composer should restore its cleared text and
/// attachment after `send()` throws [error] — true for a pre-persist
/// failure (nothing was actually sent, so there's something worth
/// retrying), false for [SendFailedAfterPersistException] (the message
/// already went through; restoring would risk a near-duplicate resend).
bool shouldRestoreComposerAfterSendError(Object error) =>
    error is! SendFailedAfterPersistException;

class ConversationScreen extends ConsumerStatefulWidget {
  const ConversationScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ConversationScreen> createState() =>
      _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  late final TextEditingController _textController;
  late final ScrollController _scrollController;

  /// Message id currently being read aloud, if any.
  String? _speakingMessageId;

  /// Path to an image attached to the message being composed, if any. Copied
  /// into app storage so it survives independently of the picker's temp file.
  String? _attachedImagePath;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    ref.read(ttsServiceProvider).stop();
    _textController.dispose();
    _scrollController.dispose();
    if (_attachedImagePath != null) {
      // Fire-and-forget: dispose() can't be async. An unsent attachment
      // shouldn't outlive the screen it was picked on.
      ref.read(fileStorageServiceProvider).deleteImage(_attachedImagePath!);
    }
    super.dispose(); // MUST be last
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final rawText = _textController.text;
    final text = rawText.trim();
    final imagePath = _attachedImagePath;
    if (text.isEmpty && imagePath == null) return;
    // Clear the composer immediately/optimistically, text and attachment
    // together, rather than waiting for send() to resolve — which for an
    // agent-mode turn can take a long time (it awaits the whole turn, not
    // just the initial call). Hand off ownership of the attachment to
    // send() at the same time: once it persists the message, the message
    // (not the composer) owns the file, so dispose()/the vision-gate below
    // must no longer touch it — otherwise a slow send() (RAG retrieval,
    // summarization) leaves a window where navigating away or switching
    // models deletes a file the already-persisted message still points to.
    //
    // On a pre-persist throw (nothing sent), both are restored together —
    // the attachment only if the file still exists, see
    // [attachedPathToRestoreAfterSendError]. On a post-persist one
    // ([SendFailedAfterPersistException]), neither is restored: the message
    // already went through, so putting the text/attachment back would risk
    // a near-duplicate resend. See [shouldRestoreComposerAfterSendError].
    _textController.clear();
    setState(() => _attachedImagePath = null);
    try {
      await ref
          .read(chatNotifierProvider(widget.conversationId).notifier)
          .send(text, imagePath: imagePath);
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      final shouldRestore = shouldRestoreComposerAfterSendError(e);
      if (shouldRestore) {
        _textController.text = rawText;
        final restore = await attachedPathToRestoreAfterSendError(imagePath);
        if (!mounted) return;
        if (restore != null) setState(() => _attachedImagePath = restore);
      } else {
        // The message was already persisted and is showing in the chat
        // above — nothing to retry, just scroll to it.
        _scrollToBottom();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(shouldRestore ? 'Error: $e' : 'Message sent, but: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      final picked = result?.files.single;
      if (picked?.path == null || !mounted) return;

      final storage = ref.read(fileStorageServiceProvider);
      final filename =
          'img-${DateTime.now().millisecondsSinceEpoch}${_extensionOf(picked!)}';
      final destPath = await storage.getImagePath(filename);
      await File(picked.path!).copy(destPath);

      // Replace any previously attached (unsent) image so it doesn't leak.
      final previous = _attachedImagePath;
      if (mounted) setState(() => _attachedImagePath = destPath);
      if (previous != null) await storage.deleteImage(previous);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not attach image: $e')),
        );
      }
    }
  }

  /// [PlatformFile.extension] splits the picked *filename*, not the full
  /// path — unlike splitting the path directly, it isn't fooled by dots
  /// earlier in an Android cache path (e.g. a package name). Falls back to
  /// `.jpg` when the filename itself has no extension (e.g. some picker
  /// implementations return an extensionless scaled-cache filename).
  String _extensionOf(PlatformFile file) {
    final ext = file.extension;
    if (ext == null || ext == file.name) return '.jpg';
    return '.$ext';
  }

  void _removeAttachedImage() {
    final stale = _attachedImagePath;
    setState(() => _attachedImagePath = null);
    if (stale != null) ref.read(fileStorageServiceProvider).deleteImage(stale);
  }

  void _editSystemPrompt() {
    final conversation = ref
        .read(conversationRepositoryProvider)
        .getById(widget.conversationId);
    if (conversation == null) return;

    final controller = TextEditingController(text: conversation.systemPrompt);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('System Prompt'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Enter system prompt (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(conversationListNotifierProvider.notifier)
                  .updateSystemPrompt(
                    widget.conversationId,
                    controller.text,
                  );
              Navigator.of(ctx).pop();
              controller.dispose();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _copyText(String text, {required String confirmation}) async {
    if (text.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    _showSnack(confirmation);
  }

  Future<void> _shareConversation(
    Conversation conversation,
    List<Message> messages,
  ) async {
    if (messages.isEmpty) {
      _showSnack('Nothing to export yet');
      return;
    }
    final markdown = exportConversationMarkdown(
      conversation: conversation,
      messages: messages,
    );
    await SharePlus.instance.share(
      ShareParams(text: markdown, subject: conversation.title),
    );
  }

  Future<void> _copyConversation(
    Conversation conversation,
    List<Message> messages,
  ) async {
    if (messages.isEmpty) {
      _showSnack('Nothing to copy yet');
      return;
    }
    await _copyText(
      exportConversationMarkdown(
        conversation: conversation,
        messages: messages,
      ),
      confirmation: 'Conversation copied to clipboard',
    );
  }

  Future<void> _toggleReadAloud(Message message) async {
    final tts = ref.read(ttsServiceProvider);
    if (!tts.isSupported) {
      _showSnack('Read aloud is available on Android');
      return;
    }
    if (_speakingMessageId == message.id) {
      await tts.stop();
      setState(() => _speakingMessageId = null);
      return;
    }
    await tts.stop();
    setState(() => _speakingMessageId = message.id);
    await tts.speak(message.content);
    if (mounted && _speakingMessageId == message.id) {
      setState(() => _speakingMessageId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatAsync = ref.watch(chatNotifierProvider(widget.conversationId));
    final backendAsync = ref.watch(inferenceNotifierProvider);
    final conversation = ref
        .watch(conversationRepositoryProvider)
        .getById(widget.conversationId);
    final conversations =
        ref.watch(conversationListNotifierProvider).valueOrNull ?? [];
    final currentConv = conversations
        .where((c) => c.id == widget.conversationId)
        .firstOrNull;
    final isRagEnabled = currentConv?.ragEnabled ?? false;
    final isToolsEnabled = currentConv?.toolsEnabled ?? false;
    final loadedModel = ref.watch(inferenceNotifierProvider.notifier).loadedModel;
    final agentCapable = isAgentCapableModel(loadedModel?.id);
    // Catalog data (isMultimodalModel) only says the model *should* support
    // vision; backend.supportsVision is the native-verified layer (the mmproj
    // actually loaded and reported vision support) — both must hold before
    // the attach button appears.
    final canAttachImage = loadedModel != null &&
        isMultimodalModel(loadedModel) &&
        (backendAsync.valueOrNull?.supportsVision ?? false);

    final isModelLoaded = backendAsync.valueOrNull != null;
    final isStreaming = chatAsync.valueOrNull?.isStreaming ?? false;
    final exportConversation = conversation ?? currentConv;

    // The chat tab is kept alive in an IndexedStack, so switching to a
    // non-vision model doesn't dispose this screen — drop any pending
    // attachment rather than let it silently ride along on the next send.
    // Only a path the composer still owns is deleted here: once send() has
    // handed a path off (see _sendMessage), _attachedImagePath is already
    // null, so an in-flight send's already-persisted image is untouched.
    ref.listen(inferenceNotifierProvider, (previous, next) {
      final model = ref.read(inferenceNotifierProvider.notifier).loadedModel;
      if (stillAllowsAttachment(next, model) || _attachedImagePath == null) {
        return;
      }
      final stale = _attachedImagePath!;
      setState(() => _attachedImagePath = null);
      ref.read(fileStorageServiceProvider).deleteImage(stale);
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(conversation?.title ?? 'Chat'),
        actions: [
          if (exportConversation != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.ios_share_outlined),
              tooltip: 'Export conversation',
              onSelected: (value) {
                final messages =
                    chatAsync.valueOrNull?.messages ?? const <Message>[];
                switch (value) {
                  case 'share':
                    _shareConversation(exportConversation, messages);
                  case 'copy':
                    _copyConversation(exportConversation, messages);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'share',
                  child: ListTile(
                    leading: Icon(Icons.share_outlined),
                    title: Text('Share as Markdown'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'copy',
                  child: ListTile(
                    leading: Icon(Icons.copy_all_outlined),
                    title: Text('Copy conversation'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          IconButton(
            icon: Icon(
              isRagEnabled ? Icons.auto_awesome : Icons.auto_awesome_outlined,
              color: isRagEnabled
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            tooltip: isRagEnabled
                ? 'RAG mode on — tap to disable'
                : 'RAG mode off — tap to enable',
            onPressed: () => ref
                .read(conversationListNotifierProvider.notifier)
                .toggleRagEnabled(widget.conversationId),
          ),
          IconButton(
            icon: Icon(
              isToolsEnabled ? Icons.build : Icons.build_outlined,
              color: isToolsEnabled && agentCapable
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            tooltip: !agentCapable
                ? 'Tools require Phi-3 or Llama 3.2 3B (load a larger model)'
                : isToolsEnabled
                    ? 'Tools on — tap to disable'
                    : 'Tools off — tap to enable',
            onPressed: !agentCapable
                ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Tool mode requires Phi-3 Mini or Llama 3.2 3B. '
                          'Load a larger model from the Models tab.',
                        ),
                      ),
                    );
                  }
                : () => ref
                    .read(conversationListNotifierProvider.notifier)
                    .toggleToolsEnabled(widget.conversationId),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'System prompt',
            onPressed: _editSystemPrompt,
          ),
        ],
      ),
      body: Column(
        children: [
          // Model status banner
          if (isModelLoaded && loadedModel != null)
            MaterialBanner(
              content: Text('Using ${loadedModel.name}'),
              leading: const Icon(Icons.memory_outlined),
              actions: [
                TextButton(
                  onPressed: () =>
                      ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
                  child: const Text('Dismiss'),
                ),
              ],
            )
          else if (!isModelLoaded)
            MaterialBanner(
              content: const Text('No model loaded. Go to the Models tab.'),
              leading: const Icon(Icons.warning_amber_outlined),
              actions: [
                TextButton(
                  onPressed: () =>
                      ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
                  child: const Text('Dismiss'),
                ),
              ],
            ),

          // Message list
          Expanded(
            child: chatAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (chatState) {
                final messages = chatState.messages;
                final streamingText = chatState.streamingText;

                // Auto-scroll when messages change
                if (messages.isNotEmpty || streamingText != null) {
                  _scrollToBottom();
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length + (streamingText != null ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Streaming bubble at end
                    if (index == messages.length && streamingText != null) {
                      // Before the first token arrives, show an animated
                      // "thinking" indicator so the user knows the model is
                      // working (time-to-first-token can be significant).
                      if (streamingText.isEmpty) {
                        return MessageBubble(
                          isUser: false,
                          isStreaming: true,
                          child: _TypingIndicator(
                            color: Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer,
                          ),
                        );
                      }
                      return MessageBubble(
                        content: '$streamingText▌',
                        isUser: false,
                        isStreaming: true,
                      );
                    }
                    final msg = messages[index];
                    return MessageBubble(
                      content: msg.content,
                      imagePath: msg.imagePath,
                      isUser: msg.role == MessageRole.user,
                      isStreaming: false,
                      onCopy: () => _copyText(
                        msg.content,
                        confirmation: 'Message copied',
                      ),
                      onReadAloud: msg.role == MessageRole.assistant
                          ? () => _toggleReadAloud(msg)
                          : null,
                      isSpeaking: _speakingMessageId == msg.id,
                    );
                  },
                );
              },
            ),
          ),

          // Quick task shortcut chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                for (final entry in const [
                  ('Translate', 'Translate the following to English:\n'),
                  ('Refine', 'Refine and improve the following text:\n'),
                  ('Summarize', 'Summarize the following in 3 bullet points:\n'),
                  ('Explain', 'Explain the following in simple terms:\n'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(entry.$1),
                      onPressed: () {
                        _textController.text = entry.$2;
                        _textController.selection = TextSelection.fromPosition(
                          TextPosition(offset: _textController.text.length),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Text input
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_attachedImagePath != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(_attachedImagePath!),
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            cacheWidth:
                                (64 * MediaQuery.of(context).devicePixelRatio)
                                    .round(),
                            cacheHeight:
                                (64 * MediaQuery.of(context).devicePixelRatio)
                                    .round(),
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              width: 64,
                              height: 64,
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              alignment: Alignment.center,
                              child: const Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        ),
                        Positioned(
                          top: -8,
                          right: -8,
                          child: IconButton(
                            icon: const Icon(Icons.cancel, size: 20),
                            tooltip: 'Remove image',
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: _removeAttachedImage,
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.image_outlined),
                      tooltip: canAttachImage
                          ? 'Attach image'
                          : 'Attaching images requires a vision-capable '
                              'model (e.g. Gemma 4)',
                      onPressed: canAttachImage ? _pickImage : null,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        minLines: 1,
                        maxLines: 4,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // While streaming, the Send button becomes a Stop button
                    // that halts generation and keeps the partial reply.
                    if (isStreaming)
                      IconButton.filled(
                        icon: const Icon(Icons.stop),
                        tooltip: 'Stop generating',
                        onPressed: () {
                          ref.read(ttsServiceProvider).stop();
                          setState(() => _speakingMessageId = null);
                          ref
                              .read(chatNotifierProvider(widget.conversationId)
                                  .notifier)
                              .stop();
                        },
                      )
                    else
                      IconButton.filled(
                        icon: const Icon(Icons.send),
                        onPressed: isModelLoaded ? _sendMessage : null,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated "model is thinking" indicator: three dots that pulse in sequence.
///
/// Shown in the assistant bubble during the gap between sending a prompt and
/// the first streamed token, so the UI never looks frozen.
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator({required this.color});

  final Color color;

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _dotCount = 3;
  static const _dotSize = 7.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose(); // MUST be last
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _dotSize * 2,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_dotCount, (i) {
              // Stagger each dot's phase so the pulse travels left-to-right.
              final phase = (_controller.value - i * 0.18) % 1.0;
              // Triangle wave: 0 -> 1 -> 0 across the phase.
              final wave = (1 - (2 * phase - 1).abs()).clamp(0.0, 1.0);
              return Padding(
                padding: EdgeInsets.only(right: i < _dotCount - 1 ? 5 : 0),
                child: Transform.translate(
                  offset: Offset(0, -3 * wave),
                  child: Opacity(
                    opacity: 0.35 + 0.65 * wave,
                    child: Container(
                      width: _dotSize,
                      height: _dotSize,
                      decoration: BoxDecoration(
                        color: widget.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
