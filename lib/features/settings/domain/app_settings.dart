class AppSettings {
  const AppSettings({
    this.chunkSize = 300,
    this.topK = 3,
    this.modelIoLoggingEnabled = false,
    this.enabledToolNames = const {},
  });

  final int chunkSize;
  final int topK;

  /// When true, every model input/output exchange is recorded to the
  /// model-I/O trace log. Off by default.
  final bool modelIoLoggingEnabled;

  /// Agent tool names the user has left enabled. Empty means "all defaults".
  final Set<String> enabledToolNames;

  AppSettings copyWith({
    int? chunkSize,
    int? topK,
    bool? modelIoLoggingEnabled,
    Set<String>? enabledToolNames,
  }) =>
      AppSettings(
        chunkSize: chunkSize ?? this.chunkSize,
        topK: topK ?? this.topK,
        modelIoLoggingEnabled:
            modelIoLoggingEnabled ?? this.modelIoLoggingEnabled,
        enabledToolNames: enabledToolNames ?? this.enabledToolNames,
      );
}
