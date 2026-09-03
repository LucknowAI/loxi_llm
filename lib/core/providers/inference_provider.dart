import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/models/data/model_repository.dart';
import '../../features/models/domain/model.dart';
import '../../features/models/domain/model_status.dart';
import '../engine/backend_selector.dart';
import '../engine/inference_backend.dart';
import '../logging/app_logger.dart';

part 'inference_provider.g.dart';

/// Manages the lifecycle of the currently loaded [InferenceBackend].
///
/// State: `AsyncData(null)` = no model loaded
///        `AsyncData(backend)` = model loaded and ready
///        `AsyncLoading()` = model is initializing
///        `AsyncError(...)` = initialization failed
///
/// keepAlive: true — the loaded backend must survive tab navigation.
@Riverpod(keepAlive: true)
class InferenceNotifier extends _$InferenceNotifier {
  /// The model currently loaded into [state]'s backend, or null when none is
  /// loaded. This is the authoritative source for "what model is running" —
  /// the persisted [ModelStatus.loaded] flag is reset on startup reconciliation
  /// and cannot be relied on (see ModelsNotifier). Set atomically with [state].
  Model? loadedModel;

  @override
  Future<InferenceBackend?> build() async => null;

  /// Load [model] into the appropriate backend.
  ///
  /// Throws [StateError] if `model.canLoad` is false (no localPath or wrong status).
  Future<void> loadModel(Model model) async {
    if (!model.canLoad) {
      throw StateError('Model ${model.id} cannot be loaded (canLoad=false)');
    }

    final previousModel = loadedModel;
    final previousBackend = state.valueOrNull;

    state = const AsyncLoading();

    final backend = backendForModel(model);
    try {
      if (previousBackend != null) {
        await previousBackend.unloadModel();
      }
      await backend.loadModel(model.localPath!, mmprojPath: model.mmprojLocalPath);
      // Assign before [state] so listeners (e.g. load SnackBar) see the new model.
      loadedModel = model;
      state = AsyncData(backend);
      final repo = ref.read(modelRepositoryProvider);
      repo.save(model.copyWith(status: ModelStatus.loaded));
      if (previousModel != null && previousModel.id != model.id) {
        repo.save(previousModel.copyWith(status: ModelStatus.downloaded));
      }
    } catch (e, st) {
      loadedModel = null;
      state = AsyncError(e, st);
      AppLogger.instance.error(
          'InferenceNotifier', 'Failed to load model ${model.id}', e, st);
      final repo = ref.read(modelRepositoryProvider);
      repo.save(model.copyWith(status: ModelStatus.error));
      if (previousModel != null && previousModel.id != model.id) {
        repo.save(previousModel.copyWith(status: ModelStatus.downloaded));
      }
      rethrow;
    }
  }

  /// Unload the current backend and reset [model] status to downloaded.
  ///
  /// Always resets the persisted status, even when no backend is alive
  /// in memory — this recovers from desync after an app restart where the
  /// row still says `loaded` but [build] returned null.
  Future<void> unloadModel(Model model) async {
    final current = state.valueOrNull;
    if (current != null) {
      await current.unloadModel();
    }
    state = const AsyncData(null);
    loadedModel = null;
    ref.read(modelRepositoryProvider).save(
          model.copyWith(status: ModelStatus.downloaded),
        );
  }
}
