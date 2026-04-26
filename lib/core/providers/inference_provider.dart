import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/models/data/model_repository.dart';
import '../../features/models/domain/model.dart';
import '../../features/models/domain/model_status.dart';
import '../engine/backend_selector.dart';
import '../engine/inference_backend.dart';

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
  @override
  Future<InferenceBackend?> build() async => null;

  /// Load [model] into the appropriate backend.
  ///
  /// Throws [StateError] if `model.canLoad` is false (no localPath or wrong status).
  Future<void> loadModel(Model model) async {
    if (!model.canLoad) {
      throw StateError('Model ${model.id} cannot be loaded (canLoad=false)');
    }

    state = const AsyncLoading();

    final backend = backendForModel(model);
    try {
      await backend.loadModel(model.localPath!);
      state = AsyncData(backend);
      // Persist loaded status
      ref.read(modelRepositoryProvider).save(
            model.copyWith(status: ModelStatus.loaded),
          );
    } catch (e, st) {
      state = AsyncError(e, st);
      ref.read(modelRepositoryProvider).save(
            model.copyWith(status: ModelStatus.error),
          );
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
    ref.read(modelRepositoryProvider).save(
          model.copyWith(status: ModelStatus.downloaded),
        );
  }
}
