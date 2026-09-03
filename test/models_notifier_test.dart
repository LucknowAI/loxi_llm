import 'package:flutter_test/flutter_test.dart';
import 'package:loki_llm/features/models/domain/model.dart';
import 'package:loki_llm/features/models/domain/model_status.dart';
import 'package:loki_llm/features/models/presentation/models_notifier.dart';

Model _model(String id, ModelStatus status, {String? localPath = '/tmp/m.gguf'}) =>
    Model(
      id: id,
      name: id,
      sizeLabel: '1 GB',
      sizeBytes: 1000000000,
      status: status,
      localPath: localPath,
    );

void main() {
  // shouldReconcileStaleModels/staleModelsToReconcile back ModelsNotifier.build's
  // cold-start recovery. A real ObjectBox store isn't available for `flutter
  // test` in this environment (needs a separate native-lib install step this
  // repo hasn't done), so these pure functions carry the regression coverage
  // for the actual bug — build() re-running reconciliation on every
  // ref.invalidateSelf() and stomping a live `loading` status back to
  // `downloaded` before the UI could ever observe it.
  group('shouldReconcileStaleModels', () {
    setUp(resetStaleModelReconciliationForTest);

    test('true on the first call, false on every call after — regression for the '
        'bug where every rebuild re-ran cold-start reconciliation and immediately '
        'flipped a live loading status back to downloaded', () {
      expect(shouldReconcileStaleModels(), isTrue);
      expect(shouldReconcileStaleModels(), isFalse);
      expect(shouldReconcileStaleModels(), isFalse);
    });

    test('true again after resetStaleModelReconciliationForTest (simulates a '
        'fresh app process)', () {
      expect(shouldReconcileStaleModels(), isTrue);
      resetStaleModelReconciliationForTest();
      expect(shouldReconcileStaleModels(), isTrue);
    });
  });

  group('staleModelsToReconcile', () {
    test('resets a loaded model with a localPath to downloaded', () {
      final stale = staleModelsToReconcile([_model('a', ModelStatus.loaded)]);
      expect(stale, hasLength(1));
      expect(stale.single.status, ModelStatus.downloaded);
    });

    test('resets a loading model with a localPath to downloaded', () {
      final stale = staleModelsToReconcile([_model('a', ModelStatus.loading)]);
      expect(stale, hasLength(1));
      expect(stale.single.status, ModelStatus.downloaded);
    });

    test('leaves a loaded/loading model without a localPath alone (nothing to '
        'recover — it was never really running)', () {
      final stale = staleModelsToReconcile([
        _model('a', ModelStatus.loaded, localPath: null),
        _model('b', ModelStatus.loading, localPath: null),
      ]);
      expect(stale, isEmpty);
    });

    test('leaves available/downloading/downloaded/error models alone', () {
      final stale = staleModelsToReconcile([
        _model('a', ModelStatus.available),
        _model('b', ModelStatus.downloading),
        _model('c', ModelStatus.downloaded),
        _model('d', ModelStatus.error),
      ]);
      expect(stale, isEmpty);
    });

    test('empty in, empty out', () {
      expect(staleModelsToReconcile(const []), isEmpty);
    });
  });

  group('loadingModelOf', () {
    test('null when no model is loading', () {
      final models = [
        _model('a', ModelStatus.available),
        _model('b', ModelStatus.downloaded),
        _model('c', ModelStatus.loaded),
      ];
      expect(loadingModelOf(models), isNull);
    });

    test('returns the loading model', () {
      final models = [
        _model('a', ModelStatus.downloaded),
        _model('b', ModelStatus.loading),
        _model('c', ModelStatus.available),
      ];
      expect(loadingModelOf(models)?.id, 'b');
    });

    test('null for an empty list', () {
      expect(loadingModelOf(const []), isNull);
    });
  });

  group('ModelAlreadyLoadingException', () {
    test('toString is the exact text shown in the SnackBar', () {
      expect(
        const ModelAlreadyLoadingException().toString(),
        'Another model is already loading',
      );
    });
  });
}
