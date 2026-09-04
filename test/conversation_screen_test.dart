import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loki_llm/core/engine/inference_backend.dart';
import 'package:loki_llm/features/chat/presentation/chat_notifier.dart';
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

  group('attachedPathToRestoreAfterSendError', () {
    test('null when there was no attachment', () async {
      expect(await attachedPathToRestoreAfterSendError(null), isNull);
    });

    test('returns the path when the file still exists (e.g. no-model error)', () async {
      final file = File('${Directory.systemTemp.path}/loki-restore-ok-${DateTime.now().microsecondsSinceEpoch}.jpg');
      await file.writeAsBytes(const [0xFF, 0xD8]);
      addTearDown(() async {
        if (await file.exists()) await file.delete();
      });

      expect(await attachedPathToRestoreAfterSendError(file.path), file.path);
    });

    test('null when the file is gone (e.g. missing-image error)', () async {
      final missing =
          '${Directory.systemTemp.path}/loki-restore-missing-${DateTime.now().microsecondsSinceEpoch}.jpg';
      expect(await attachedPathToRestoreAfterSendError(missing), isNull);
    });
  });

  group('shouldRestoreComposerAfterSendError', () {
    test('true for a pre-persist failure (nothing was sent — worth retrying)', () {
      expect(
        shouldRestoreComposerAfterSendError(StateError('No model loaded')),
        isTrue,
      );
      expect(
        shouldRestoreComposerAfterSendError(
          StateError('Attached image is no longer available. Please re-attach.'),
        ),
        isTrue,
      );
    });

    test('false for a post-persist failure (message already sent — nothing '
        'to retry, restoring risks a near-duplicate resend)', () {
      expect(
        shouldRestoreComposerAfterSendError(
          const SendFailedAfterPersistException('mediaMarker failed'),
        ),
        isFalse,
      );
    });
  });
}
