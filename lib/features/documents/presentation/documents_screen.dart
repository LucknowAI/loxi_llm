import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'documents_notifier.dart';

class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(documentsNotifierProvider);
    final notifier = ref.read(documentsNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Documents'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Import'),
        onPressed: () => notifier.pickAndIngest(),
      ),
      body: docsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (docs) => docs.isEmpty
            ? const Center(
                child: Text(
                  'Add documents to use RAG\nin your conversations.',
                  textAlign: TextAlign.center,
                ),
              )
            : ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  return ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: Text(doc.name),
                    subtitle: Text(
                        '${doc.chunkCount} chunks · ${doc.format.toUpperCase()}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => notifier.deleteDocument(doc.id),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
