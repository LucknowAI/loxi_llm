import 'package:objectbox/objectbox.dart';

@Entity()
class MessageEntity {
  @Id()
  int id = 0;

  @Index()
  @Property()
  String conversationId = '';

  @Property()
  String messageId = '';

  @Property()
  String role = ''; // 'user' | 'assistant' | 'system'

  @Property()
  String content = '';

  @Property()
  int createdAtMs = 0;

  @Property()
  String? imagePath;

  MessageEntity();
}
