import 'dart:convert';

/// How a generation finished.
enum TraceOutcome { done, error, timeout, stopped }

extension TraceOutcomeLabel on TraceOutcome {
  String get label => switch (this) {
        TraceOutcome.done => 'done',
        TraceOutcome.error => 'error',
        TraceOutcome.timeout => 'timeout',
        TraceOutcome.stopped => 'stopped',
      };

  static TraceOutcome parse(String? value) => switch (value) {
        'error' => TraceOutcome.error,
        'timeout' => TraceOutcome.timeout,
        'stopped' => TraceOutcome.stopped,
        _ => TraceOutcome.done,
      };
}

/// A full record of one model input/output exchange, captured only when the
/// "Model I/O logging" setting is enabled. Serialized one-per-line as JSONL.
class ModelIoTrace {
  const ModelIoTrace({
    required this.timestampMs,
    required this.conversationId,
    required this.modelName,
    required this.backendType,
    required this.inputPrompt,
    required this.generationParams,
    required this.ragEnabled,
    required this.ragChunks,
    required this.outputText,
    required this.tokenCount,
    required this.timeToFirstTokenMs,
    required this.totalDurationMs,
    required this.outcome,
    this.error,
  });

  final int timestampMs;
  final String conversationId;
  final String modelName;
  final String backendType;

  /// The exact prompt string handed to the backend.
  final String inputPrompt;

  /// Generation parameters reported by the backend (temp, maxTokens, ...).
  final Map<String, Object?> generationParams;

  final bool ragEnabled;

  /// Text of the RAG chunks injected into the prompt (empty when none).
  final List<String> ragChunks;

  /// The full generated response.
  final String outputText;
  final int tokenCount;

  /// Milliseconds from invoking the backend to the first streamed token, or
  /// null if no token was produced.
  final int? timeToFirstTokenMs;
  final int totalDurationMs;

  final TraceOutcome outcome;

  /// Error description when [outcome] is not [TraceOutcome.done].
  final String? error;

  int get ragChunkCount => ragChunks.length;

  Map<String, Object?> toJson() => {
        'timestampMs': timestampMs,
        'conversationId': conversationId,
        'modelName': modelName,
        'backendType': backendType,
        'inputPrompt': inputPrompt,
        'generationParams': generationParams,
        'ragEnabled': ragEnabled,
        'ragChunks': ragChunks,
        'outputText': outputText,
        'tokenCount': tokenCount,
        'timeToFirstTokenMs': timeToFirstTokenMs,
        'totalDurationMs': totalDurationMs,
        'outcome': outcome.label,
        'error': error,
      };

  factory ModelIoTrace.fromJson(Map<String, Object?> json) => ModelIoTrace(
        timestampMs: (json['timestampMs'] as num?)?.toInt() ?? 0,
        conversationId: json['conversationId'] as String? ?? '',
        modelName: json['modelName'] as String? ?? 'unknown',
        backendType: json['backendType'] as String? ?? 'unknown',
        inputPrompt: json['inputPrompt'] as String? ?? '',
        generationParams:
            (json['generationParams'] as Map?)?.cast<String, Object?>() ??
                const {},
        ragEnabled: json['ragEnabled'] as bool? ?? false,
        ragChunks: (json['ragChunks'] as List?)?.cast<String>() ?? const [],
        outputText: json['outputText'] as String? ?? '',
        tokenCount: (json['tokenCount'] as num?)?.toInt() ?? 0,
        timeToFirstTokenMs: (json['timeToFirstTokenMs'] as num?)?.toInt(),
        totalDurationMs: (json['totalDurationMs'] as num?)?.toInt() ?? 0,
        outcome: TraceOutcomeLabel.parse(json['outcome'] as String?),
        error: json['error'] as String?,
      );

  /// One-line JSON for the .jsonl file.
  String toJsonLine() => jsonEncode(toJson());

  /// Parse a single JSONL line, or null if malformed.
  static ModelIoTrace? tryParseLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return null;
    try {
      return ModelIoTrace.fromJson(
        jsonDecode(trimmed) as Map<String, Object?>,
      );
    } catch (_) {
      return null;
    }
  }
}
