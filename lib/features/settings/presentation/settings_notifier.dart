import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/logging/model_io_logger.dart';
import '../../../core/providers/shared_preferences_provider.dart';
import '../../agent/agent_tool_catalog.dart';
import '../domain/app_settings.dart';
import '../domain/generation_settings.dart';

part 'settings_notifier.g.dart';

@riverpod
class SettingsNotifier extends _$SettingsNotifier {
  static const _keyChunkSize = 'settings_chunk_size';
  static const _keyTopK = 'settings_top_k';
  static const _keySpeechRate = 'settings_speech_rate';
  static const _keyModelIoLogging = 'settings_model_io_logging';
  // Persists which tools the user turned OFF (opt-out), not which are on, so
  // a tool added to the catalog after a user's last save defaults to enabled
  // instead of silently disappearing (#67).
  static const _keyDisabledTools = 'settings_disabled_tools';
  static const _keyPrompts = 'settings_prompt_library';

  /// flutter_tts accepts 0.0–1.0. Keep the slider off the silent end.
  static double _speechRate(double value) => value.clamp(0.25, 1.0);

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
      speechRate: _speechRate(prefs.getDouble(_keySpeechRate) ?? 0.5),
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

  void setSpeechRate(double value) {
    ref
        .read(sharedPreferencesProvider)
        .setDouble(_keySpeechRate, _speechRate(value));
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

  static String _genKey(String modelId, String name) => 'gen_${modelId}_$name';

  /// Saved settings for [modelId], or that model's defaults when unset.
  GenerationSettings generationFor(String modelId) {
    final prefs = ref.read(sharedPreferencesProvider);
    final defaults = GenerationSettings.defaultsFor(modelId);
    return GenerationSettings(
      temperature: prefs.getDouble(_genKey(modelId, 'temperature')) ??
          defaults.temperature,
      maxTokens:
          prefs.getInt(_genKey(modelId, 'max_tokens')) ?? defaults.maxTokens,
      topK: prefs.getInt(_genKey(modelId, 'top_k')) ?? defaults.topK,
      topP: prefs.getDouble(_genKey(modelId, 'top_p')) ?? defaults.topP,
      repeatPenalty:
          prefs.getDouble(_genKey(modelId, 'repeat')) ?? defaults.repeatPenalty,
      nThreads: prefs.getInt(_genKey(modelId, 'threads')) ?? defaults.nThreads,
      contextSize:
          prefs.getInt(_genKey(modelId, 'context')) ?? defaults.contextSize,
      batchSize: prefs.getInt(_genKey(modelId, 'batch')) ?? defaults.batchSize,
    ).clamped();
  }

  void saveGeneration(String modelId, GenerationSettings settings) {
    final saved = settings.clamped();
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setDouble(_genKey(modelId, 'temperature'), saved.temperature);
    prefs.setInt(_genKey(modelId, 'max_tokens'), saved.maxTokens);
    prefs.setInt(_genKey(modelId, 'top_k'), saved.topK);
    prefs.setDouble(_genKey(modelId, 'top_p'), saved.topP);
    prefs.setDouble(_genKey(modelId, 'repeat'), saved.repeatPenalty);
    prefs.setInt(_genKey(modelId, 'threads'), saved.nThreads);
    prefs.setInt(_genKey(modelId, 'context'), saved.contextSize);
    prefs.setInt(_genKey(modelId, 'batch'), saved.batchSize);
    ref.invalidateSelf();
  }

  /// Named system prompts. Editing one does not change chats that already
  /// copied it.
  List<SavedPrompt> savedPrompts() {
    final raw = ref.read(sharedPreferencesProvider).getString(_keyPrompts);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [
        for (final item in decoded)
          if (item is Map && item['name'] is String && item['body'] is String)
            SavedPrompt(
              name: item['name'] as String,
              body: item['body'] as String,
            ),
      ];
    } catch (_) {
      return const [];
    }
  }

  /// Saves [body] under [name]. The same name replaces the previous text.
  void savePrompt(String name, String body) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    _writePrompts([
      for (final prompt in savedPrompts())
        if (prompt.name != trimmed) prompt,
      SavedPrompt(name: trimmed, body: body),
    ]);
  }

  void deletePrompt(String name) {
    _writePrompts([
      for (final prompt in savedPrompts())
        if (prompt.name != name) prompt,
    ]);
  }

  void _writePrompts(List<SavedPrompt> prompts) {
    ref.read(sharedPreferencesProvider).setString(
          _keyPrompts,
          jsonEncode([
            for (final prompt in prompts)
              {'name': prompt.name, 'body': prompt.body},
          ]),
        );
    ref.invalidateSelf();
  }
}

class SavedPrompt {
  const SavedPrompt({required this.name, required this.body});

  final String name;
  final String body;
}
