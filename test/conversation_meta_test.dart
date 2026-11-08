import 'package:flutter_test/flutter_test.dart';
import 'package:loki_llm/features/chat/presentation/chat_screen.dart';

void main() {
  test('conversation meta names the model and skips a missing one', () {
    final now = DateTime(2026, 11, 6, 12);
    final tenMinutesAgo = now.subtract(const Duration(minutes: 10));
    expect(
      conversationMeta(
        modelName: 'Gemma 3 270M IT',
        updatedAtMs: tenMinutesAgo.millisecondsSinceEpoch,
        now: now,
      ),
      'Gemma 3 270M IT · 10m ago',
    );
    expect(
      conversationMeta(
        modelName: '',
        updatedAtMs: tenMinutesAgo.millisecondsSinceEpoch,
        now: now,
      ),
      '10m ago',
    );
  });
}
