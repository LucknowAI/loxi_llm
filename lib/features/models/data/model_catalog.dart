import '../domain/model.dart';

/// Curated models shown to users on first launch.
/// These are seeded into ObjectBox when the DB is empty.
const List<Model> kCuratedModels = [
  Model(
    id: 'gemma3-270m-it',
    name: 'Gemma 3 270M IT',
    sizeLabel: '304 MB',
    sizeBytes: 318767104,
    format: 'task',
    huggingFaceRepo: 'litert-community/gemma-3-270m-it',
    filename: 'gemma3-270m-it-q8.task',
  ),
  Model(
    id: 'phi3-mini-4k-q4km',
    name: 'Phi-3 Mini 4K Q4_K_M',
    sizeLabel: '2.4 GB',
    sizeBytes: 2391343104,
    format: 'gguf',
    huggingFaceRepo: 'bartowski/Phi-3-mini-4k-instruct-GGUF',
    filename: 'Phi-3-mini-4k-instruct-Q4_K_M.gguf',
  ),
  Model(
    id: 'llama32-3b-q4km',
    name: 'Llama 3.2 3B Q4_K_M',
    sizeLabel: '2.0 GB',
    sizeBytes: 2019000000,
    format: 'gguf',
    huggingFaceRepo: 'bartowski/Llama-3.2-3B-Instruct-GGUF',
    filename: 'Llama-3.2-3B-Instruct-Q4_K_M.gguf',
  ),
];

/// Compute HuggingFace download URL from model metadata.
String huggingFaceDownloadUrl(Model model) {
  assert(model.huggingFaceRepo != null && model.filename != null,
      'Model ${model.id} is missing huggingFaceRepo or filename');
  return 'https://huggingface.co/${model.huggingFaceRepo}/resolve/main/${model.filename}';
}
