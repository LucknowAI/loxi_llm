import '../../features/models/domain/model.dart';
import 'inference_backend.dart';
import 'llama_cpp_backend.dart';
import 'mediapipe_backend.dart';

/// Returns the appropriate [InferenceBackend] for the given [model].
///
/// - `'task'` format → [MediaPipeBackend] (flutter_gemma, Gemma .task files)
/// - All other formats (default `'gguf'`) → [LlamaCppBackend] (flutter_llama)
///
/// Each call returns a NEW instance. The caller ([InferenceNotifier]) is
/// responsible for keeping the returned instance alive.
InferenceBackend backendForModel(Model model) {
  return switch (model.format) {
    'task' => MediaPipeBackend(),
    _ => LlamaCppBackend(),
  };
}
