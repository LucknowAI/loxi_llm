import 'package:flutter_test/flutter_test.dart';
import 'package:loki_llm/core/services/ram_check_service.dart';
import 'package:loki_llm/features/models/domain/model.dart';

const _smallModel = Model(
  id: 'gemma3-270m-it',
  name: 'Gemma 3 270M IT',
  sizeLabel: '253 MB',
  sizeBytes: 265289728, // 253 MiB
);

const _largeTextOnlyModel = Model(
  id: 'phi3-mini-4k-q4km',
  name: 'Phi-3 Mini 4K Q4_K_M',
  sizeLabel: '2.4 GB',
  sizeBytes: 2391343104, // ~2280 MiB
);

const _visionModel = Model(
  id: 'gemma4-e2b-it',
  name: 'Gemma 4 E2B IT (Vision)',
  sizeLabel: '3.11 GB',
  sizeBytes: 3106738272, // ~2963 MiB
  mmprojFilename: 'mmproj-F16.gguf',
  mmprojSizeBytes: 985654080, // ~940 MiB
);

// A base model small enough alone to stay under the 2048 MiB threshold, but
// pushed over it once its mmproj is added — proves the combined-size math,
// not just the base size.
const _smallBaseVisionModel = Model(
  id: 'hypothetical-small-vision',
  name: 'Hypothetical Small Vision',
  sizeLabel: '1.9 GB',
  sizeBytes: 1992294400, // 1900 MiB
  mmprojFilename: 'mmproj-F16.gguf',
  mmprojSizeBytes: 209715200, // 200 MiB -> combined 2100 MiB, over threshold
);

void main() {
  group('isLargeModel', () {
    test('false for a small text-only model', () {
      expect(isLargeModel(_smallModel), isFalse);
    });

    test('true for a large text-only model', () {
      expect(isLargeModel(_largeTextOnlyModel), isTrue); // ~2280 MiB > 2048
    });

    test('true for a vision model whose base alone is already large', () {
      expect(isLargeModel(_visionModel), isTrue);
    });

    test('true when the mmproj pushes an otherwise-small base over the threshold', () {
      expect(isLargeModel(_smallBaseVisionModel), isTrue);
    });
  });

  group('ramWarningMessage', () {
    test('text-only model: mentions total size and the fallback recommendation', () {
      final msg = ramWarningMessage(_largeTextOnlyModel);
      expect(msg, contains('2.2 GB')); // 2280 MiB / 1024
      expect(msg, contains('Recommended: use Gemma 3 270M'));
      expect(msg, isNot(contains('vision component')));
    });

    test('vision model: breaks out the vision component and skips the fallback', () {
      final msg = ramWarningMessage(_visionModel);
      expect(msg, contains('vision component'));
      expect(msg, isNot(contains('Recommended: use Gemma 3 270M')));
    });
  });
}
