import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/inference_provider.dart';

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backendAsync = ref.watch(inferenceNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Chat'),
      ),
      body: backendAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Engine error: $e',
            textAlign: TextAlign.center,
          ),
        ),
        data: (backend) => backend == null
            ? const Center(
                child: Text(
                  'Load a model from the Models tab\nto start chatting.',
                  textAlign: TextAlign.center,
                ),
              )
            : const Center(
                child: Text(
                  'Model loaded — chat coming in Phase 4!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.green),
                ),
              ),
      ),
    );
  }
}
