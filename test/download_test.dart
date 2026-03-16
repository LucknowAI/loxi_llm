import 'package:flutter_test/flutter_test.dart';
import 'package:loki_llm/features/models/data/model_catalog.dart';
import 'package:loki_llm/features/models/domain/model.dart';
import 'package:loki_llm/features/models/domain/model_status.dart';

void main() {
  group('kCuratedModels catalog', () {
    test('contains exactly 3 models', () {
      expect(kCuratedModels.length, equals(3));
    });

    test('all models have unique IDs', () {
      final ids = kCuratedModels.map((m) => m.id).toSet();
      expect(ids.length, equals(kCuratedModels.length));
    });

    test('all models start with available status', () {
      for (final model in kCuratedModels) {
        expect(model.status, equals(ModelStatus.available));
      }
    });

    test('all models have huggingFaceRepo and filename', () {
      for (final model in kCuratedModels) {
        expect(model.huggingFaceRepo, isNotNull);
        expect(model.filename, isNotNull);
      }
    });

    test('Gemma model has task format', () {
      final gemma = kCuratedModels.first;
      expect(gemma.format, equals('task'));
    });

    test('GGUF models have gguf format', () {
      for (final model in kCuratedModels.skip(1)) {
        expect(model.format, equals('gguf'));
      }
    });
  });

  group('huggingFaceDownloadUrl', () {
    test('constructs correct HF URL', () {
      const model = Model(
        id: 'test',
        name: 'Test',
        sizeLabel: '1GB',
        sizeBytes: 1000000000,
        huggingFaceRepo: 'owner/repo',
        filename: 'model.gguf',
      );
      final url = huggingFaceDownloadUrl(model);
      expect(url, equals('https://huggingface.co/owner/repo/resolve/main/model.gguf'));
    });

    test('Phi-3 URL contains correct repo and file', () {
      final phi3 = kCuratedModels.firstWhere((m) => m.id == 'phi3-mini-4k-q4km');
      final url = huggingFaceDownloadUrl(phi3);
      expect(url, contains('bartowski/Phi-3-mini-4k-instruct-GGUF'));
      expect(url, contains('Q4_K_M.gguf'));
    });
  });

  group('Model download state transitions', () {
    test('Model copyWith sets downloading status', () {
      const model = Model(
        id: 'test-dl',
        name: 'Test',
        sizeLabel: '1GB',
        sizeBytes: 1000000000,
      );
      final downloading = model.copyWith(
        status: ModelStatus.downloading,
        downloadProgress: 0.0,
      );
      expect(downloading.isDownloading, isTrue);
      expect(downloading.canLoad, isFalse);
    });

    test('Model copyWith sets downloaded status with localPath', () {
      const model = Model(
        id: 'test-dl',
        name: 'Test',
        sizeLabel: '1GB',
        sizeBytes: 1000000000,
        status: ModelStatus.downloading,
      );
      final downloaded = model.copyWith(
        status: ModelStatus.downloaded,
        localPath: '/data/models/model.gguf',
        downloadProgress: 1.0,
      );
      expect(downloaded.isDownloaded, isTrue);
      expect(downloaded.canLoad, isTrue);
    });

    test('Model without localPath cannot be loaded even if downloaded', () {
      const model = Model(
        id: 'test-no-path',
        name: 'Test',
        sizeLabel: '1GB',
        sizeBytes: 1000000000,
        status: ModelStatus.downloaded,
      );
      expect(model.canLoad, isFalse);
    });
  });
}
