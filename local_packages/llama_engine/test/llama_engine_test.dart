import 'package:flutter_test/flutter_test.dart';
import 'package:llama_engine/llama_engine.dart';

void main() {
  group('LlamaConfig.toMap', () {
    test('omits mmprojPath when not set', () {
      const config = LlamaConfig(modelPath: '/tmp/model.gguf');
      expect(config.toMap().containsKey('mmprojPath'), isFalse);
    });

    test('includes mmprojPath when set', () {
      const config = LlamaConfig(
        modelPath: '/tmp/model.gguf',
        mmprojPath: '/tmp/mmproj.gguf',
      );
      expect(config.toMap()['mmprojPath'], '/tmp/mmproj.gguf');
    });
  });

  group('GenerationParams.toMap', () {
    test('imagePaths defaults to an empty list', () {
      const params = GenerationParams(prompt: 'hi');
      expect(params.toMap()['imagePaths'], isEmpty);
    });

    test('includes imagePaths when set', () {
      const params = GenerationParams(
        prompt: 'describe this',
        imagePaths: ['/tmp/a.jpg'],
      );
      expect(params.toMap()['imagePaths'], ['/tmp/a.jpg']);
    });
  });
}
