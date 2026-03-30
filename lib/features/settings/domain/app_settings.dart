class AppSettings {
  const AppSettings({
    this.chunkSize = 300,
    this.topK = 3,
  });

  final int chunkSize;
  final int topK;

  AppSettings copyWith({int? chunkSize, int? topK}) => AppSettings(
        chunkSize: chunkSize ?? this.chunkSize,
        topK: topK ?? this.topK,
      );
}
