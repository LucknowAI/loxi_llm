import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/logging/model_io_logger.dart';
import '../../../core/providers/shared_preferences_provider.dart';
import '../domain/app_settings.dart';

part 'settings_notifier.g.dart';

@riverpod
class SettingsNotifier extends _$SettingsNotifier {
  static const _keyChunkSize = 'settings_chunk_size';
  static const _keyTopK = 'settings_top_k';
  static const _keyModelIoLogging = 'settings_model_io_logging';

  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final modelIoLoggingEnabled = prefs.getBool(_keyModelIoLogging) ?? false;
    // Keep the logger's gate in sync with the persisted setting.
    ModelIoLogger.instance.enabled = modelIoLoggingEnabled;
    return AppSettings(
      chunkSize: prefs.getInt(_keyChunkSize) ?? 300,
      topK: prefs.getInt(_keyTopK) ?? 3,
      modelIoLoggingEnabled: modelIoLoggingEnabled,
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

  void setModelIoLoggingEnabled(bool value) {
    ref.read(sharedPreferencesProvider).setBool(_keyModelIoLogging, value);
    ModelIoLogger.instance.enabled = value;
    ref.invalidateSelf();
  }
}
