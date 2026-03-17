// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DocumentImpl _$$DocumentImplFromJson(Map<String, dynamic> json) =>
    _$DocumentImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      format: json['format'] as String? ?? 'txt',
      chunkCount: (json['chunkCount'] as num?)?.toInt() ?? 0,
      createdAtMs: (json['createdAtMs'] as num).toInt(),
    );

Map<String, dynamic> _$$DocumentImplToJson(_$DocumentImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'format': instance.format,
      'chunkCount': instance.chunkCount,
      'createdAtMs': instance.createdAtMs,
    };
