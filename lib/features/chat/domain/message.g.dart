// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MessageImpl _$$MessageImplFromJson(Map<String, dynamic> json) =>
    _$MessageImpl(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      role: $enumDecode(_$MessageRoleEnumMap, json['role']),
      content: json['content'] as String,
      createdAtMs: (json['createdAtMs'] as num).toInt(),
      imagePath: json['imagePath'] as String?,
      tokenCount: (json['tokenCount'] as num?)?.toInt(),
      timeToFirstTokenMs: (json['timeToFirstTokenMs'] as num?)?.toInt(),
      totalDurationMs: (json['totalDurationMs'] as num?)?.toInt(),
      replyWaitMs: (json['replyWaitMs'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$MessageImplToJson(_$MessageImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'conversationId': instance.conversationId,
      'role': _$MessageRoleEnumMap[instance.role]!,
      'content': instance.content,
      'createdAtMs': instance.createdAtMs,
      'imagePath': instance.imagePath,
      'tokenCount': instance.tokenCount,
      'timeToFirstTokenMs': instance.timeToFirstTokenMs,
      'totalDurationMs': instance.totalDurationMs,
      'replyWaitMs': instance.replyWaitMs,
    };

const _$MessageRoleEnumMap = {
  MessageRole.user: 'user',
  MessageRole.assistant: 'assistant',
  MessageRole.system: 'system',
};
