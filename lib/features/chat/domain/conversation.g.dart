// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ConversationImpl _$$ConversationImplFromJson(Map<String, dynamic> json) =>
    _$ConversationImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      systemPrompt: json['systemPrompt'] as String? ?? '',
      modelId: json['modelId'] as String? ?? '',
      createdAtMs: (json['createdAtMs'] as num).toInt(),
      updatedAtMs: (json['updatedAtMs'] as num).toInt(),
      ragEnabled: json['ragEnabled'] as bool? ?? false,
      toolsEnabled: json['toolsEnabled'] as bool? ?? false,
      summary: json['summary'] as String? ?? '',
      summarizedCount: (json['summarizedCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$ConversationImplToJson(_$ConversationImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'systemPrompt': instance.systemPrompt,
      'modelId': instance.modelId,
      'createdAtMs': instance.createdAtMs,
      'updatedAtMs': instance.updatedAtMs,
      'ragEnabled': instance.ragEnabled,
      'toolsEnabled': instance.toolsEnabled,
      'summary': instance.summary,
      'summarizedCount': instance.summarizedCount,
    };
