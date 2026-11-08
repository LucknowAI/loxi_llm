class AppSettings {
  const AppSettings({
    this.chunkSize = 300,
    this.topK = 3,
    this.speechRate = 0.5,
    this.modelIoLoggingEnabled = false,
    this.enabledToolNames = const {},
  });

  final int chunkSize;
  final int topK;

  /// flutter_tts rate. 0.5 is normal speed on Android.
  final double speechRate;

  /// When true, every model input/output exchange is recorded to the
  /// model-I/O trace log. Off by default.
  final bool modelIoLoggingEnabled;

  /// Agent tool names the user has left enabled. Empty means "all defaults".
  final Set<String> enabledToolNames;

  AppSettings copyWith({
    int? chunkSize,
    int? topK,
    double? speechRate,
    bool? modelIoLoggingEnabled,
    Set<String>? enabledToolNames,
  }) =>
      AppSettings(
        chunkSize: chunkSize ?? this.chunkSize,
        topK: topK ?? this.topK,
        speechRate: speechRate ?? this.speechRate,
        modelIoLoggingEnabled:
            modelIoLoggingEnabled ?? this.modelIoLoggingEnabled,
        enabledToolNames: enabledToolNames ?? this.enabledToolNames,
      );
}
