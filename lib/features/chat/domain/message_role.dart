import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum MessageRole {
  @JsonValue('user')
  user,
  @JsonValue('assistant')
  assistant,
  @JsonValue('system')
  system,
}
