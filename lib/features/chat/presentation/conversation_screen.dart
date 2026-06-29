import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/inference_provider.dart';
import '../data/conversation_repository.dart';
import '../domain/message_role.dart';
import 'chat_notifier.dart';
import 'conversation_list_notifier.dart';

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

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
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
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    try {
      await ref
          .read(chatNotifierProvider(widget.conversationId).notifier)
          .send(text);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

    final isModelLoaded = backendAsync.valueOrNull != null;
    final isStreaming = chatAsync.valueOrNull?.isStreaming ?? false;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(conversation?.title ?? 'Chat'),
        actions: [
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
              color: isToolsEnabled
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            tooltip: isToolsEnabled
                ? 'Tools on — tap to disable'
                : 'Tools off — tap to enable',
            onPressed: () => ref
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
          if (!isModelLoaded)
            MaterialBanner(
              content: const Text('No model loaded. Go to the Models tab.'),
              actions: [
                TextButton(onPressed: () {}, child: const Text('Dismiss')),
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
                        return _MessageBubble(
                          isUser: false,
                          isStreaming: true,
                          child: _TypingIndicator(
                            color: Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer,
                          ),
                        );
                      }
                      return _MessageBubble(
                        content: '$streamingText▌',
                        isUser: false,
                        isStreaming: true,
                      );
                    }
                    final msg = messages[index];
                    return _MessageBubble(
                      content: msg.content,
                      isUser: msg.role == MessageRole.user,
                      isStreaming: false,
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
            child: Row(
              children: [
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
                // While streaming, the Send button becomes a Stop button that
                // halts generation and keeps the partial reply.
                if (isStreaming)
                  IconButton.filled(
                    icon: const Icon(Icons.stop),
                    tooltip: 'Stop generating',
                    onPressed: () => ref
                        .read(chatNotifierProvider(widget.conversationId)
                            .notifier)
                        .stop(),
                  )
                else
                  IconButton.filled(
                    icon: const Icon(Icons.send),
                    onPressed: isModelLoaded ? _sendMessage : null,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    this.content,
    this.child,
    required this.isUser,
    required this.isStreaming,
  }) : assert(content != null || child != null,
            'Provide either content or child');

  /// Text to render. Ignored when [child] is supplied.
  final String? content;

  /// Custom bubble body (e.g. the typing indicator). Takes precedence
  /// over [content].
  final Widget? child;
  final bool isUser;
  final bool isStreaming;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? colorScheme.primaryContainer
              : colorScheme.secondaryContainer,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: child ??
            Text(
              content!,
              style: TextStyle(
                color: isUser
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSecondaryContainer,
                fontStyle: isStreaming ? FontStyle.italic : FontStyle.normal,
              ),
            ),
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
