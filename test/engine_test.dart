import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loki_llm/core/engine/backend_selector.dart';
import 'package:loki_llm/core/engine/inference_backend.dart';
import 'package:loki_llm/core/engine/llama_cpp_backend.dart';
import 'package:loki_llm/core/providers/inference_provider.dart';
import 'package:loki_llm/core/providers/objectbox_provider.dart';
import 'package:loki_llm/core/providers/shared_preferences_provider.dart';
import 'package:loki_llm/features/models/domain/model.dart';
import 'package:loki_llm/features/models/domain/model_status.dart';
import 'package:loki_llm/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('backendForModel (backend selector)', () {
    test('returns LlamaCppBackend for any format', () {
      const model = Model(
        id: 'gemma-2b',
        name: 'Gemma 2B',
        sizeLabel: '1.5GB',
        sizeBytes: 1500000000,
        format: 'task',
        status: ModelStatus.downloaded,
        localPath: '/tmp/gemma.task',
      );
      final backend = backendForModel(model);
      expect(backend, isA<LlamaCppBackend>());
    });

    test('returns LlamaCppBackend for format == gguf (default)', () {
      const model = Model(
        id: 'phi-3',
        name: 'Phi-3 Mini',
        sizeLabel: '2GB',
        sizeBytes: 2000000000,
        // format defaults to 'gguf'
        status: ModelStatus.downloaded,
        localPath: '/tmp/phi3.gguf',
      );
      final backend = backendForModel(model);
      expect(backend, isA<LlamaCppBackend>());
    });

    test('returns LlamaCppBackend for unknown format string', () {
      const model = Model(
        id: 'unknown-model',
        name: 'Unknown Format Model',
        sizeLabel: '1GB',
        sizeBytes: 1000000000,
        format: 'bin',
        status: ModelStatus.downloaded,
        localPath: '/tmp/model.bin',
      );
      final backend = backendForModel(model);
      expect(backend, isA<LlamaCppBackend>());
    });

    test('each call returns a NEW backend instance', () {
      const model = Model(
        id: 'phi-3',
        name: 'Phi-3 Mini',
        sizeLabel: '2GB',
        sizeBytes: 2000000000,
        status: ModelStatus.downloaded,
        localPath: '/tmp/phi3.gguf',
      );
      final backend1 = backendForModel(model);
      final backend2 = backendForModel(model);
      expect(identical(backend1, backend2), isFalse);
    });
  });

  group('InferenceBackend base class', () {
    test('default loadModel throws UnimplementedError', () {
      final backend = _StubBackend();
      expect(
        () => backend.loadModel('/tmp/model.gguf'),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('default isLoaded throws UnimplementedError', () {
      final backend = _StubBackend();
      expect(() => backend.isLoaded, throwsA(isA<UnimplementedError>()));
    });

    test('default embeddings throws UnimplementedError', () {
      final backend = _StubBackend();
      expect(
        () => backend.embeddings('hello'),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('default stop() is a no-op (does not throw)', () {
      final backend = _StubBackend();
      expect(backend.stop(), completes);
    });

    test('default supportsVision is false', () {
      final backend = _StubBackend();
      expect(backend.supportsVision, isFalse);
    });

    test('default mediaMarker throws UnimplementedError', () {
      final backend = _StubBackend();
      expect(
        () => backend.mediaMarker(),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });

  group('InferenceBackend.generate stopSequences', () {
    test('carries stopSequences through to the implementation', () async {
      final backend = _CapturingBackend();
      await backend
          .generate('hi', stopSequences: const ['<end_of_turn>'])
          .toList();
      expect(backend.lastStops, const ['<end_of_turn>']);
    });

    test('defaults stopSequences to empty when omitted', () async {
      final backend = _CapturingBackend();
      await backend.generate('hi').toList();
      expect(backend.lastStops, isEmpty);
    });
  });

  group('InferenceBackend.generate imagePaths', () {
    test('carries imagePaths through to the implementation', () async {
      final backend = _CapturingBackend();
      await backend.generate('prompt', imagePaths: ['/tmp/a.jpg']).toList();
      expect(backend.lastImagePaths, ['/tmp/a.jpg']);
    });

    test('defaults imagePaths to empty when omitted', () async {
      final backend = _CapturingBackend();
      await backend.generate('prompt').toList();
      expect(backend.lastImagePaths, isEmpty);
    });
  });

  group('InferenceBackend.loadModel mmprojPath', () {
    test('carries mmprojPath through to the implementation', () async {
      final backend = _CapturingBackend();
      await backend.loadModel('/tmp/model.gguf', mmprojPath: '/tmp/mmproj.gguf');
      expect(backend.lastMmprojPath, '/tmp/mmproj.gguf');
    });
  });

  group('InferenceNotifier initial state', () {
    test('build() returns AsyncData(null) — no model loaded at startup', () async {
      final container = ProviderContainer(
        overrides: [
          objectBoxStoreProvider.overrideWith(
            (ref) => throw UnimplementedError('No store in test'),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Await the future to let the AsyncNotifier.build() resolve
      final value = await container.read(inferenceNotifierProvider.future);
      expect(value, isNull);
    });
  });

  group('ChatScreen widget', () {
    testWidgets('shows load-model prompt when no backend loaded', (tester) async {
      SharedPreferences.setMockInitialValues({'onboarding_complete': true});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            objectBoxStoreProvider.overrideWith(
              (ref) => throw UnimplementedError('No store in test'),
            ),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MyApp(),
        ),
      );
      await tester.pump();

      // Navigate to Chat tab
      await tester.tap(find.text('Chat'));
      await tester.pumpAndSettle();

      expect(
        find.text('Load a model from the Models tab\nto start chatting.'),
        findsOneWidget,
      );
    });
  });
}

/// Minimal concrete subclass of InferenceBackend used to test
/// that the base-class default methods throw [UnimplementedError].
final class _StubBackend extends InferenceBackend {}

/// Records the [stopSequences] passed to [generate] and whether [stop] was
/// called, so the abstraction's contract can be asserted without native plugins.
final class _CapturingBackend extends InferenceBackend {
  List<String>? lastStops;
  bool stopCalled = false;
  List<String>? lastImagePaths;
  String? lastMmprojPath;

  @override
  Future<void> loadModel(String path, {String? mmprojPath}) async {
    lastMmprojPath = mmprojPath;
  }

  @override
  Stream<String> generate(
    String prompt, {
    List<String> stopSequences = const [],
    String? grammar,
    List<String> imagePaths = const [],
  }) async* {
    lastStops = stopSequences;
    lastImagePaths = imagePaths;
  }

  @override
  Future<void> stop() async {
    stopCalled = true;
  }
}
