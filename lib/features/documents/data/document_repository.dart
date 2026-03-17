import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/objectbox_provider.dart';
import '../../../objectbox.g.dart';
import '../domain/document.dart';
import 'document_entity.dart';

part 'document_repository.g.dart';

@Riverpod(keepAlive: true)
DocumentRepository documentRepository(Ref ref) {
  return DocumentRepository(ref.watch(documentBoxProvider));
}

class DocumentRepository {
  const DocumentRepository(this._box);
  final Box<DocumentEntity> _box;

  List<Document> getAll() {
    final query = _box
        .query()
        .order(DocumentEntity_.createdAtMs, flags: Order.descending)
        .build();
    final entities = query.find();
    query.close();
    return entities.map(_entityToDocument).toList();
  }

  void save(Document doc) {
    final existing = _findEntityById(doc.id);
    if (existing != null) {
      existing.name = doc.name;
      existing.format = doc.format;
      existing.chunkCount = doc.chunkCount;
      _box.put(existing);
    } else {
      _box.put(_documentToEntity(doc));
    }
  }

  void delete(String documentId) {
    final query = _box
        .query(DocumentEntity_.documentId.equals(documentId))
        .build();
    final ids = query.findIds();
    query.close();
    _box.removeMany(ids);
  }

  DocumentEntity? _findEntityById(String documentId) {
    final query = _box
        .query(DocumentEntity_.documentId.equals(documentId))
        .build();
    final entities = query.find();
    query.close();
    return entities.isEmpty ? null : entities.first;
  }

  Document _entityToDocument(DocumentEntity e) => Document(
        id: e.documentId,
        name: e.name,
        format: e.format,
        chunkCount: e.chunkCount,
        createdAtMs: e.createdAtMs,
      );

  DocumentEntity _documentToEntity(Document d) {
    final e = DocumentEntity();
    e.documentId = d.id;
    e.name = d.name;
    e.format = d.format;
    e.chunkCount = d.chunkCount;
    e.createdAtMs = d.createdAtMs;
    return e;
  }
}
