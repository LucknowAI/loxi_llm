/// Model IDs kept to plain chat: too small for reliable tool-calling
/// (Gemma 3 270M), or not yet tested with the app's tool-call format (LFM3,
/// trained on its own XML tool-call format).
const kAgentIncapableModelIds = {'gemma3-270m-it', 'lfm3-1.7b'};

/// Whether [modelId] supports the tool-calling agent loop.
///
/// Returns false when no model is loaded ([modelId] null/empty) or when the
/// model is in [kAgentIncapableModelIds].
bool isAgentCapableModel(String? modelId) {
  if (modelId == null || modelId.isEmpty) return false;
  return !kAgentIncapableModelIds.contains(modelId);
}
