import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../platform/flutter_tts_service.dart';
import '../platform/no_op_tts_service.dart';
import '../services/tts_service.dart';

/// App-wide TTS service. Uses platform TTS on Android; no-op elsewhere (for now).
final ttsServiceProvider = Provider<TtsService>((ref) {
  final TtsService service =
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android
          ? FlutterTtsService()
          : NoOpTtsService();
  ref.onDispose(() => service.dispose());
  return service;
});
