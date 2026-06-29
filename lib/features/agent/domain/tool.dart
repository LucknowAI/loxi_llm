/// A capability the agent can invoke during the loop.
///
/// Implementations MUST NOT throw from [call] — on any failure return a
/// human-readable error string, which becomes the observation fed back to the
/// model so it can recover.
abstract class Tool {
  /// Unique tool name the model uses in a `tool_call`.
  String get name;

  /// One-line description shown to the model.
  String get description;

  /// JSON-schema-style description of the accepted arguments, e.g.
  /// `{'expression': 'string — the arithmetic to evaluate'}`.
  Map<String, Object?> get parameterSchema;

  /// Execute the tool. Never throws; returns the result (or an error message).
  Future<String> call(Map<String, Object?> arguments);
}

/// A parsed request from the model to run a tool.
class ToolCall {
  const ToolCall({required this.name, required this.arguments});

  final String name;
  final Map<String, Object?> arguments;

  @override
  String toString() => 'ToolCall($name, $arguments)';
}
