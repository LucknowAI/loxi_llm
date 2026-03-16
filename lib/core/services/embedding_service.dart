import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';
import 'package:dart_wordpiece/dart_wordpiece.dart';

/// On-device embedding service using BGE-small-en-v1.5 INT8 ONNX.
///
/// Call [init] once before embedding. Provider handles lifecycle via [dispose].
///
/// BGE asymmetric usage:
/// - Queries:   [embedQuery]   — adds retrieval prefix automatically
/// - Passages:  [embedPassage] — no prefix (documents/chunks)
class EmbeddingService {
  OrtSession? _session;
  WordPieceTokenizer? _tokenizer;

  bool get isInitialized => _session != null && _tokenizer != null;

  static const _queryPrefix =
      'Represent this sentence for searching relevant passages: ';
  static const _modelAsset = 'assets/models/bge-small-en-v1.5-int8.onnx';
  static const _vocabAsset = 'assets/vocab.txt';

  /// Load ONNX model and vocabulary from Flutter assets.
  /// Safe to call multiple times — idempotent after first init.
  Future<void> init() async {
    if (isInitialized) return;

    OrtEnv.instance.init(level: OrtLoggingLevel.warning);

    final modelBytes =
        (await rootBundle.load(_modelAsset)).buffer.asUint8List();
    _session = OrtSession.fromBuffer(modelBytes, OrtSessionOptions());

    final vocabText = await rootBundle.loadString(_vocabAsset);
    _tokenizer = WordPieceTokenizer.fromString(vocabText);
  }

  /// Embed a search query (adds BGE retrieval prefix).
  ///
  /// Returns a 384-dimensional L2-normalized vector.
  Future<List<double>> embedQuery(String text) =>
      _embed('$_queryPrefix$text');

  /// Embed a document passage (no prefix).
  ///
  /// Returns a 384-dimensional L2-normalized vector.
  Future<List<double>> embedPassage(String text) => _embed(text);

  Future<List<double>> _embed(String text) async {
    assert(isInitialized, 'EmbeddingService.init() must be called first');
    final tokens = _tokenizer!.encode(text);
    final seqLen = tokens.length;

    final ortIds = OrtValueTensor.createTensorWithDataList(
        tokens.inputIdsInt64, [1, seqLen]);
    final ortMask = OrtValueTensor.createTensorWithDataList(
        tokens.attentionMaskInt64, [1, seqLen]);
    final ortTypes = OrtValueTensor.createTensorWithDataList(
        tokens.tokenTypeIdsInt64, [1, seqLen]);

    final runOptions = OrtRunOptions();
    final outputs = await _session!.runAsync(runOptions, {
      'input_ids': ortIds,
      'attention_mask': ortMask,
      'token_type_ids': ortTypes,
    });

    // outputs[1] = sentence_embedding [1, 384] — CLS-pooled, L2-normalized.
    // .value returns List<List<double>> for a [1, 384] float32 tensor.
    final raw = outputs![1]?.value as List;
    final embedding = (raw[0] as List).cast<double>();

    ortIds.release();
    ortMask.release();
    ortTypes.release();
    runOptions.release();
    for (final e in outputs) {
      e?.release();
    }

    return List<double>.unmodifiable(embedding);
  }

  /// Release ORT resources. Called by provider's ref.onDispose.
  void dispose() {
    _session?.release();
    _session = null;
    _tokenizer = null;
  }
}
