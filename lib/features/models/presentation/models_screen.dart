import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/inference_provider.dart';
import '../../../core/services/ram_check_service.dart';
import '../domain/model.dart';
import '../domain/model_status.dart';
import 'models_notifier.dart';

class ModelsScreen extends ConsumerWidget {
  const ModelsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modelsAsync = ref.watch(modelsNotifierProvider);

    ref.listen(inferenceNotifierProvider, (previous, next) {
      final wasLoading = previous?.isLoading ?? false;
      next.whenOrNull(
        data: (backend) {
          if (wasLoading && backend != null) {
            final name = ref
                    .read(inferenceNotifierProvider.notifier)
                    .loadedModel
                    ?.name ??
                'Model';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$name loaded — ready to chat'),
                action: SnackBarAction(
                  label: 'Open Chat',
                  onPressed: () => context.go('/chat'),
                ),
              ),
            );
          }
        },
        error: (e, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load model: $e'),
            backgroundColor: Colors.red,
          ),
        ),
      );
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Models'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.file_open),
        label: const Text('Sideload'),
        onPressed: () => ref.read(modelsNotifierProvider.notifier).sideloadModel(),
      ),
      body: modelsAsync.when(
        data: (models) => ListView.builder(
          itemCount: models.length,
          itemBuilder: (context, index) =>
              _ModelListTile(model: models[index]),
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
    // Live download speed (bytes/sec) for this model, if downloading. The
    // parent watches modelsNotifierProvider, so this rebuilds as it updates.
    final speed = model.status == ModelStatus.downloading
        ? ref.read(modelsNotifierProvider.notifier).downloadSpeed[model.id]
        : null;
    final isActive = model.status == ModelStatus.loaded;
    return Column(
      children: [
        ListTile(
          tileColor: isActive
              ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35)
              : null,
          leading: isActive
              ? Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                )
              : null,
          title: Text(model.name),
          subtitle: _subtitle(context, speed),
          trailing: _trailingWidget(context, ref),
        ),
        if (model.status == ModelStatus.downloading)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LinearProgressIndicator(value: model.downloadProgress),
          ),
      ],
    );
  }

  /// Format a download speed in bytes/second as e.g. "3.4 MB/s" or "812 KB/s".
  static String _formatSpeed(double bytesPerSecond) {
    if (bytesPerSecond >= 1024 * 1024) {
      return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    }
    if (bytesPerSecond >= 1024) {
      return '${(bytesPerSecond / 1024).toStringAsFixed(0)} KB/s';
    }
    return '${bytesPerSecond.toStringAsFixed(0)} B/s';
  }

  Widget _subtitle(BuildContext context, double? speed) {
    final badge = model.recommendationBadge;
    final speedSuffix = (speed != null && speed > 0)
        ? ' · ${_formatSpeed(speed)}'
        : '';
    final statusLabel = switch (model.status) {
      ModelStatus.downloading =>
        '${model.sizeLabel} — ${(model.downloadProgress * 100).toStringAsFixed(0)}%$speedSuffix',
      ModelStatus.loading => '${model.sizeLabel} — loading into memory…',
      ModelStatus.loaded => '${model.sizeLabel} — active, ready to chat',
      _ => '${model.sizeLabel} — ${model.status.name}',
    };
    final chips = <Widget>[
      if (model.status == ModelStatus.loaded)
        Chip(
          label: const Text('Active'),
          padding: EdgeInsets.zero,
          labelStyle: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          visualDensity: VisualDensity.compact,
        ),
      if (badge != null)
        Chip(
          label: Text(badge),
          padding: EdgeInsets.zero,
          labelStyle: const TextStyle(fontSize: 11),
          visualDensity: VisualDensity.compact,
        ),
    ];
    if (chips.isEmpty) return Text(statusLabel);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(statusLabel),
        const SizedBox(height: 4),
        Wrap(spacing: 6, runSpacing: 4, children: chips),
      ],
    );
  }

  Widget _trailingWidget(BuildContext context, WidgetRef ref) {
    return switch (model.status) {
      ModelStatus.available => IconButton(
          icon: const Icon(Icons.cloud_download_outlined),
          tooltip: 'Download',
          onPressed: () => ref
              .read(modelsNotifierProvider.notifier)
              .downloadModel(model.id),
        ),
      ModelStatus.downloading => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Cancel',
              onPressed: () => ref
                  .read(modelsNotifierProvider.notifier)
                  .cancelDownload(model.id),
            ),
          ],
        ),
      ModelStatus.downloaded => IconButton(
          icon: const Icon(Icons.play_arrow, color: Colors.green),
          tooltip: 'Load model',
          onPressed: () async {
            final confirmed = await RamCheckService.confirmLoad(
              context,
              modelSizeBytes: model.sizeBytes,
            );
            if (confirmed && context.mounted) {
              ref.read(modelsNotifierProvider.notifier).loadModel(model.id);
            }
          },
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
      ModelStatus.error => IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Retry download',
          onPressed: () => ref
              .read(modelsNotifierProvider.notifier)
              .downloadModel(model.id),
        ),
      _ => const SizedBox.shrink(),
    };
  }
}
