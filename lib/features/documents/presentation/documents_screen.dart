import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Documents'),
      ),
      body: const Center(
        child: Text(
          'Add documents to use RAG\nin your conversations.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
