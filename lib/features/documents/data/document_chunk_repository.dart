import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/objectbox_provider.dart';
import '../../../objectbox.g.dart';
import '../domain/document_chunk.dart';
import 'document_chunk_entity.dart';

part 'document_chunk_repository.g.dart';

@Riverpod(keepAlive: true)
DocumentChunkRepository documentChunkRepository(Ref ref) {
  return DocumentChunkRepository(ref.watch(documentChunkBoxProvider));
}

class DocumentChunkRepository {
  const DocumentChunkRepository(this._box);

  final Box<DocumentChunkEntity> _box;

  /// Persist a batch of [chunks]. Uses putMany for efficiency.
  void saveChunks(List<DocumentChunk> chunks) {
    final entities = chunks.map(_chunkToEntity).toList();
    _box.putMany(entities);
  }

  /// Find the [topK] most similar chunks to [queryVec] using HNSW ANN search.
  ///
  /// Returns results ordered by ascending distance (closest first).
  List<DocumentChunk> findSimilar(List<double> queryVec, {int topK = 5}) {
    final query = _box
        .query(DocumentChunkEntity_.embedding
            .nearestNeighborsF32(queryVec, topK))
        .build();
    final results = query.findWithScores();
    query.close();
    return results.map((r) => _entityToChunk(r.object)).toList();
  }

  /// Delete all chunks belonging to [documentId].
  void deleteByDocumentId(String documentId) {
    final query = _box
        .query(DocumentChunkEntity_.documentId.equals(documentId))
        .build();
    final ids = query.findIds();
    query.close();
    _box.removeMany(ids);
  }

  /// Get all chunks for a document, ordered by chunkIndex ascending.
  List<DocumentChunk> getChunks(String documentId) {
    final query = _box
        .query(DocumentChunkEntity_.documentId.equals(documentId))
        .order(DocumentChunkEntity_.chunkIndex)
        .build();
    final entities = query.find();
    query.close();
    return entities.map(_entityToChunk).toList();
  }

  DocumentChunk _entityToChunk(DocumentChunkEntity e) => DocumentChunk(
        chunkId: e.chunkId,
        documentId: e.documentId,
        content: e.content,
        chunkIndex: e.chunkIndex,
        createdAtMs: e.createdAtMs,
        embedding: e.embedding,
      );

  DocumentChunkEntity _chunkToEntity(DocumentChunk c) {
    final e = DocumentChunkEntity();
    e.chunkId = c.chunkId;
    e.documentId = c.documentId;
    e.content = c.content;
    e.chunkIndex = c.chunkIndex;
    e.createdAtMs = c.createdAtMs;
    e.embedding = c.embedding;
    return e;
  }
}
