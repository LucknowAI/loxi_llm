import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:objectbox/objectbox.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/chat/data/conversation_entity.dart';
import '../../features/chat/data/message_entity.dart';
import '../../features/documents/data/document_chunk_entity.dart';
import '../../features/documents/data/document_entity.dart';
import '../../features/models/data/model_entity.dart';

part 'objectbox_provider.g.dart';

/// Overridden in main() with the real Store instance.
/// keepAlive: true — store must never be disposed.
@Riverpod(keepAlive: true)
Store objectBoxStore(Ref ref) =>
    throw UnimplementedError('Must be overridden in main()');

/// Box<ModelEntity> — derived from the store.
@Riverpod(keepAlive: true)
Box<ModelEntity> modelBox(Ref ref) {
  final store = ref.watch(objectBoxStoreProvider);
  return store.box<ModelEntity>();
}

@Riverpod(keepAlive: true)
Box<ConversationEntity> conversationBox(Ref ref) {
  final store = ref.watch(objectBoxStoreProvider);
  return store.box<ConversationEntity>();
}

@Riverpod(keepAlive: true)
Box<MessageEntity> messageBox(Ref ref) {
  final store = ref.watch(objectBoxStoreProvider);
  return store.box<MessageEntity>();
}

@Riverpod(keepAlive: true)
Box<DocumentChunkEntity> documentChunkBox(Ref ref) {
  final store = ref.watch(objectBoxStoreProvider);
  return store.box<DocumentChunkEntity>();
}

@Riverpod(keepAlive: true)
Box<DocumentEntity> documentBox(Ref ref) {
  final store = ref.watch(objectBoxStoreProvider);
  return store.box<DocumentEntity>();
}
