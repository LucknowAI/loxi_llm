class AppSettings {
  const AppSettings({
    this.chunkSize = 300,
    this.topK = 3,
    this.modelIoLoggingEnabled = false,
  });

  final int chunkSize;
  final int topK;

  /// When true, every model input/output exchange is recorded to the
  /// model-I/O trace log. Off by default.
  final bool modelIoLoggingEnabled;

  AppSettings copyWith({
    int? chunkSize,
    int? topK,
    bool? modelIoLoggingEnabled,
  }) =>
      AppSettings(
        chunkSize: chunkSize ?? this.chunkSize,
        topK: topK ?? this.topK,
        modelIoLoggingEnabled:
            modelIoLoggingEnabled ?? this.modelIoLoggingEnabled,
      );
}
