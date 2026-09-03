import 'package:flutter_test/flutter_test.dart';
import 'package:loki_llm/features/models/domain/model.dart';
import 'package:loki_llm/features/models/domain/model_status.dart';

Model _model({String? mmprojFilename}) => Model(
      id: 'm1',
      name: 'Test Model',
      sizeLabel: '1 GB',
      sizeBytes: 1000000000,
      mmprojFilename: mmprojFilename,
    );

void main() {
  group('Model multimodal fields', () {
    test('mmproj fields default to null', () {
      final model = _model();
      expect(model.mmprojFilename, isNull);
      expect(model.mmprojHuggingFaceRepo, isNull);
      expect(model.mmprojLocalPath, isNull);
      expect(model.mmprojSizeBytes, isNull);
    });

    test('mmproj fields round-trip through the constructor', () {
      const model = Model(
        id: 'm1',
        name: 'Gemma 4 E2B',
        sizeLabel: '2 GB',
        sizeBytes: 2000000000,
        mmprojFilename: 'mmproj-gemma4-e2b-f16.gguf',
        mmprojHuggingFaceRepo: 'google/gemma-4-e2b-gguf',
        mmprojLocalPath: '/data/models/mmproj-gemma4-e2b-f16.gguf',
        mmprojSizeBytes: 500000000,
      );
      expect(model.mmprojFilename, 'mmproj-gemma4-e2b-f16.gguf');
      expect(model.mmprojHuggingFaceRepo, 'google/gemma-4-e2b-gguf');
      expect(model.mmprojLocalPath, '/data/models/mmproj-gemma4-e2b-f16.gguf');
      expect(model.mmprojSizeBytes, 500000000);
    });
  });

  group('isMultimodalModel', () {
    test('false when mmprojFilename is null', () {
      expect(isMultimodalModel(_model()), isFalse);
    });

    test('true when mmprojFilename is set', () {
      expect(
        isMultimodalModel(_model(mmprojFilename: 'mmproj.gguf')),
        isTrue,
      );
    });
  });

  group('Model JSON serialization', () {
    test('round-trips a vision model through toJson/fromJson, mmproj fields '
        'included', () {
      const model = Model(
        id: 'gemma4-e2b-it',
        name: 'Gemma 4 E2B IT (Vision)',
        sizeLabel: '3.11 GB',
        sizeBytes: 3106738272,
        status: ModelStatus.downloaded,
        downloadProgress: 1.0,
        localPath: '/data/models/gemma-4-E2B-it-Q4_K_M.gguf',
        huggingFaceRepo: 'unsloth/gemma-4-E2B-it-GGUF',
        filename: 'gemma-4-E2B-it-Q4_K_M.gguf',
        format: 'gguf',
        mmprojFilename: 'mmproj-F16.gguf',
        mmprojHuggingFaceRepo: 'unsloth/gemma-4-E2B-it-GGUF',
        mmprojLocalPath: '/data/models/mmproj-F16.gguf',
        mmprojSizeBytes: 985654080,
      );
      final roundTripped = Model.fromJson(model.toJson());
      expect(roundTripped, model);
    });

    test('round-trips a text-only model (all nullable fields absent)', () {
      const model = Model(
        id: 'phi3-mini-4k-q4km',
        name: 'Phi-3 Mini 4K Q4_K_M',
        sizeLabel: '2.4 GB',
        sizeBytes: 2391343104,
      );
      final roundTripped = Model.fromJson(model.toJson());
      expect(roundTripped, model);
    });
  });
}
