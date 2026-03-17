import 'package:objectbox/objectbox.dart';

@Entity()
class DocumentEntity {
  @Id()
  int id = 0;

  @Property()
  String documentId = '';

  @Property()
  String name = '';

  /// File format: pdf | docx | txt
  @Property()
  String format = '';

  @Property()
  int chunkCount = 0;

  @Property()
  int createdAtMs = 0;

  DocumentEntity(); // no-arg constructor REQUIRED by ObjectBox
}
