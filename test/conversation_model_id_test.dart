import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:loki_llm/core/engine/inference_backend.dart';
import 'package:loki_llm/core/providers/inference_provider.dart';
import 'package:loki_llm/core/providers/shared_preferences_provider.dart';
import 'package:loki_llm/features/chat/data/conversation_repository.dart';
import 'package:loki_llm/features/chat/data/message_repository.dart';
import 'package:loki_llm/features/chat/domain/conversation.dart';
import 'package:loki_llm/features/chat/domain/message.dart';
import 'package:loki_llm/features/chat/presentation/chat_notifier.dart';
import 'package:loki_llm/features/chat/presentation/chat_screen.dart';
import 'package:loki_llm/features/chat/presentation/conversation_list_notifier.dart';
import 'package:loki_llm/features/models/domain/model.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _phi3 = Model(
  id: 'phi3-mini-4k-q4km',
  name: 'Phi-3 Mini',
  sizeLabel: '2 GB',
  sizeBytes: 1,
);

void main() {
  group('Conversation model id', () {
    Future<ProviderContainer> openContainer({
      InferenceBackend? backend,
      Model? loaded,
    }) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          conversationRepositoryProvider.overrideWith(
            (ref) => _MemoryConversations(),
          ),
          messageRepositoryProvider.overrideWith((ref) => _MemoryMessages()),
          inferenceNotifierProvider.overrideWith(
            () => _FixedInference(backend: backend, loaded: loaded),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(inferenceNotifierProvider.future);
      return container;
    }

    String? storedModelId(ProviderContainer container, String id) {
      return container
          .read(conversationRepositoryProvider)
          .getById(id)
          ?.modelId;
    }

    testWidgets('a new chat stores the loaded model id', (tester) async {
      final container = await openContainer(
        backend: _ReadyBackend(),
        loaded: _phi3,
      );
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, __) => const ChatScreen()),
          GoRoute(
            path: '/chat/:id',
            builder: (_, __) => const SizedBox.shrink(),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('New Chat'));
      await tester.pumpAndSettle();

      final stored = container.read(conversationRepositoryProvider).getAll();
      expect(stored, hasLength(1));
      expect(stored.single.modelId, _phi3.id);
    });

    test('send stores the answering model when generation fails', () async {
      final container = await openContainer(backend: _ErrorBackend());
      final id = container
          .read(conversationListNotifierProvider.notifier)
          .createConversation();
      container.read(inferenceNotifierProvider.notifier).loadedModel = _phi3;
      final sub = container.listen(chatNotifierProvider(id), (_, __) {});
      addTearDown(sub.close);
      final notifier = container.read(chatNotifierProvider(id).notifier);
      await container.read(chatNotifierProvider(id).future);

      await notifier.send('hi');
      final chat = await _idleChat(container, id);

      expect(chat.error, isNotNull);
      expect(storedModelId(container, id), _phi3.id);
    });

    test('send stores the answering model when the reply is stopped', () async {
      final container = await openContainer(backend: _HoldBackend());
      final id = container
          .read(conversationListNotifierProvider.notifier)
          .createConversation();
      container.read(inferenceNotifierProvider.notifier).loadedModel = _phi3;
      final sub = container.listen(chatNotifierProvider(id), (_, __) {});
      addTearDown(sub.close);
      final notifier = container.read(chatNotifierProvider(id).notifier);
      await container.read(chatNotifierProvider(id).future);

      await notifier.send('hi');
      await notifier.stop();
      final chat = await _idleChat(container, id);

      expect(chat.error, isNull);
      expect(storedModelId(container, id), _phi3.id);
    });
  });
}

Future<ChatState> _idleChat(ProviderContainer container, String id) async {
  for (var i = 0; i < 20; i++) {
    final chat = container.read(chatNotifierProvider(id)).valueOrNull;
    if (chat != null && !chat.isStreaming) return chat;
    await Future<void>.delayed(Duration.zero);
  }
  fail('chat did not finish');
}

class _FixedInference extends InferenceNotifier {
  _FixedInference({this.backend, this.loaded});

  final InferenceBackend? backend;
  final Model? loaded;

  @override
  Future<InferenceBackend?> build() async {
    loadedModel = loaded;
    return backend;
  }
}

final class _MemoryConversations implements ConversationRepository {
  final _items = <String, Conversation>{};

  @override
  List<Conversation> getAll() => _items.values.toList();

  @override
  Conversation? getById(String conversationId) => _items[conversationId];

  @override
  void save(Conversation conversation) =>
      _items[conversation.id] = conversation;

  @override
  void delete(String conversationId) => _items.remove(conversationId);
}

final class _MemoryMessages implements MessageRepository {
  final _items = <String, Message>{};

  @override
  List<Message> getMessages(String conversationId) {
    final messages = _items.values
        .where((message) => message.conversationId == conversationId)
        .toList()
      ..sort((a, b) => a.createdAtMs.compareTo(b.createdAtMs));
    return messages;
  }

  @override
  void save(Message message) => _items[message.id] = message;

  @override
  void deleteByConversationId(String conversationId) {
    _items
        .removeWhere((_, message) => message.conversationId == conversationId);
  }
}

final class _ReadyBackend extends InferenceBackend {
  @override
  bool get isLoaded => true;
}

final class _ErrorBackend extends InferenceBackend {
  @override
  bool get isLoaded => true;

  @override
  Stream<String> generate(
    String prompt, {
    List<String> stopSequences = const [],
    String? grammar,
    List<String> imagePaths = const [],
    int maxTokens = 512,
    double temperature = 0.7,
    int topK = 40,
    double topP = 0.95,
    double repeatPenalty = 1.1,
  }) =>
      Stream.error(StateError('failed'));
}

final class _HoldBackend extends InferenceBackend {
  final _gate = Completer<void>();

  @override
  bool get isLoaded => true;

  @override
  Future<void> stop() async {
    if (!_gate.isCompleted) _gate.complete();
  }

  @override
  Stream<String> generate(
    String prompt, {
    List<String> stopSequences = const [],
    String? grammar,
    List<String> imagePaths = const [],
    int maxTokens = 512,
    double temperature = 0.7,
    int topK = 40,
    double topP = 0.95,
    double repeatPenalty = 1.1,
  }) async* {
    await _gate.future;
  }
}
