import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/objectbox_provider.dart';
import '../../../objectbox.g.dart';
import '../domain/conversation.dart';
import 'conversation_entity.dart';

part 'conversation_repository.g.dart';

@Riverpod(keepAlive: true)
ConversationRepository conversationRepository(Ref ref) {
  return ConversationRepository(ref.watch(conversationBoxProvider));
}

class ConversationRepository {
  const ConversationRepository(this._box);

  final Box<ConversationEntity> _box;

  List<Conversation> getAll() {
    return _box
        .query()
        .order(ConversationEntity_.updatedAtMs, flags: Order.descending)
        .build()
        .find()
        .map(_entityToConversation)
        .toList();
  }

  Conversation? getById(String conversationId) {
    final query = _box
        .query(ConversationEntity_.conversationId.equals(conversationId))
        .build();
    final entity = query.findFirst();
    query.close();
    return entity != null ? _entityToConversation(entity) : null;
  }

  void save(Conversation conversation) {
    final existing = _findEntityById(conversation.id);
    final entity = existing ?? ConversationEntity();
    _updateEntity(entity, conversation);
    _box.put(entity);
  }

  void delete(String conversationId) {
    final entity = _findEntityById(conversationId);
    if (entity != null) _box.remove(entity.id);
  }

  ConversationEntity? _findEntityById(String conversationId) {
    final query = _box
        .query(ConversationEntity_.conversationId.equals(conversationId))
        .build();
    final result = query.findFirst();
    query.close();
    return result;
  }

  Conversation _entityToConversation(ConversationEntity e) => Conversation(
        id: e.conversationId,
        title: e.title,
        systemPrompt: e.systemPrompt,
        modelId: e.modelId,
        createdAtMs: e.createdAtMs,
        updatedAtMs: e.updatedAtMs,
        ragEnabled: e.ragEnabled,
        toolsEnabled: e.toolsEnabled,
        summary: e.summary,
        summarizedCount: e.summarizedCount,
      );

  void _updateEntity(ConversationEntity e, Conversation c) {
    e.conversationId = c.id;
    e.title = c.title;
    e.systemPrompt = c.systemPrompt;
    e.modelId = c.modelId;
    e.createdAtMs = c.createdAtMs;
    e.updatedAtMs = c.updatedAtMs;
    e.ragEnabled = c.ragEnabled;
    e.toolsEnabled = c.toolsEnabled;
    e.summary = c.summary;
    e.summarizedCount = c.summarizedCount;
  }
}
