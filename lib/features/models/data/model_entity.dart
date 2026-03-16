import 'package:objectbox/objectbox.dart';

@Entity()
class ModelEntity {
  @Id()
  int id = 0;

  @Property()
  String modelId = '';

  @Property()
  String name = '';

  @Property()
  int sizeBytes = 0;

  @Property()
  String sizeLabel = '';

  @Property()
  int statusIndex = 0;

  @Property()
  double downloadProgress = 0.0;

  @Property()
  String? localPath;

  @Property()
  String? huggingFaceRepo;

  @Property()
  String? filename;

  @Property()
  String format = 'gguf';

  ModelEntity();
}
