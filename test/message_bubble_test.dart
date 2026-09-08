import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loki_llm/features/chat/presentation/widgets/message_bubble.dart';

// Minimal valid 1x1 red PNG, used so Image.file has real bytes to decode.
const List<int> _tinyPngBytes = [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, //
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, //
  0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, //
  0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, //
  0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00, //
  0x00, 0x00, 0x03, 0x00, 0x01, 0xA0, 0x5B, 0xF3, //
  0x63, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, //
  0x44, 0xAE, 0x42, 0x60, 0x82, //
];

void main() {
  late File imageFile;

  setUp(() async {
    final dir = await Directory.systemTemp.createTemp('message_bubble_test');
    imageFile = File('${dir.path}/img-1.png')
      ..writeAsBytesSync(_tinyPngBytes);
  });

  tearDown(() async {
    if (imageFile.existsSync()) {
      await imageFile.parent.delete(recursive: true);
    }
  });

  testWidgets('renders attached image above text when imagePath is set',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MessageBubble(
            content: 'what is in this photo?',
            imagePath: imageFile.path,
            isUser: true,
            isStreaming: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsOneWidget);
    expect(find.text('what is in this photo?'), findsOneWidget);
  });

  testWidgets('renders no image when imagePath is null', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MessageBubble(
            content: 'just text',
            isUser: true,
            isStreaming: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsNothing);
    expect(find.text('just text'), findsOneWidget);
  });

  testWidgets('renders no Text widget for an image-only message (empty content)',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MessageBubble(
            content: '',
            imagePath: imageFile.path,
            isUser: true,
            isStreaming: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('falls back to a broken-image placeholder for a missing file',
      (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              content: 'gone',
              imagePath: '/does/not/exist.png',
              isUser: true,
              isStreaming: false,
            ),
          ),
        ),
      );
      // Image.file's error callback fires via a real async File read —
      // runAsync lets that real Future actually resolve before we pump.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await tester.pump();
    });

    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
  });
}
