import 'package:flutter_test/flutter_test.dart';
import 'package:loki_llm/core/logging/model_io_logger.dart';
import 'package:loki_llm/core/logging/model_io_trace.dart';

ModelIoTrace _sampleTrace({
  TraceOutcome outcome = TraceOutcome.done,
  String? error,
}) =>
    ModelIoTrace(
      timestampMs: 1700000000000,
      conversationId: 'conv-1',
      modelName: 'gemma-3-270m-it',
      backendType: 'LlamaCppBackend',
      inputPrompt: 'Human: hi\nAssistant: ',
      generationParams: const {'temperature': 0.7, 'maxTokens': 512},
      ragEnabled: true,
      ragChunks: const ['chunk one', 'chunk two'],
      outputText: 'Hello there!',
      tokenCount: 3,
      timeToFirstTokenMs: 120,
      totalDurationMs: 800,
      outcome: outcome,
      error: error,
    );

void main() {
  group('ModelIoTrace serialization', () {
    test('round-trips through JSON', () {
      final original = _sampleTrace();
      final restored = ModelIoTrace.fromJson(original.toJson());

      expect(restored.timestampMs, original.timestampMs);
      expect(restored.conversationId, original.conversationId);
      expect(restored.modelName, original.modelName);
      expect(restored.backendType, original.backendType);
      expect(restored.inputPrompt, original.inputPrompt);
      expect(restored.generationParams, original.generationParams);
      expect(restored.ragEnabled, isTrue);
      expect(restored.ragChunks, original.ragChunks);
      expect(restored.outputText, original.outputText);
      expect(restored.tokenCount, 3);
      expect(restored.timeToFirstTokenMs, 120);
      expect(restored.totalDurationMs, 800);
      expect(restored.outcome, TraceOutcome.done);
    });

    test('round-trips an error outcome with a null TTFT', () {
      const original = ModelIoTrace(
        timestampMs: 1,
        conversationId: 'c',
        modelName: 'm',
        backendType: 'b',
        inputPrompt: 'p',
        generationParams: {},
        ragEnabled: false,
        ragChunks: [],
        outputText: '',
        tokenCount: 0,
        timeToFirstTokenMs: null,
        totalDurationMs: 50,
        outcome: TraceOutcome.error,
        error: 'boom',
      );
      final restored =
          ModelIoTrace.fromJson(original.toJson());
      expect(restored.outcome, TraceOutcome.error);
      expect(restored.error, 'boom');
      expect(restored.timeToFirstTokenMs, isNull);
      expect(restored.ragChunkCount, 0);
    });

    test('tryParseLine returns null on malformed input', () {
      expect(ModelIoTrace.tryParseLine(''), isNull);
      expect(ModelIoTrace.tryParseLine('not json'), isNull);
      expect(ModelIoTrace.tryParseLine(_sampleTrace().toJsonLine()), isNotNull);
    });
  });

  group('ModelIoLogger gating', () {
    test('record is a no-op when disabled', () {
      final logger = ModelIoLogger.instance;
      logger.enabled = false;
      // No file init in tests; record must not throw and must not buffer.
      final before = logger.entries.length;
      logger.record(_sampleTrace());
      expect(logger.entries.length, before);
    });

    test('record buffers when enabled', () {
      final logger = ModelIoLogger.instance;
      logger.enabled = true;
      final before = logger.entries.length;
      logger.record(_sampleTrace());
      expect(logger.entries.length, before + 1);
      logger.enabled = false; // restore
    });
  });
}
