import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/inference_provider.dart';
import '../domain/generation_settings.dart';
import 'settings_notifier.dart';

class GenerationSettingsScreen extends ConsumerWidget {
  const GenerationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(settingsNotifierProvider);
    final inference = ref.watch(inferenceNotifierProvider);
    final backend = inference.valueOrNull;
    final model = ref.read(inferenceNotifierProvider.notifier).loadedModel;
    final notifier = ref.read(settingsNotifierProvider.notifier);
    final settings = model == null ? null : notifier.generationFor(model.id);
    final loadedThreads = backend?.generationParams['nThreads'];
    final loadedContext = backend?.generationParams['contextSize'];
    final loadedBatch = backend?.generationParams['batchSize'];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(model?.name ?? 'Generation'),
      ),
      body: model == null || settings == null
          ? const Center(
              child: Text('Load a model to change generation settings.'),
            )
          : _Sliders(
              modelId: model.id,
              loadedContext: loadedContext is int ? loadedContext : 2048,
              settings: settings,
              onChanged: (next) {
                final before = loadedThreads is int &&
                    loadedContext is int &&
                    loadedBatch is int &&
                    settings.differsFromLoaded(
                      nThreads: loadedThreads,
                      contextSize: loadedContext,
                      batchSize: loadedBatch,
                    );
                notifier.saveGeneration(model.id, next);
                final after = loadedThreads is int &&
                    loadedContext is int &&
                    loadedBatch is int &&
                    next.clamped().differsFromLoaded(
                          nThreads: loadedThreads,
                          contextSize: loadedContext,
                          batchSize: loadedBatch,
                        );
                if (!before && after && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Reload the model to use the new threads, context, or batch size.',
                      ),
                    ),
                  );
                }
              },
            ),
    );
  }
}

class _Sliders extends StatelessWidget {
  const _Sliders({
    required this.modelId,
    required this.loadedContext,
    required this.settings,
    required this.onChanged,
  });

  final String modelId;
  final int loadedContext;
  final GenerationSettings settings;
  final ValueChanged<GenerationSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    final replyLength = settings.maxTokensForLoadedContext(loadedContext);
    final maxTokensLimit = loadedContext - GenerationSettings.promptRoom;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Next message', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Used on the next reply, including a tool-using turn.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        _slider(
          context,
          label: 'Temperature',
          value: settings.temperature,
          min: 0,
          max: 2,
          divisions: 40,
          caption: settings.temperature.toStringAsFixed(2),
          onChanged: (v) => onChanged(settings.copyWith(temperature: v)),
        ),
        _slider(
          context,
          label: 'Reply length',
          value: replyLength.toDouble(),
          min: 64,
          max: maxTokensLimit.toDouble(),
          divisions: (maxTokensLimit - 64) ~/ 64,
          caption: '$replyLength',
          onChanged: (v) => onChanged(settings.copyWith(maxTokens: v.round())),
        ),
        Text(
          'Room left for the conversation: ${loadedContext - replyLength} tokens.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        _slider(
          context,
          label: 'Top-k',
          value: settings.topK.toDouble(),
          min: 1,
          max: 100,
          divisions: 99,
          caption: '${settings.topK}',
          onChanged: (v) => onChanged(settings.copyWith(topK: v.round())),
        ),
        _slider(
          context,
          label: 'Top-p',
          value: settings.topP,
          min: 0.05,
          max: 1,
          divisions: 19,
          caption: settings.topP.toStringAsFixed(2),
          onChanged: (v) => onChanged(settings.copyWith(topP: v)),
        ),
        _slider(
          context,
          label: 'Repeat penalty',
          value: settings.repeatPenalty,
          min: 1,
          max: 1.5,
          divisions: 10,
          caption: settings.repeatPenalty.toStringAsFixed(2),
          onChanged: (v) => onChanged(settings.copyWith(repeatPenalty: v)),
        ),
        const Divider(height: 32),
        Text(
          'When the model is loaded',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Takes effect the next time this model is loaded.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        _slider(
          context,
          label: 'Threads',
          value: settings.nThreads.toDouble(),
          min: 1,
          max: 8,
          divisions: 7,
          caption: '${settings.nThreads}',
          onChanged: (v) => onChanged(settings.copyWith(nThreads: v.round())),
        ),
        _choice(
          context,
          label: 'Context size',
          choices: GenerationSettings.contextChoices,
          value: settings.contextSize,
          onChanged: (v) => onChanged(settings.copyWith(contextSize: v)),
        ),
        _choice(
          context,
          label: 'Batch size',
          choices: GenerationSettings.batchChoices,
          value: settings.batchSize,
          onChanged: (v) => onChanged(settings.copyWith(batchSize: v)),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => onChanged(GenerationSettings.defaultsFor(modelId)),
            child: const Text('Reset to this model\'s defaults'),
          ),
        ),
      ],
    );
  }

  Widget _slider(
    BuildContext context, {
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String caption,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text('$label: $caption',
            style: Theme.of(context).textTheme.titleMedium),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          label: caption,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _choice(
    BuildContext context, {
    required String label,
    required List<int> choices,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    final index = choices.indexOf(value).clamp(0, choices.length - 1);
    return _slider(
      context,
      label: label,
      value: index.toDouble(),
      min: 0,
      max: (choices.length - 1).toDouble(),
      divisions: choices.length - 1,
      caption: '${choices[index]}',
      onChanged: (v) => onChanged(choices[v.round()]),
    );
  }
}
