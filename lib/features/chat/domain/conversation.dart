import 'package:freezed_annotation/freezed_annotation.dart';

part 'conversation.freezed.dart';
part 'conversation.g.dart';

@freezed
class Conversation with _$Conversation {
  const Conversation._();

  const factory Conversation({
    required String id,
    required String title,
    @Default('') String systemPrompt,
    @Default('') String modelId,
    required int createdAtMs,
    required int updatedAtMs,
    @Default(false) bool ragEnabled,
    @Default(false) bool toolsEnabled,
    @Default('') String summary,
    @Default(0) int summarizedCount,
  }) = _Conversation;

  factory Conversation.fromJson(Map<String, dynamic> json) =>
      _$ConversationFromJson(json);
}
