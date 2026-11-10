/// Platform text-to-speech abstraction (Phase 3 platform TTS; Pocket TTS later).
abstract class TtsService {
  /// Whether this implementation can speak on the current platform.
  bool get isSupported;

  /// Speak [text] aloud. Stops any in-progress utterance first.
  ///
  /// [rate] is the flutter_tts scale: 0.5 is normal speed.
  Future<void> speak(String text, {double rate = 0.5});

  /// Pause the current utterance so [resume] can continue it.
  ///
  /// False when this engine cannot pause. The utterance is stopped, so the
  /// next speak starts from the beginning.
  Future<bool> pause();

  /// Continue the utterance paused by [pause].
  Future<void> resume({double rate = 0.5});

  /// Stop the current utterance, if any.
  Future<void> stop();

  /// Release native resources.
  Future<void> dispose();
}
