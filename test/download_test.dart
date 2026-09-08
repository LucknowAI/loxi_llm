import 'package:flutter_test/flutter_test.dart';
import 'package:loki_llm/core/services/download_service.dart';
import 'package:loki_llm/features/models/data/model_catalog.dart';
import 'package:loki_llm/features/models/domain/model.dart';
import 'package:loki_llm/features/models/domain/model_status.dart';
import 'package:loki_llm/features/models/presentation/models_notifier.dart';

void main() {
  group('kCuratedModels catalog', () {
    test('contains exactly 5 models', () {
      expect(kCuratedModels.length, equals(5));
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

    test('all curated models use gguf format', () {
      for (final model in kCuratedModels) {
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

  group('Gemma 4 vision catalog entries', () {
    test('gemma4-e2b-it sets mmproj fields', () {
      final model = kCuratedModels.firstWhere((m) => m.id == 'gemma4-e2b-it');
      expect(model.mmprojFilename, equals('mmproj-F16.gguf'));
      expect(model.mmprojHuggingFaceRepo, equals('unsloth/gemma-4-E2B-it-GGUF'));
      expect(model.mmprojSizeBytes, equals(985654080));
      expect(isMultimodalModel(model), isTrue);
    });

    test('gemma4-e4b-it sets mmproj fields', () {
      final model = kCuratedModels.firstWhere((m) => m.id == 'gemma4-e4b-it');
      expect(model.mmprojFilename, equals('mmproj-F16.gguf'));
      expect(model.mmprojHuggingFaceRepo, equals('unsloth/gemma-4-E4B-it-GGUF'));
      expect(model.mmprojSizeBytes, equals(990372672));
      expect(isMultimodalModel(model), isTrue);
    });

    test('pre-existing text-only models are not multimodal', () {
      final gemma3 = kCuratedModels.firstWhere((m) => m.id == 'gemma3-270m-it');
      expect(isMultimodalModel(gemma3), isFalse);
    });
  });

  group('huggingFaceMmprojDownloadUrl', () {
    test('constructs correct HF URL when mmproj fields are set', () {
      final model = kCuratedModels.firstWhere((m) => m.id == 'gemma4-e2b-it');
      final url = huggingFaceMmprojDownloadUrl(model);
      expect(
        url,
        equals('https://huggingface.co/unsloth/gemma-4-E2B-it-GGUF/resolve/main/mmproj-F16.gguf'),
      );
    });

    test('returns null when the model has no mmproj companion', () {
      final phi3 = kCuratedModels.firstWhere((m) => m.id == 'phi3-mini-4k-q4km');
      expect(huggingFaceMmprojDownloadUrl(phi3), isNull);
    });
  });

  group('combinedDownloadProgress', () {
    test('reduces to baseFraction when there is no mmproj file', () {
      final progress = combinedDownloadProgress(
        baseFraction: 0.5,
        mmprojFraction: 0.0,
        baseSizeBytes: 1000,
        mmprojSizeBytes: 0,
      );
      expect(progress, equals(0.5));
    });

    test('weights each leg by its share of the combined size', () {
      // base is 3x the size of mmproj -> base weight 0.75, mmproj weight 0.25
      final progress = combinedDownloadProgress(
        baseFraction: 1.0,
        mmprojFraction: 0.0,
        baseSizeBytes: 3000,
        mmprojSizeBytes: 1000,
      );
      expect(progress, closeTo(0.75, 1e-9));
    });

    test('reports 1.0 once both legs finish', () {
      final progress = combinedDownloadProgress(
        baseFraction: 1.0,
        mmprojFraction: 1.0,
        baseSizeBytes: 3106738272,
        mmprojSizeBytes: 985654080,
      );
      expect(progress, closeTo(1.0, 1e-9));
    });
  });

  group('modelsMissingFromCatalog', () {
    test('returns every catalog entry when existing is empty', () {
      final missing = modelsMissingFromCatalog(existing: const [], catalog: kCuratedModels);
      expect(missing.map((m) => m.id).toSet(), equals(kCuratedModels.map((m) => m.id).toSet()));
    });

    test('returns only the entries not already present, without touching existing rows', () {
      final downloadedGemma3 = kCuratedModels
          .firstWhere((m) => m.id == 'gemma3-270m-it')
          .copyWith(status: ModelStatus.downloaded, localPath: '/data/models/gemma3.gguf');
      final phi3 = kCuratedModels.firstWhere((m) => m.id == 'phi3-mini-4k-q4km');
      final llama32 = kCuratedModels.firstWhere((m) => m.id == 'llama32-3b-q4km');

      final missing = modelsMissingFromCatalog(
        existing: [downloadedGemma3, phi3, llama32],
        catalog: kCuratedModels,
      );

      expect(missing.map((m) => m.id).toSet(), equals({'gemma4-e2b-it', 'gemma4-e4b-it'}));
    });

    test('returns nothing when every catalog id already exists', () {
      final missing = modelsMissingFromCatalog(existing: kCuratedModels, catalog: kCuratedModels);
      expect(missing, isEmpty);
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

  group('isSupportedSideloadExtension', () {
    test('accepts .gguf files', () {
      expect(isSupportedSideloadExtension('phi3-mini.gguf'), isTrue);
    });

    test('is case-insensitive', () {
      expect(isSupportedSideloadExtension('Model.GGUF'), isTrue);
    });

    test('rejects .task files (no backend supports MediaPipe bundles)', () {
      expect(isSupportedSideloadExtension('gemma.task'), isFalse);
    });

    test('rejects unrelated extensions', () {
      expect(isSupportedSideloadExtension('notes.txt'), isFalse);
      expect(isSupportedSideloadExtension('archive.tar.gz'), isFalse);
    });

    test('rejects filenames without an extension', () {
      expect(isSupportedSideloadExtension('README'), isFalse);
    });
  });
}
