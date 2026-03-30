import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/shared_preferences_provider.dart';
import '../domain/app_settings.dart';

part 'settings_notifier.g.dart';

@riverpod
class SettingsNotifier extends _$SettingsNotifier {
  static const _keyChunkSize = 'settings_chunk_size';
  static const _keyTopK = 'settings_top_k';

  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return AppSettings(
      chunkSize: prefs.getInt(_keyChunkSize) ?? 300,
      topK: prefs.getInt(_keyTopK) ?? 3,
    );
  }

  void setChunkSize(int value) {
    ref.read(sharedPreferencesProvider).setInt(_keyChunkSize, value);
    ref.invalidateSelf();
  }

  void setTopK(int value) {
    ref.read(sharedPreferencesProvider).setInt(_keyTopK, value);
    ref.invalidateSelf();
  }
}
