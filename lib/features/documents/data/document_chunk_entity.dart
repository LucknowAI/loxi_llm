import 'package:objectbox/objectbox.dart';

@Entity()
class DocumentChunkEntity {
  @Id()
  int id = 0;

  @Index()
  @Property()
  String documentId = ''; // FK to document — @Index() for fast equals() queries

  @Property()
  String chunkId = '';

  @Property()
  String content = '';

  @Property()
  int chunkIndex = 0;

  @Property()
  int createdAtMs = 0;

  /// 384-dimensional BGE-small-en-v1.5 embedding vector.
  /// BOTH annotations are REQUIRED together.
  @HnswIndex(dimensions: 384)
  @Property(type: PropertyType.floatVector)
  List<double>? embedding;

  DocumentChunkEntity(); // no-arg constructor REQUIRED by ObjectBox
}
