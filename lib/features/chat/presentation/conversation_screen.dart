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

    final isModelLoaded = backendAsync.valueOrNull != null;

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
                      return _MessageBubble(
                        content:
                            streamingText.isEmpty ? '▌' : '$streamingText▌',
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
    required this.content,
    required this.isUser,
    required this.isStreaming,
  });

  final String content;
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
        child: Text(
          content,
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
