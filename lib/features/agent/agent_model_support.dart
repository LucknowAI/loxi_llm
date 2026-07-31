/// Model IDs that are too small for reliable tool-calling (plain chat only).
const kAgentIncapableModelIds = {'gemma3-270m-it'};

/// Whether [modelId] supports the tool-calling agent loop.
///
/// Returns false when no model is loaded ([modelId] null/empty) or when the
/// model is known to be too small (e.g. Gemma 3 270M).
bool isAgentCapableModel(String? modelId) {
  if (modelId == null || modelId.isEmpty) return false;
  return !kAgentIncapableModelIds.contains(modelId);
}
