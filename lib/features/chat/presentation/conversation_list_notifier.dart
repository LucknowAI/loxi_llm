import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/conversation_repository.dart';
import '../data/message_repository.dart';
import '../domain/conversation.dart';

part 'conversation_list_notifier.g.dart';

@riverpod
class ConversationListNotifier extends _$ConversationListNotifier {
  @override
  Future<List<Conversation>> build() async {
    return ref.watch(conversationRepositoryProvider).getAll();
  }

  /// Creates a new conversation and returns its ID.
  String createConversation({String systemPrompt = '', String modelId = ''}) {
    final id = 'conv-${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now().millisecondsSinceEpoch;
    final conversation = Conversation(
      id: id,
      title: 'New conversation',
      systemPrompt: systemPrompt,
      modelId: modelId,
      createdAtMs: now,
      updatedAtMs: now,
    );
    ref.read(conversationRepositoryProvider).save(conversation);
    ref.invalidateSelf();
    return id;
  }

  void updateTitle(String conversationId, String title) {
    final repo = ref.read(conversationRepositoryProvider);
    final conversation = repo.getById(conversationId);
    if (conversation == null) return;
    repo.save(conversation.copyWith(
      title: title,
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
    ));
    ref.invalidateSelf();
  }

  void updateSystemPrompt(String conversationId, String systemPrompt) {
    final repo = ref.read(conversationRepositoryProvider);
    final conversation = repo.getById(conversationId);
    if (conversation == null) return;
    repo.save(conversation.copyWith(systemPrompt: systemPrompt));
    ref.invalidateSelf();
  }

  void toggleRagEnabled(String conversationId) {
    final repo = ref.read(conversationRepositoryProvider);
    final conversation = repo.getById(conversationId);
    if (conversation == null) return;
    repo.save(conversation.copyWith(ragEnabled: !conversation.ragEnabled));
    ref.invalidateSelf();
  }

  void deleteConversation(String conversationId) {
    ref.read(messageRepositoryProvider).deleteByConversationId(conversationId);
    ref.read(conversationRepositoryProvider).delete(conversationId);
    ref.invalidateSelf();
  }
}
