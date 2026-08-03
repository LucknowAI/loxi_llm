import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/inference_provider.dart';
import 'conversation_list_notifier.dart';

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

    void startNewConversation() {
      final id = notifier.createConversation();
      context.go('/chat/$id');
    }

    ref.watch(inferenceNotifierProvider);
    final loadedModel =
        ref.read(inferenceNotifierProvider.notifier).loadedModel;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Conversations'),
        bottom: loadedModel != null
            ? PreferredSize(
                preferredSize: const Size.fromHeight(28),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      'Model: ${loadedModel.name}',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                ),
              )
            : null,
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New Chat'),
        onPressed: startNewConversation,
      ),
      body: conversationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (conversations) => conversations.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No conversations yet.'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Start New Chat'),
                      onPressed: startNewConversation,
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: conversations.length,
                itemBuilder: (context, index) {
                  final conv = conversations[index];
                  return ListTile(
                    title: Text(conv.title),
                    subtitle: Text(
                        conv.modelId.isNotEmpty ? conv.modelId : 'No model'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => notifier.deleteConversation(conv.id),
                    ),
                    onTap: () => context.go('/chat/${conv.id}'),
                  );
                },
              ),
      ),
    );
  }
}
