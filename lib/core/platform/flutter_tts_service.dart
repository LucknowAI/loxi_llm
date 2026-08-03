import 'package:flutter_tts/flutter_tts.dart';

import '../services/speech_text_normalizer.dart';
import '../services/tts_service.dart';

/// Android/iOS platform TTS via [FlutterTts] (wraps TextToSpeech on Android).
final class FlutterTtsService implements TtsService {
  FlutterTtsService() : _tts = FlutterTts() {
    _tts.awaitSpeakCompletion(true);
  }

  final FlutterTts _tts;

  @override
  bool get isSupported => true;

  @override
  Future<void> speak(String text) async {
    final speakable = SpeechTextNormalizer.normalize(text);
    if (speakable.isEmpty) return;
    await _tts.stop();
    await _tts.speak(speakable);
  }

  @override
  Future<void> stop() => _tts.stop();

  @override
  Future<void> dispose() => _tts.stop();
}
