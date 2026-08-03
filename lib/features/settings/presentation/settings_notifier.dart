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
  static const _keyEnabledTools = 'settings_enabled_tools';

  Set<String> _loadEnabledTools(SharedPreferences prefs) {
    final raw = prefs.getString(_keyEnabledTools);
    if (raw == null || raw.isEmpty) return defaultEnabledToolNames();
    final names = raw.split(',').where((s) => s.isNotEmpty).toSet();
    return names.isEmpty ? defaultEnabledToolNames() : names;
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
    final current = {...state.enabledToolNames};
    if (enabled) {
      current.add(toolName);
    } else {
      current.remove(toolName);
    }
    prefs.setString(_keyEnabledTools, current.join(','));
    ref.invalidateSelf();
  }
}
