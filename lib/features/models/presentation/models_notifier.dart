import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/inference_provider.dart';
import '../data/model_repository.dart';
import '../domain/model.dart';
import '../domain/model_status.dart';

part 'models_notifier.g.dart';

@riverpod
class ModelsNotifier extends _$ModelsNotifier {
  @override
  Future<List<Model>> build() async {
    return ref.watch(modelRepositoryProvider).getAll();
  }

  /// Load a downloaded model into the inference engine.
  ///
  /// Updates status to [ModelStatus.loading] immediately for responsive UI,
  /// then delegates to [InferenceNotifier.loadModel] which handles the
  /// backend initialization and final status persistence.
  Future<void> loadModel(String modelId) async {
    final repo = ref.read(modelRepositoryProvider);
    final model = repo.getById(modelId);
    if (model == null) throw StateError('Model $modelId not found');

    // Persist loading status so tile shows spinner immediately
    repo.save(model.copyWith(status: ModelStatus.loading));
    ref.invalidateSelf();

    try {
      await ref.read(inferenceNotifierProvider.notifier).loadModel(model);
    } finally {
      // Refresh list to pick up the persisted status (loaded or error)
      ref.invalidateSelf();
    }
  }

  /// Unload the currently loaded model.
  Future<void> unloadModel(String modelId) async {
    final repo = ref.read(modelRepositoryProvider);
    final model = repo.getById(modelId);
    if (model == null) return;

    await ref.read(inferenceNotifierProvider.notifier).unloadModel(model);
    ref.invalidateSelf();
  }
}
