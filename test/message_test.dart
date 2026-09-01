import 'package:flutter_test/flutter_test.dart';
import 'package:loki_llm/features/chat/domain/message.dart';
import 'package:loki_llm/features/chat/domain/message_role.dart';

void main() {
  group('Message imagePath', () {
    test('defaults to null', () {
      const message = Message(
        id: 'msg-1',
        conversationId: 'conv-1',
        role: MessageRole.user,
        content: 'hello',
        createdAtMs: 0,
      );
      expect(message.imagePath, isNull);
    });

    test('round-trips through the constructor', () {
      const message = Message(
        id: 'msg-1',
        conversationId: 'conv-1',
        role: MessageRole.user,
        content: 'what is in this photo?',
        createdAtMs: 0,
        imagePath: '/data/user/0/dev.lokillm/app_flutter/images/img-1.jpg',
      );
      expect(
        message.imagePath,
        '/data/user/0/dev.lokillm/app_flutter/images/img-1.jpg',
      );
    });

    test('copyWith preserves imagePath when not overridden', () {
      const message = Message(
        id: 'msg-1',
        conversationId: 'conv-1',
        role: MessageRole.user,
        content: 'hello',
        createdAtMs: 0,
        imagePath: '/tmp/a.jpg',
      );
      final copy = message.copyWith(content: 'updated');
      expect(copy.imagePath, '/tmp/a.jpg');
    });
  });
}
