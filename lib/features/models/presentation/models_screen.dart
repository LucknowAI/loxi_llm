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
    final loadingModel = loadingModelOf(modelsAsync.valueOrNull ?? const []);

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
            // Settings is a separate Scaffold slot, not covered by the
            // body-level loading overlay below, so it's disabled explicitly
            // while a load is in flight. This doesn't fully lock the screen
            // — the bottom nav bar (outside this widget) can still switch to
            // the Chat/Documents tab — just this one push-navigation path.
            onPressed:
                loadingModel == null ? () => context.push('/settings') : null,
          ),
        ],
      ),
      floatingActionButton: loadingModel != null
          ? null
          : FloatingActionButton.extended(
              icon: const Icon(Icons.file_open),
              label: const Text('Sideload'),
              onPressed: () async {
                try {
                  await ref.read(modelsNotifierProvider.notifier).sideloadModel();
                } on FormatException catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.message), backgroundColor: Colors.red),
                    );
                  }
                }
              },
            ),
      body: Stack(
        children: [
          modelsAsync.when(
            data: (models) => ListView.builder(
              itemCount: models.length,
              itemBuilder: (context, index) =>
                  _ModelListTile(model: models[index]),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error loading models: $e')),
          ),
          // On top of the list in the Stack, so it absorbs every tap on the
          // rows beneath it — no need to separately disable each row's own
          // button.
          if (loadingModel != null)
            Positioned.fill(child: _LoadingOverlay(modelName: loadingModel.name)),
        ],
      ),
    );
  }
}

/// Full-screen scrim shown while a model is loading: pulsing rings around a
/// chip icon, the loading model's name, and a reassuring hint. Blocks
/// interaction with whatever's beneath it in the Stack by simply being an
/// opaque-enough widget on top — no manual per-row disabling needed.
class _LoadingOverlay extends StatefulWidget {
  const _LoadingOverlay({required this.modelName});

  final String modelName;

  @override
  State<_LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<_LoadingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // BlockSemantics drops the semantics of everything painted before it in
    // this same semantics scope — i.e. the model list underneath. Without
    // it, the scrim blocks touches but a screen reader could still navigate
    // to and activate a "hidden" row's button. liveRegion announces the
    // loading text automatically as it appears, rather than requiring the
    // user to have already focused this part of the screen.
    return BlockSemantics(
      child: Semantics(
        liveRegion: true,
        child: Container(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) => CustomPaint(
                      painter: _PulsingRingsPainter(
                        progress: _controller.value,
                        color: colorScheme.primary,
                      ),
                      child: Center(
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.auto_awesome,
                            size: 16,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Loading ${widget.modelName}…',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'This can take a little longer for vision models',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints 3 rings expanding outward and fading, offset in phase by a third
/// of a cycle each — a single [progress] value (0..1, repeating) drives all
/// three rather than needing three separate AnimationControllers.
class _PulsingRingsPainter extends CustomPainter {
  _PulsingRingsPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxRadius = size.shortestSide / 2;
    for (var i = 0; i < 3; i++) {
      final t = (progress + i / 3) % 1.0;
      // Stays within maxRadius at t=1 — the mockup's CSS version could
      // bleed past its box since nothing sat close beneath it, but here the
      // model name/hint text sits right below with limited clearance.
      final radius = maxRadius * (0.3 + 0.7 * t);
      final opacity = (1.0 - t) * 0.7;
      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PulsingRingsPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
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
          onPressed: () => _confirmAndLoad(context, ref),
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
      // `error` covers two distinct failures: a download that never finished
      // (no localPath yet — retry re-downloads) and a load that failed on an
      // already-complete file (localPath set — retry re-downloading would
      // re-request a file that's already whole, e.g. hitting the server with
      // a range request past EOF; what the user actually wants is to retry
      // the load, which is cheap and doesn't touch the network).
      ModelStatus.error => model.localPath != null
          ? IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Retry load',
              onPressed: () => _confirmAndLoad(context, ref),
            )
          : IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Retry download',
              onPressed: () => ref
                  .read(modelsNotifierProvider.notifier)
                  .downloadModel(model.id),
            ),
      _ => const SizedBox.shrink(),
    };
  }

  Future<void> _confirmAndLoad(BuildContext context, WidgetRef ref) async {
    final confirmed = await RamCheckService.confirmLoad(context, model: model);
    if (!confirmed || !context.mounted) return;
    try {
      await ref.read(modelsNotifierProvider.notifier).loadModel(model.id);
    } on ModelAlreadyLoadingException catch (e) {
      // A genuine backend load failure is deliberately NOT caught here — it
      // already surfaces via inferenceNotifierProvider's AsyncError state
      // (see ModelsScreen's ref.listen); catching it again here would show
      // two SnackBars for the same failure.
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
