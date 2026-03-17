import 'package:flutter_test/flutter_test.dart';
import 'package:loki_llm/features/documents/domain/document.dart';
import 'package:loki_llm/features/documents/domain/document_chunk.dart';

void main() {
  group('Document domain', () {
    test('default format is txt', () {
      const doc = Document(
        id: 'doc-1',
        name: 'notes.txt',
        createdAtMs: 0,
      );
      expect(doc.format, equals('txt'));
    });

    test('default chunkCount is 0', () {
      const doc = Document(
        id: 'doc-2',
        name: 'file.pdf',
        format: 'pdf',
        createdAtMs: 0,
      );
      expect(doc.chunkCount, equals(0));
    });

    test('copyWith updates chunkCount', () {
      const doc = Document(
        id: 'doc-3',
        name: 'file.pdf',
        format: 'pdf',
        createdAtMs: 0,
      );
      final updated = doc.copyWith(chunkCount: 42);
      expect(updated.chunkCount, equals(42));
      expect(updated.id, equals('doc-3')); // unchanged
    });

    test('copyWith updates name', () {
      const doc = Document(
        id: 'doc-4',
        name: 'old.pdf',
        format: 'pdf',
        createdAtMs: 0,
      );
      final renamed = doc.copyWith(name: 'new.pdf');
      expect(renamed.name, equals('new.pdf'));
    });
  });

  group('RAG prompt injection logic', () {
    test('chunk IDs follow doc-id prefix convention', () {
      const docId = 'doc-1234567890';
      const chunkId = 'chunk-$docId-0';
      expect(chunkId, startsWith('chunk-doc-'));
      expect(chunkId, endsWith('-0'));
    });

    test('DocumentChunk with 384-dim embedding accepted', () {
      final chunk = DocumentChunk(
        chunkId: 'chunk-doc-1-0',
        documentId: 'doc-1',
        content: 'Contract termination clause ...',
        chunkIndex: 0,
        createdAtMs: 0,
        embedding: List.filled(384, 0.01),
      );
      expect(chunk.embedding!.length, equals(384));
      expect(chunk.content, contains('termination'));
    });

    test('DocumentChunk without embedding is valid', () {
      const chunk = DocumentChunk(
        chunkId: 'chunk-doc-2-0',
        documentId: 'doc-2',
        content: 'Some text',
        chunkIndex: 0,
        createdAtMs: 0,
      );
      expect(chunk.embedding, isNull);
    });
  });
}
