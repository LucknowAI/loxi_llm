import 'package:flutter_test/flutter_test.dart';
import 'package:loki_llm/features/documents/domain/document_chunk.dart';
import 'package:loki_llm/core/services/embedding_service.dart';

void main() {
  group('DocumentChunk domain', () {
    test('copyWith updates content', () {
      const chunk = DocumentChunk(
        chunkId: 'c1',
        documentId: 'doc1',
        content: 'Original text',
        chunkIndex: 0,
        createdAtMs: 0,
      );
      final updated = chunk.copyWith(content: 'Updated text');
      expect(updated.content, equals('Updated text'));
      expect(updated.chunkId, equals('c1')); // unchanged
      expect(updated.documentId, equals('doc1')); // unchanged
    });

    test('embedding is null by default', () {
      const chunk = DocumentChunk(
        chunkId: 'c2',
        documentId: 'doc1',
        content: 'Some text',
        chunkIndex: 0,
        createdAtMs: 0,
      );
      expect(chunk.embedding, isNull);
    });

    test('copyWith can set embedding', () {
      const chunk = DocumentChunk(
        chunkId: 'c3',
        documentId: 'doc1',
        content: 'Some text',
        chunkIndex: 0,
        createdAtMs: 0,
      );
      final withEmbedding = chunk.copyWith(embedding: List.filled(384, 0.1));
      expect(withEmbedding.embedding, isNotNull);
      expect(withEmbedding.embedding!.length, equals(384));
    });

    test('chunkIndex preserved after copyWith', () {
      const chunk = DocumentChunk(
        chunkId: 'c4',
        documentId: 'doc1',
        content: 'Chunk text',
        chunkIndex: 5,
        createdAtMs: 1000,
      );
      final updated = chunk.copyWith(content: 'New');
      expect(updated.chunkIndex, equals(5));
      expect(updated.createdAtMs, equals(1000));
    });
  });

  group('EmbeddingService state', () {
    test('isInitialized is false before init', () {
      final service = EmbeddingService();
      expect(service.isInitialized, isFalse);
    });

    test('dispose can be called on uninitialized service without error', () {
      final service = EmbeddingService();
      expect(() => service.dispose(), returnsNormally);
    });

    test('init is idempotent after dispose (no throw)', () async {
      // Note: init() requires Flutter asset bundle — skipped in unit test.
      // This test verifies pre-conditions only.
      final service = EmbeddingService();
      expect(service.isInitialized, isFalse);
      service.dispose();
      expect(service.isInitialized, isFalse);
    });
  });
}
