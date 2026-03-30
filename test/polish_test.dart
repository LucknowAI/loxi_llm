import 'package:flutter_test/flutter_test.dart';
import 'package:loki_llm/features/settings/domain/app_settings.dart';
import 'package:loki_llm/features/models/domain/model.dart';
import 'package:loki_llm/features/models/domain/model_status.dart';

void main() {
  group('AppSettings', () {
    test('default chunkSize is 300', () {
      expect(const AppSettings().chunkSize, equals(300));
    });

    test('default topK is 3', () {
      expect(const AppSettings().topK, equals(3));
    });

    test('copyWith updates chunkSize', () {
      const s = AppSettings();
      final updated = s.copyWith(chunkSize: 200);
      expect(updated.chunkSize, equals(200));
      expect(updated.topK, equals(3)); // unchanged
    });

    test('copyWith updates topK', () {
      const s = AppSettings();
      final updated = s.copyWith(topK: 5);
      expect(updated.topK, equals(5));
      expect(updated.chunkSize, equals(300)); // unchanged
    });
  });

  group('Model recommendation badges', () {
    Model makeModel(String id) => Model(
          id: id,
          name: id,
          sizeLabel: '1 GB',
          sizeBytes: 1000000000,
          status: ModelStatus.available,
          huggingFaceRepo: 'repo/model',
          filename: 'model.gguf',
        );

    test('gemma3 model has Fastest badge', () {
      expect(makeModel('gemma3-270m-it').recommendationBadge, equals('Fastest'));
    });

    test('phi3 model has Balanced badge', () {
      expect(makeModel('phi3-mini-4k-q4km').recommendationBadge, equals('Balanced'));
    });

    test('llama32 model has Best for RAG badge', () {
      expect(makeModel('llama32-3b-q4km').recommendationBadge, equals('Best for RAG'));
    });

    test('unknown model has null badge', () {
      expect(makeModel('unknown-model-xyz').recommendationBadge, isNull);
    });
  });
}
