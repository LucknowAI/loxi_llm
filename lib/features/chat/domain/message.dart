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
    String? imagePath,

    /// Same model-call numbers as the Model I/O log line for this reply.
    /// Null on older messages and on user turns.
    int? tokenCount,
    int? timeToFirstTokenMs,
    int? totalDurationMs,

    /// Send until the reply was saved, including a summary or tool calls.
    /// [totalDurationMs] stays the model call, which is what tok/s uses.
    int? replyWaitMs,
  }) = _Message;

  factory Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);

  bool get isUser => role == MessageRole.user;
  bool get isAssistant => role == MessageRole.assistant;
}
