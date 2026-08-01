import '../services/tts_service.dart';

/// Test / unsupported-platform stub.
final class NoOpTtsService implements TtsService {
  @override
  bool get isSupported => false;
  @override
  Future<void> dispose() async {}

  @override
  Future<void> speak(String text) async {}

  @override
  Future<void> stop() async {}
}
