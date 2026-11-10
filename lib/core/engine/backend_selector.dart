import '../../features/models/domain/model.dart';
import 'inference_backend.dart';
import 'llama_cpp_backend.dart';

/// Returns the [InferenceBackend] for the given [model].
///
/// All models run through [LlamaCppBackend] (GGUF via the MIT `llama_engine`
/// plugin). Each call returns a NEW instance; the caller ([InferenceNotifier])
/// keeps it alive. Per-model sampling defaults are passed in at load and
/// generate time.
InferenceBackend backendForModel(Model model) => LlamaCppBackend();
