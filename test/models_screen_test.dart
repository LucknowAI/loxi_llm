import 'package:flutter_test/flutter_test.dart';
import 'package:loki_llm/features/models/domain/model.dart';
import 'package:loki_llm/features/models/domain/model_status.dart';
import 'package:loki_llm/features/models/presentation/models_screen.dart';

Model _model(String id, ModelStatus status) => Model(
      id: id,
      name: id,
      sizeLabel: '1 GB',
      sizeBytes: 1000000000,
      status: status,
    );

void main() {
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
}
