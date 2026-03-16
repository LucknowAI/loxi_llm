import 'package:freezed_annotation/freezed_annotation.dart';
import 'message_role.dart';

part 'message.freezed.dart';
part 'message.g.dart';

@freezed
class Message with _$Message {
  const Message._();

  const factory Message({
    required String id,
    required String conversationId,
    required MessageRole role,
    required String content,
    required int createdAtMs, // DateTime.now().millisecondsSinceEpoch
  }) = _Message;

  factory Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);

  bool get isUser => role == MessageRole.user;
  bool get isAssistant => role == MessageRole.assistant;
}
