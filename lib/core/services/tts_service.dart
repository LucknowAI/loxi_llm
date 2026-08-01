/// Platform text-to-speech abstraction (Phase 3 platform TTS; Pocket TTS later).
abstract class TtsService {
  /// Whether this implementation can speak on the current platform.
  bool get isSupported;

  /// Speak [text] aloud. Stops any in-progress utterance first.
  Future<void> speak(String text);

  /// Stop the current utterance, if any.
  Future<void> stop();

  /// Release native resources.
  Future<void> dispose();
}
