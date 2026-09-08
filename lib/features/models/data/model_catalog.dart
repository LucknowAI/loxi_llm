import '../domain/model.dart';

/// Curated models shown to users on first launch.
/// These are seeded into ObjectBox when the DB is empty.
const List<Model> kCuratedModels = [
  Model(
    id: 'gemma3-270m-it',
    name: 'Gemma 3 270M IT',
    sizeLabel: '253 MB',
    sizeBytes: 265289728,
    format: 'gguf',
    huggingFaceRepo: 'unsloth/gemma-3-270m-it-GGUF',
    filename: 'gemma-3-270m-it-Q4_K_M.gguf',
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
  Model(
    id: 'gemma4-e2b-it',
    name: 'Gemma 4 E2B IT (Vision)',
    sizeLabel: '3.11 GB',
    sizeBytes: 3106738272,
    format: 'gguf',
    huggingFaceRepo: 'unsloth/gemma-4-E2B-it-GGUF',
    filename: 'gemma-4-E2B-it-Q4_K_M.gguf',
    mmprojFilename: 'mmproj-F16.gguf',
    mmprojHuggingFaceRepo: 'unsloth/gemma-4-E2B-it-GGUF',
    mmprojSizeBytes: 985654080,
  ),
  Model(
    id: 'gemma4-e4b-it',
    name: 'Gemma 4 E4B IT (Vision)',
    sizeLabel: '4.98 GB',
    sizeBytes: 4977171584,
    format: 'gguf',
    huggingFaceRepo: 'unsloth/gemma-4-E4B-it-GGUF',
    filename: 'gemma-4-E4B-it-Q4_K_M.gguf',
    mmprojFilename: 'mmproj-F16.gguf',
    mmprojHuggingFaceRepo: 'unsloth/gemma-4-E4B-it-GGUF',
    mmprojSizeBytes: 990372672,
  ),
];

/// Compute HuggingFace download URL from model metadata.
String huggingFaceDownloadUrl(Model model) {
  assert(model.huggingFaceRepo != null && model.filename != null,
      'Model ${model.id} is missing huggingFaceRepo or filename');
  return 'https://huggingface.co/${model.huggingFaceRepo}/resolve/main/${model.filename}';
}

/// Compute the HuggingFace download URL for [model]'s mmproj (vision
/// projector) companion file, or `null` if it has none.
String? huggingFaceMmprojDownloadUrl(Model model) {
  final repo = model.mmprojHuggingFaceRepo;
  final filename = model.mmprojFilename;
  if (repo == null || filename == null) return null;
  return 'https://huggingface.co/$repo/resolve/main/$filename';
}
