import 'package:flutter_tts/flutter_tts.dart';

import '../services/speech_text_normalizer.dart';
import '../services/tts_service.dart';

/// Android/iOS platform TTS via [FlutterTts] (wraps TextToSpeech on Android).
final class FlutterTtsService implements TtsService {
  FlutterTtsService() : _tts = FlutterTts() {
    _tts.awaitSpeakCompletion(true);
  }

  final FlutterTts _tts;

  /// Normalized text of the utterance in progress. Resume speaks this again.
  String? _utterance;

  /// Bumped by pause and stop so a speak that has not started yet gives up.
  int _gen = 0;

  @override
  bool get isSupported => true;

  @override
  Future<void> speak(String text, {double rate = 0.5}) async {
    final speakable = SpeechTextNormalizer.normalize(text);
    if (speakable.isEmpty) return;
    final gen = ++_gen;
    _utterance = speakable;
    await _tts.stop();
    if (gen != _gen) return;
    await _tts.setSpeechRate(rate);
    if (gen != _gen) return;
    await _tts.speak(speakable);
  }

  @override
  Future<void> pause() {
    _gen++;
    return _tts.pause();
  }

  @override
  Future<void> resume({double rate = 0.5}) async {
    final text = _utterance;
    if (text == null) return;
    final gen = _gen;
    await _tts.setSpeechRate(rate);
    if (gen != _gen || _utterance == null) return;
    // Same string as speak(). stop() here would drop the paused remainder.
    await _tts.speak(text);
  }

  @override
  Future<void> stop() async {
    _gen++;
    _utterance = null;
    await _tts.stop();
  }

  @override
  Future<void> dispose() => stop();
}
