import '../../features/models/domain/model.dart';
import 'chat_template.dart';
import 'inference_backend.dart';
import 'llama_cpp_backend.dart';

/// Returns the [InferenceBackend] for the given [model].
///
/// All models run through [LlamaCppBackend] (GGUF via the MIT `llama_engine`
/// plugin). Each call returns a NEW instance; the caller ([InferenceNotifier])
/// keeps it alive.
InferenceBackend backendForModel(Model model) {
  // LFM3's model card (and its GGUF metadata) recommends temperature 0.1; at
  // the app default of 0.7 it drifts into visible reasoning with thinking off.
  // Moves to per-model catalog defaults with the advanced-settings work.
  if (ChatTemplate.forModelId(model.id).kind == ChatTemplateKind.lfm3) {
    return LlamaCppBackend(temperature: 0.1);
  }
  return LlamaCppBackend();
}
