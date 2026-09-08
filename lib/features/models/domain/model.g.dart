// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ModelImpl _$$ModelImplFromJson(Map<String, dynamic> json) => _$ModelImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      sizeLabel: json['sizeLabel'] as String,
      sizeBytes: (json['sizeBytes'] as num).toInt(),
      status: $enumDecodeNullable(_$ModelStatusEnumMap, json['status']) ??
          ModelStatus.available,
      downloadProgress: (json['downloadProgress'] as num?)?.toDouble() ?? 0.0,
      localPath: json['localPath'] as String?,
      huggingFaceRepo: json['huggingFaceRepo'] as String?,
      filename: json['filename'] as String?,
      format: json['format'] as String? ?? 'gguf',
      mmprojFilename: json['mmprojFilename'] as String?,
      mmprojHuggingFaceRepo: json['mmprojHuggingFaceRepo'] as String?,
      mmprojLocalPath: json['mmprojLocalPath'] as String?,
      mmprojSizeBytes: (json['mmprojSizeBytes'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$ModelImplToJson(_$ModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'sizeLabel': instance.sizeLabel,
      'sizeBytes': instance.sizeBytes,
      'status': _$ModelStatusEnumMap[instance.status]!,
      'downloadProgress': instance.downloadProgress,
      'localPath': instance.localPath,
      'huggingFaceRepo': instance.huggingFaceRepo,
      'filename': instance.filename,
      'format': instance.format,
      'mmprojFilename': instance.mmprojFilename,
      'mmprojHuggingFaceRepo': instance.mmprojHuggingFaceRepo,
      'mmprojLocalPath': instance.mmprojLocalPath,
      'mmprojSizeBytes': instance.mmprojSizeBytes,
    };

const _$ModelStatusEnumMap = {
  ModelStatus.available: 'available',
  ModelStatus.downloading: 'downloading',
  ModelStatus.paused: 'paused',
  ModelStatus.downloaded: 'downloaded',
  ModelStatus.loading: 'loading',
  ModelStatus.loaded: 'loaded',
  ModelStatus.error: 'error',
};
