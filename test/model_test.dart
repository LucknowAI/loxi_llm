import 'package:flutter_test/flutter_test.dart';
import 'package:loki_llm/features/models/domain/model.dart';

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
}
