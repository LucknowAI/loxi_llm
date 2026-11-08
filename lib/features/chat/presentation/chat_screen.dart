import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/inference_provider.dart';
import '../../models/presentation/models_notifier.dart';
import 'conversation_list_notifier.dart';
import 'widgets/chat_markdown_text.dart';

/// Subtitle for a chat row. Empty [modelName] is just the time, so a chat
/// with no saved model does not say "No model".
String conversationMeta({
  required String modelName,
  required int updatedAtMs,
  DateTime? now,
}) {
  final when = _timeAgo(updatedAtMs, now ?? DateTime.now());
  if (modelName.isEmpty) return when;
  return '$modelName · $when';
}

String _timeAgo(int updatedAtMs, DateTime now) {
  final then = DateTime.fromMillisecondsSinceEpoch(updatedAtMs);
  final delta = now.difference(then);
  if (delta.inMinutes < 1) return 'Just now';
  if (delta.inHours < 1) return '${delta.inMinutes}m ago';
  if (delta.inDays < 1) return '${delta.inHours}h ago';
  if (delta.inDays < 7) return '${delta.inDays}d ago';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${then.day} ${months[then.month - 1]}';
}

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backendAsync = ref.watch(inferenceNotifierProvider);

    return backendAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: Center(child: Text('Engine error: $e')),
      ),
      data: (backend) => backend == null
          ? Scaffold(
              appBar: AppBar(
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                title: const Text('Chat'),
              ),
              body: const Center(
                child: Text(
                  'Load a model from the Models tab\nto start chatting.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : const _ConversationListView(),
    );
  }
}

class _ConversationListView extends ConsumerWidget {
  const _ConversationListView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationListNotifierProvider);
    final notifier = ref.read(conversationListNotifierProvider.notifier);
    ref.watch(inferenceNotifierProvider);
    final loadedModel =
        ref.read(inferenceNotifierProvider.notifier).loadedModel;
    final modelNames = {
      for (final model
          in ref.watch(modelsNotifierProvider).valueOrNull ?? const [])
        model.id: model.name,
    };
    final colorScheme = Theme.of(context).colorScheme;

    void startNewConversation() {
      final id = notifier.createConversation(modelId: loadedModel?.id ?? '');
      context.go('/chat/$id');
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.inversePrimary,
        title: const Text('Conversations'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New Chat'),
        onPressed: startNewConversation,
      ),
      body: conversationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (conversations) {
          if (conversations.isEmpty) {
            return _EmptyChats(onStart: startNewConversation);
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conv = conversations[index];
              final storedId = conv.modelId;
              final modelName =
                  storedId.isEmpty ? '' : (modelNames[storedId] ?? storedId);
              return _ConversationCard(
                title: conv.title,
                subtitle: conversationMeta(
                  modelName: modelName,
                  updatedAtMs: conv.updatedAtMs,
                ),
                onTap: () => context.go('/chat/${conv.id}'),
                onDelete: () => notifier.deleteConversation(conv.id),
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyChats extends StatelessWidget {
  const _EmptyChats({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 48, color: colorScheme.outline),
            const SizedBox(height: 12),
            Text('No chats yet', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Start one with the model you have loaded.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Start New Chat'),
              onPressed: onStart,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationCard extends StatelessWidget {
  const _ConversationCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.onDelete,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(
            Icons.chat_bubble_outline,
            size: 20,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        title: ChatMarkdownText(
          title,
          style: Theme.of(context).textTheme.titleMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          inlineOnly: true,
        ),
        subtitle: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Delete chat',
          onPressed: onDelete,
        ),
        onTap: onTap,
      ),
    );
  }
}
