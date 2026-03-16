import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/objectbox_provider.dart';
import '../../../objectbox.g.dart';
import '../domain/message.dart';
import '../domain/message_role.dart';
import 'message_entity.dart';

part 'message_repository.g.dart';

@Riverpod(keepAlive: true)
MessageRepository messageRepository(Ref ref) {
  return MessageRepository(ref.watch(messageBoxProvider));
}

class MessageRepository {
  const MessageRepository(this._box);

  final Box<MessageEntity> _box;

  /// Returns all messages for [conversationId], ordered by createdAtMs ascending.
  List<Message> getMessages(String conversationId) {
    final query = _box
        .query(MessageEntity_.conversationId.equals(conversationId))
        .order(MessageEntity_.createdAtMs)
        .build();
    final entities = query.find();
    query.close();
    return entities.map(_entityToMessage).toList();
  }

  void save(Message message) {
    final existing = _findEntityByMessageId(message.id);
    final entity = existing ?? MessageEntity();
    _updateEntity(entity, message);
    _box.put(entity);
  }

  void deleteByConversationId(String conversationId) {
    final query = _box
        .query(MessageEntity_.conversationId.equals(conversationId))
        .build();
    final ids = query.findIds();
    query.close();
    _box.removeMany(ids);
  }

  MessageEntity? _findEntityByMessageId(String messageId) {
    final query =
        _box.query(MessageEntity_.messageId.equals(messageId)).build();
    final result = query.findFirst();
    query.close();
    return result;
  }

  Message _entityToMessage(MessageEntity e) => Message(
        id: e.messageId,
        conversationId: e.conversationId,
        role: MessageRole.values.firstWhere(
          (r) => r.name == e.role,
          orElse: () => MessageRole.user,
        ),
        content: e.content,
        createdAtMs: e.createdAtMs,
      );

  void _updateEntity(MessageEntity e, Message m) {
    e.messageId = m.id;
    e.conversationId = m.conversationId;
    e.role = m.role.name;
    e.content = m.content;
    e.createdAtMs = m.createdAtMs;
  }
}
