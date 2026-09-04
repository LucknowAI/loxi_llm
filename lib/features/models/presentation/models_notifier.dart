import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/providers/download_provider.dart';
import '../../../core/providers/inference_provider.dart';
import '../data/model_catalog.dart';
import '../data/model_repository.dart';
import '../domain/model.dart';
import '../domain/model_status.dart';

part 'models_notifier.g.dart';

/// `gguf` has no registered Android MIME type, so `FileType.custom` +
/// `allowedExtensions` fails there before the picker even opens. We use
/// `FileType.any` and validate the extension ourselves.
///
/// `.task` (MediaPipe bundle) is rejected: `backendForModel` only returns
/// `LlamaCppBackend`, which can't load it, since `MediaPipeBackend` was
/// removed. Re-add `.task` once MediaPipe support returns.
bool isSupportedSideloadExtension(String filename) {
  final ext = filename.split('.').last.toLowerCase();
  return ext == 'gguf';
}

/// Catalog entries not yet present (by id) among [existing] rows.
///
/// Pure and side-effect free so seed-merge logic is unit-testable without
/// ObjectBox. Rows a user has already touched are never returned here, so
/// callers can safely upsert the result without clobbering user state.
List<Model> modelsMissingFromCatalog({
  required List<Model> existing,
  required List<Model> catalog,
}) {
  final existingIds = existing.map((m) => m.id).toSet();
  return catalog.where((m) => !existingIds.contains(m.id)).toList();
}

/// The model currently loading, if any. Only one native backend can load at
/// a time, so at most one entry in [models] ever has this status — but the
/// list scan (rather than trusting a separately-tracked id) keeps this in
/// sync with persisted state automatically. Shared by the Models screen's
/// loading overlay and [ModelsNotifier.loadModel]'s concurrent-load guard,
/// so both agree on exactly the same definition of "something is loading".
Model? loadingModelOf(List<Model> models) {
  for (final m in models) {
    if (m.status == ModelStatus.loading) return m;
  }
  return null;
}

/// Thrown by [ModelsNotifier.loadModel] when another model is already
/// loading. A distinct type (rather than a generic [StateError]) so callers
/// can catch and show feedback for exactly this case without also catching
/// — and double-showing feedback for — a genuine backend load failure,
/// which propagates as a different exception and is already surfaced via
/// `inferenceNotifierProvider`'s `AsyncError` state.
class ModelAlreadyLoadingException implements Exception {
  const ModelAlreadyLoadingException();

  @override
  String toString() => 'Another model is already loading';
}

/// Whether [ModelsNotifier.build]'s stale-state reconciliation has already
/// run this app session.
///
/// Module-level, not an instance field on the notifier: `ref.invalidateSelf()`
/// re-runs `build()` (e.g. every `loadModel()`/`downloadModel()` call), and
/// each invalidation gets a fresh notifier instance, so an instance field
/// would reset on every single call — which is exactly what caused the bug
/// this guards against. Without it, `build()`'s reconciliation (meant only to
/// recover from a killed-app session where no backend survived) would also
/// fire on every live invalidation, immediately flipping a model's status
/// from `loading` back to `downloaded` the instant `loadModel()` sets it,
/// before the UI ever had a chance to observe the loading state.
bool _hasReconciledStaleModelState = false;

/// Resets [_hasReconciledStaleModelState] so a test can exercise
/// [ModelsNotifier.build]'s cold-start reconciliation more than once in the
/// same process — real app runs never need this, since the flag is only
/// ever meant to reset via an actual process restart.
@visibleForTesting
void resetStaleModelReconciliationForTest() {
  _hasReconciledStaleModelState = false;
}

/// Whether [ModelsNotifier.build] should run its stale-state reconciliation
/// this call. True (and flips the module-level flag) the first time it's
/// called after app start or [resetStaleModelReconciliationForTest]; false
/// every time after. Pure aside from that one flag flip — no repo/IO — so
/// the "runs exactly once" behavior is directly unit-testable without
/// needing a real ObjectBox store.
bool shouldReconcileStaleModels() {
  if (_hasReconciledStaleModelState) return false;
  _hasReconciledStaleModelState = true;
  return true;
}

/// Which of [models] have a `loaded`/`loading` status that can't be trusted
/// after an app restart (no backend survives one) and should be reset to
/// `downloaded`. Pure — returns the subset needing the fix, already
/// `copyWith(status: downloaded)`; the caller persists them.
List<Model> staleModelsToReconcile(List<Model> models) {
  return [
    for (final m in models)
      if ((m.status == ModelStatus.loaded || m.status == ModelStatus.loading) &&
          m.localPath != null)
        m.copyWith(status: ModelStatus.downloaded),
  ];
}

@riverpod
class ModelsNotifier extends _$ModelsNotifier {
  /// Transient live download speed in bytes/second, keyed by model id. Not
  /// persisted — only valid while a download is active.
  final Map<String, double> downloadSpeed = {};

  @override
  Future<List<Model>> build() async {
    final repo = ref.watch(modelRepositoryProvider);
    var models = repo.getAll();
    final missing = modelsMissingFromCatalog(existing: models, catalog: kCuratedModels);
    if (missing.isNotEmpty) {
      // Seed any catalog entries the DB doesn't have yet — covers both a
      // fresh install (all entries missing) and an existing install after a
      // new model was added to the catalog (only the new ones missing).
      for (final model in missing) {
        repo.save(model);
      }
      models = repo.getAll();
    }
    // Reconcile stale in-memory state: no backend survives an app restart,
    // so any row persisted as loaded/loading must drop back to downloaded.
    // Runs exactly once per app session (see shouldReconcileStaleModels) —
    // this is a cold-start recovery step, not something to redo on every
    // live rebuild (every loadModel()/downloadModel() call invalidates this
    // provider, which re-runs build()).
    if (!shouldReconcileStaleModels()) return models;
    final stale = staleModelsToReconcile(models);
    if (stale.isEmpty) return models;

    final staleIds = stale.map((m) => m.id).toSet();
    for (final m in stale) {
      repo.save(m);
    }
    return [
      for (final m in models)
        if (staleIds.contains(m.id))
          stale.firstWhere((s) => s.id == m.id)
        else
          m,
    ];
  }

  /// Download a model from HuggingFace.
  Future<void> downloadModel(String modelId) async {
    final repo = ref.read(modelRepositoryProvider);
    final model = repo.getById(modelId);
    if (model == null) throw StateError('Model $modelId not found');
    if (model.filename == null || model.huggingFaceRepo == null) {
      throw StateError('Model $modelId has no download URL metadata');
    }

    // Transition to downloading
    repo.save(model.copyWith(status: ModelStatus.downloading, downloadProgress: 0.0));
    ref.invalidateSelf();

    final service = ref.read(downloadServiceProvider);
    final url = huggingFaceDownloadUrl(model);
    final mmprojUrl = huggingFaceMmprojDownloadUrl(model);

    try {
      final result = await service.downloadModel(
        model: model,
        downloadUrl: url,
        mmprojDownloadUrl: mmprojUrl,
        onProgress: (progress, bytesPerSecond) {
          final current = repo.getById(modelId);
          if (current != null) {
            downloadSpeed[modelId] = bytesPerSecond;
            repo.save(current.copyWith(downloadProgress: progress));
            ref.invalidateSelf();
          }
        },
      );
      // Mark as downloaded with local path(s)
      final downloaded = repo.getById(modelId);
      if (downloaded != null) {
        repo.save(downloaded.copyWith(
          status: ModelStatus.downloaded,
          localPath: result.modelPath,
          mmprojLocalPath: result.mmprojPath,
          downloadProgress: 1.0,
        ));
      }
    } catch (e, st) {
      AppLogger.instance.error(
          'ModelsNotifier', 'Failed to download model $modelId', e, st);
      final current = repo.getById(modelId);
      if (current != null) {
        repo.save(current.copyWith(status: ModelStatus.error));
      }
    } finally {
      downloadSpeed.remove(modelId);
      ref.invalidateSelf();
    }
  }

  /// Cancel an active download and reset status to available.
  void cancelDownload(String modelId) {
    final service = ref.read(downloadServiceProvider);
    service.cancelDownload(modelId);
    downloadSpeed.remove(modelId);
    final repo = ref.read(modelRepositoryProvider);
    final model = repo.getById(modelId);
    if (model != null) {
      repo.save(model.copyWith(
        status: ModelStatus.available,
        downloadProgress: 0.0,
      ));
    }
    ref.invalidateSelf();
  }

  /// Sideload a model from device storage via file picker.
  Future<void> sideloadModel() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final path = file.path;
    if (path == null) return;

    final filename = file.name;
    if (!isSupportedSideloadExtension(filename)) {
      throw const FormatException('Unsupported file type. Choose a .gguf file.');
    }
    final sizeBytes = file.size > 0 ? file.size : (File(path).existsSync() ? File(path).lengthSync() : 0);

    final repo = ref.read(modelRepositoryProvider);
    final model = Model(
      id: 'sideload-${DateTime.now().millisecondsSinceEpoch}',
      name: filename,
      sizeLabel: _formatBytes(sizeBytes),
      sizeBytes: sizeBytes,
      status: ModelStatus.downloaded,
      localPath: path,
      filename: filename,
      downloadProgress: 1.0,
    );
    repo.save(model);
    ref.invalidateSelf();
  }

  /// Load a downloaded model into the inference engine (with RAM check in UI layer).
  ///
  /// Throws [ModelAlreadyLoadingException] if another model is already
  /// loading. The Models screen's full-screen overlay already blocks this
  /// via the UI, but that alone isn't a real guarantee — a fast double-tap
  /// before the overlay renders, or an accessibility tool invoking the
  /// action directly, could still reach here. Guarding here, before
  /// anything is persisted, is what actually prevents two concurrent loads
  /// racing the single native backend (InferenceNotifier/LlamaEngine.instance).
  ///
  /// A genuine backend load failure instead propagates as whatever
  /// [InferenceNotifier.loadModel] threw — callers shouldn't show feedback
  /// for that themselves, since it's already surfaced via
  /// `inferenceNotifierProvider`'s `AsyncError` state (see the Models
  /// screen's `ref.listen`); showing it again here would double up.
  Future<void> loadModel(String modelId) async {
    final repo = ref.read(modelRepositoryProvider);
    final model = repo.getById(modelId);
    if (model == null) throw StateError('Model $modelId not found');
    if (loadingModelOf(repo.getAll()) != null) {
      throw const ModelAlreadyLoadingException();
    }

    repo.save(model.copyWith(status: ModelStatus.loading));
    ref.invalidateSelf();

    try {
      await ref.read(inferenceNotifierProvider.notifier).loadModel(model);
    } finally {
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

  String _formatBytes(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
