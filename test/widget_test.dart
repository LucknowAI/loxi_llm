import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loki_llm/core/providers/objectbox_provider.dart';
import 'package:loki_llm/core/providers/shared_preferences_provider.dart';
import 'package:loki_llm/features/models/domain/model.dart';
import 'package:loki_llm/features/models/domain/model_status.dart';
import 'package:loki_llm/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('MyApp navigation smoke test', () {
    testWidgets('renders 3-tab bottom navigation', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({'onboarding_complete': true});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // Override store with unimplemented stub — ModelsNotifier
            // returns empty list when box is uninitialized in test env.
            objectBoxStoreProvider.overrideWith(
              (ref) => throw UnimplementedError('No store in test'),
            ),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MyApp(),
        ),
      );
      // Allow async providers to settle
      await tester.pump();

      expect(find.byType(NavigationBar), findsOneWidget);
      // NavigationBar renders labels twice (visible + semantics node)
      expect(find.text('Models'), findsAtLeastNWidgets(1));
      expect(find.text('Chat'), findsAtLeastNWidgets(1));
      expect(find.text('Documents'), findsAtLeastNWidgets(1));
    });
  });

  group('Model domain', () {
    test('Model.isDownloaded returns true when status is downloaded', () {
      const model = Model(
        id: 'test-1',
        name: 'Test Model',
        sizeLabel: '2GB',
        sizeBytes: 2000000000,
        status: ModelStatus.downloaded,
        localPath: '/tmp/test.gguf',
      );
      expect(model.isDownloaded, isTrue);
      expect(model.isDownloading, isFalse);
      expect(model.canLoad, isTrue);
    });

    test('Model.canLoad is false without localPath', () {
      const model = Model(
        id: 'test-2',
        name: 'Test Model',
        sizeLabel: '2GB',
        sizeBytes: 2000000000,
        status: ModelStatus.downloaded,
      );
      expect(model.isDownloaded, isTrue);
      expect(model.canLoad, isFalse);
    });

    test('Model.isDownloading returns true when status is downloading', () {
      const model = Model(
        id: 'test-3',
        name: 'Test Model',
        sizeLabel: '2GB',
        sizeBytes: 2000000000,
        status: ModelStatus.downloading,
      );
      expect(model.isDownloading, isTrue);
      expect(model.isDownloaded, isFalse);
    });

    test('Model.copyWith preserves unchanged fields', () {
      const model = Model(
        id: 'test-4',
        name: 'Original Name',
        sizeLabel: '2GB',
        sizeBytes: 2000000000,
      );
      final updated = model.copyWith(name: 'Updated Name');
      expect(updated.name, equals('Updated Name'));
      expect(updated.id, equals('test-4'));
      expect(updated.status, equals(ModelStatus.available));
    });

    test('Model default status is available', () {
      const model = Model(
        id: 'test-5',
        name: 'Test',
        sizeLabel: '1GB',
        sizeBytes: 1000000000,
      );
      expect(model.status, equals(ModelStatus.available));
      expect(model.downloadProgress, equals(0.0));
      expect(model.format, equals('gguf'));
    });
  });
}
