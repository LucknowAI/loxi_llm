import 'package:objectbox/objectbox.dart';

@Entity()
class ConversationEntity {
  @Id()
  int id = 0;

  @Property()
  String conversationId = '';

  @Property()
  String title = '';

  @Property()
  String systemPrompt = '';

  @Property()
  String modelId = '';

  @Property()
  int createdAtMs = 0;

  @Property()
  int updatedAtMs = 0;

  ConversationEntity();
}
