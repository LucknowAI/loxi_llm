/// A single text chunk from an ingested document, optionally with its embedding.
class DocumentChunk {
  const DocumentChunk({
    required this.chunkId,
    required this.documentId,
    required this.content,
    required this.chunkIndex,
    required this.createdAtMs,
    this.embedding,
  });

  final String chunkId;
  final String documentId;
  final String content;
  final int chunkIndex;
  final int createdAtMs;

  /// 384-dim BGE-small embedding vector. Null if not yet embedded.
  final List<double>? embedding;

  DocumentChunk copyWith({
    String? chunkId,
    String? documentId,
    String? content,
    int? chunkIndex,
    int? createdAtMs,
    List<double>? embedding,
  }) {
    return DocumentChunk(
      chunkId: chunkId ?? this.chunkId,
      documentId: documentId ?? this.documentId,
      content: content ?? this.content,
      chunkIndex: chunkIndex ?? this.chunkIndex,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      embedding: embedding ?? this.embedding,
    );
  }
}
