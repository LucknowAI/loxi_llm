import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loki_llm/core/providers/shared_preferences_provider.dart';
import 'package:loki_llm/features/settings/presentation/settings_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SettingsNotifier', () {
    Future<(ProviderContainer, SharedPreferences)> makeContainer({
      Map<String, Object> initialValues = const {},
    }) async {
      SharedPreferences.setMockInitialValues(initialValues);
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      return (container, prefs);
    }

    test('defaults to chunkSize=300 and topK=3 when SharedPreferences is empty',
        () async {
      final (container, _) = await makeContainer();
      addTearDown(container.dispose);

      final settings = container.read(settingsNotifierProvider);

      expect(settings.chunkSize, equals(300));
      expect(settings.topK, equals(3));
    });

    test('reads persisted chunkSize from SharedPreferences', () async {
      final (container, _) = await makeContainer(
        initialValues: {'settings_chunk_size': 150},
      );
      addTearDown(container.dispose);

      expect(container.read(settingsNotifierProvider).chunkSize, equals(150));
    });

    test('reads persisted topK from SharedPreferences', () async {
      final (container, _) = await makeContainer(
        initialValues: {'settings_top_k': 7},
      );
      addTearDown(container.dispose);

      expect(container.read(settingsNotifierProvider).topK, equals(7));
    });

    test('reads both persisted values simultaneously', () async {
      final (container, _) = await makeContainer(
        initialValues: {'settings_chunk_size': 200, 'settings_top_k': 5},
      );
      addTearDown(container.dispose);

      final settings = container.read(settingsNotifierProvider);
      expect(settings.chunkSize, equals(200));
      expect(settings.topK, equals(5));
    });

    test('setChunkSize writes the new value to SharedPreferences', () async {
      final (container, prefs) = await makeContainer();
      addTearDown(container.dispose);

      container.read(settingsNotifierProvider.notifier).setChunkSize(400);

      expect(prefs.getInt('settings_chunk_size'), equals(400));
    });

    test('setTopK writes the new value to SharedPreferences', () async {
      final (container, prefs) = await makeContainer();
      addTearDown(container.dispose);

      container.read(settingsNotifierProvider.notifier).setTopK(8);

      expect(prefs.getInt('settings_top_k'), equals(8));
    });

    test('setChunkSize followed by setTopK persists both independently', () async {
      final (container, prefs) = await makeContainer();
      addTearDown(container.dispose);

      container.read(settingsNotifierProvider.notifier).setChunkSize(100);
      container.read(settingsNotifierProvider.notifier).setTopK(10);

      expect(prefs.getInt('settings_chunk_size'), equals(100));
      expect(prefs.getInt('settings_top_k'), equals(10));
    });

    test('overwriting chunkSize replaces the previous value', () async {
      final (container, prefs) = await makeContainer(
        initialValues: {'settings_chunk_size': 300},
      );
      addTearDown(container.dispose);

      container.read(settingsNotifierProvider.notifier).setChunkSize(500);

      expect(prefs.getInt('settings_chunk_size'), equals(500));
    });

    test('defaults all agent tools enabled', () async {
      final (container, _) = await makeContainer();
      addTearDown(container.dispose);

      final settings = container.read(settingsNotifierProvider);
      expect(settings.enabledToolNames.length, equals(7));
      expect(settings.enabledToolNames, contains('calculator'));
      expect(settings.enabledToolNames, contains('unit_convert'));
    });

    test('setToolEnabled persists disabled tools', () async {
      final (container, prefs) = await makeContainer();
      addTearDown(container.dispose);

      container
          .read(settingsNotifierProvider.notifier)
          .setToolEnabled('calculator', false);

      expect(
        prefs.getString('settings_enabled_tools'),
        isNot(contains('calculator')),
      );
      expect(
        container.read(settingsNotifierProvider).enabledToolNames,
        isNot(contains('calculator')),
      );
    });

    test('setToolEnabled re-enables a disabled tool', () async {
      final (container, prefs) = await makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(settingsNotifierProvider.notifier);
      notifier.setToolEnabled('datetime', false);
      notifier.setToolEnabled('datetime', true);

      expect(prefs.getString('settings_enabled_tools'), contains('datetime'));
      expect(
        container.read(settingsNotifierProvider).enabledToolNames,
        contains('datetime'),
      );
    });
  });
}
