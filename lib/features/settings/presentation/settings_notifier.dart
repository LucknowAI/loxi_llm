import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/logging/model_io_logger.dart';
import '../../../core/providers/shared_preferences_provider.dart';
import '../../agent/agent_tool_catalog.dart';
import '../domain/app_settings.dart';

part 'settings_notifier.g.dart';

@riverpod
class SettingsNotifier extends _$SettingsNotifier {
  static const _keyChunkSize = 'settings_chunk_size';
  static const _keyTopK = 'settings_top_k';
  static const _keyModelIoLogging = 'settings_model_io_logging';
  // Persists which tools the user turned OFF (opt-out), not which are on, so
  // a tool added to the catalog after a user's last save defaults to enabled
  // instead of silently disappearing (#67).
  static const _keyDisabledTools = 'settings_disabled_tools';

  Set<String> _loadEnabledTools(SharedPreferences prefs) {
    final raw = prefs.getString(_keyDisabledTools);
    final disabled = raw == null || raw.isEmpty
        ? const <String>{}
        : raw.split(',').where((s) => s.isNotEmpty).toSet();
    return defaultEnabledToolNames().difference(disabled);
  }

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
      enabledToolNames: _loadEnabledTools(prefs),
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

  void setToolEnabled(String toolName, bool enabled) {
    final prefs = ref.read(sharedPreferencesProvider);
    final disabled = defaultEnabledToolNames().difference(
      state.enabledToolNames,
    );
    if (enabled) {
      disabled.remove(toolName);
    } else {
      disabled.add(toolName);
    }
    prefs.setString(_keyDisabledTools, disabled.join(','));
    ref.invalidateSelf();
  }
}
