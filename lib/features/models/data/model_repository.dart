import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/objectbox_provider.dart';
import '../../../objectbox.g.dart';
import '../domain/model.dart';
import '../domain/model_status.dart';
import 'model_entity.dart';

part 'model_repository.g.dart';

@Riverpod(keepAlive: true)
ModelRepository modelRepository(Ref ref) {
  return ModelRepository(ref.watch(modelBoxProvider));
}

class ModelRepository {
  const ModelRepository(this._box);

  final Box<ModelEntity> _box;

  List<Model> getAll() {
    return _box.getAll().map(_entityToModel).toList();
  }

  Model? getById(String modelId) {
    final query = _box.query(ModelEntity_.modelId.equals(modelId)).build();
    final entity = query.findFirst();
    query.close();
    return entity != null ? _entityToModel(entity) : null;
  }

  void save(Model model) {
    final existing = _findEntityByModelId(model.id);
    final entity = existing ?? ModelEntity();
    _updateEntity(entity, model);
    _box.put(entity);
  }

  void delete(String modelId) {
    final entity = _findEntityByModelId(modelId);
    if (entity != null) {
      _box.remove(entity.id);
    }
  }

  ModelEntity? _findEntityByModelId(String modelId) {
    final query = _box.query(ModelEntity_.modelId.equals(modelId)).build();
    final result = query.findFirst();
    query.close();
    return result;
  }

  Model _entityToModel(ModelEntity e) => Model(
        id: e.modelId,
        name: e.name,
        sizeBytes: e.sizeBytes,
        sizeLabel: e.sizeLabel,
        status: ModelStatus.values[e.statusIndex.clamp(0, ModelStatus.values.length - 1)],
        downloadProgress: e.downloadProgress,
        localPath: e.localPath,
        huggingFaceRepo: e.huggingFaceRepo,
        filename: e.filename,
        format: e.format,
        mmprojFilename: e.mmprojFilename,
        mmprojHuggingFaceRepo: e.mmprojHuggingFaceRepo,
        mmprojLocalPath: e.mmprojLocalPath,
        mmprojSizeBytes: e.mmprojSizeBytes,
      );

  void _updateEntity(ModelEntity e, Model m) {
    e.modelId = m.id;
    e.name = m.name;
    e.sizeBytes = m.sizeBytes;
    e.sizeLabel = m.sizeLabel;
    e.statusIndex = m.status.index;
    e.downloadProgress = m.downloadProgress;
    e.localPath = m.localPath;
    e.huggingFaceRepo = m.huggingFaceRepo;
    e.filename = m.filename;
    e.format = m.format;
    e.mmprojFilename = m.mmprojFilename;
    e.mmprojHuggingFaceRepo = m.mmprojHuggingFaceRepo;
    e.mmprojLocalPath = m.mmprojLocalPath;
    e.mmprojSizeBytes = m.mmprojSizeBytes;
  }
}
