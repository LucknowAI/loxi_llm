import 'package:freezed_annotation/freezed_annotation.dart';
import 'model_status.dart';

part 'model.freezed.dart';
part 'model.g.dart';

@freezed
class Model with _$Model {
  const Model._();

  const factory Model({
    required String id,
    required String name,
    required String sizeLabel,
    required int sizeBytes,
    @Default(ModelStatus.available) ModelStatus status,
    @Default(0.0) double downloadProgress,
    String? localPath,
    String? huggingFaceRepo,
    String? filename,
    @Default('gguf') String format,
  }) = _Model;

  factory Model.fromJson(Map<String, dynamic> json) => _$ModelFromJson(json);

  bool get isDownloaded => status == ModelStatus.downloaded;
  bool get isDownloading => status == ModelStatus.downloading;
  bool get canLoad => status == ModelStatus.downloaded && localPath != null;
}
