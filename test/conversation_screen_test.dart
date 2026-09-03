import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loki_llm/core/engine/inference_backend.dart';
import 'package:loki_llm/features/chat/presentation/conversation_screen.dart';
import 'package:loki_llm/features/models/domain/model.dart';

final class _FakeBackend extends InferenceBackend {
  _FakeBackend({required bool supportsVision}) : _supportsVision = supportsVision;
  final bool _supportsVision;

  @override
  bool get supportsVision => _supportsVision;
}

const _visionModel = Model(
  id: 'gemma4-e2b-it',
  name: 'Gemma 4 E2B IT (Vision)',
  sizeLabel: '3.11 GB',
  sizeBytes: 3106738272,
  mmprojFilename: 'mmproj-F16.gguf',
);

const _textOnlyModel = Model(
  id: 'phi3-mini-4k-q4km',
  name: 'Phi-3 Mini 4K Q4_K_M',
  sizeLabel: '2.4 GB',
  sizeBytes: 2391343104,
);

void main() {
  group('stillAllowsAttachment', () {
    test('true while a load is in flight, regardless of the outgoing model', () {
      expect(stillAllowsAttachment(const AsyncLoading(), _visionModel), isTrue);
      expect(stillAllowsAttachment(const AsyncLoading(), _textOnlyModel), isTrue);
      expect(stillAllowsAttachment(const AsyncLoading(), null), isTrue);
    });

    test('true once settled on a vision-capable model with a vision-capable backend', () {
      final next = AsyncData<InferenceBackend?>(_FakeBackend(supportsVision: true));
      expect(stillAllowsAttachment(next, _visionModel), isTrue);
    });

    test('false once settled on a vision-capable model but the backend never confirmed vision', () {
      final next = AsyncData<InferenceBackend?>(_FakeBackend(supportsVision: false));
      expect(stillAllowsAttachment(next, _visionModel), isFalse);
    });

    test('false once settled on a text-only model even if the backend reports vision', () {
      final next = AsyncData<InferenceBackend?>(_FakeBackend(supportsVision: true));
      expect(stillAllowsAttachment(next, _textOnlyModel), isFalse);
    });

    test('false once settled with no model loaded', () {
      const next = AsyncData<InferenceBackend?>(null);
      expect(stillAllowsAttachment(next, null), isFalse);
    });

    test('false after a load error', () {
      const next = AsyncError<InferenceBackend?>('boom', StackTrace.empty);
      expect(stillAllowsAttachment(next, null), isFalse);
    });
  });
}
