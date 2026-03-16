import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/inference_provider.dart';
import '../domain/model.dart';
import '../domain/model_status.dart';
import 'models_notifier.dart';

class ModelsScreen extends ConsumerWidget {
  const ModelsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modelsAsync = ref.watch(modelsNotifierProvider);

    // Show SnackBar on inference errors
    ref.listen(inferenceNotifierProvider, (previous, next) {
      next.whenOrNull(
        error: (e, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Engine error: $e'), backgroundColor: Colors.red),
        ),
      );
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Models'),
      ),
      body: modelsAsync.when(
        data: (models) => models.isEmpty
            ? const Center(
                child: Text(
                  'No models yet.\nDownload a model to get started.',
                  textAlign: TextAlign.center,
                ),
              )
            : ListView.builder(
                itemCount: models.length,
                itemBuilder: (context, index) {
                  final model = models[index];
                  return _ModelListTile(model: model);
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error loading models: $e')),
      ),
    );
  }
}

class _ModelListTile extends ConsumerWidget {
  const _ModelListTile({required this.model});

  final Model model;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: Text(model.name),
      subtitle: Text('${model.sizeLabel} — ${model.status.name}'),
      trailing: _trailingWidget(context, ref),
    );
  }

  Widget _trailingWidget(BuildContext context, WidgetRef ref) {
    return switch (model.status) {
      ModelStatus.downloaded => IconButton(
          icon: const Icon(Icons.play_arrow, color: Colors.green),
          tooltip: 'Load model',
          onPressed: () => ref
              .read(modelsNotifierProvider.notifier)
              .loadModel(model.id),
        ),
      ModelStatus.loading => const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ModelStatus.loaded => IconButton(
          icon: const Icon(Icons.stop, color: Colors.blue),
          tooltip: 'Unload model',
          onPressed: () => ref
              .read(modelsNotifierProvider.notifier)
              .unloadModel(model.id),
        ),
      ModelStatus.downloading => const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ModelStatus.error => const Icon(Icons.error, color: Colors.red),
      _ => const Icon(Icons.cloud_download_outlined),
    };
  }
}
