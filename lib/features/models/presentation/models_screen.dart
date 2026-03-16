import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/model.dart';
import '../domain/model_status.dart';
import 'models_notifier.dart';

class ModelsScreen extends ConsumerWidget {
  const ModelsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modelsAsync = ref.watch(modelsNotifierProvider);

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

class _ModelListTile extends StatelessWidget {
  const _ModelListTile({required this.model});

  final Model model;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(model.name),
      subtitle: Text('${model.sizeLabel} — ${model.status.name}'),
      trailing: _statusBadge(model.status),
    );
  }

  Widget _statusBadge(ModelStatus status) {
    return switch (status) {
      ModelStatus.downloaded => const Icon(Icons.check_circle, color: Colors.green),
      ModelStatus.downloading => const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ModelStatus.loaded => const Icon(Icons.memory, color: Colors.blue),
      ModelStatus.error => const Icon(Icons.error, color: Colors.red),
      _ => const Icon(Icons.cloud_download_outlined),
    };
  }
}
