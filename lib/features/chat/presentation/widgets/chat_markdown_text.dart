import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

/// Shared Markdown paint for chat bubbles and conversation-list titles.
class ChatMarkdownText extends StatelessWidget {
  const ChatMarkdownText(
    this.data, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.isStreaming = false,
    this.inlineOnly = false,
  });

  final String data;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool isStreaming;

  /// Skip headings/fences/lists (conversation-list titles).
  final bool inlineOnly;

  @override
  Widget build(BuildContext context) {
    return GptMarkdown(
      data,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
      animation:
          isStreaming ? GptMarkdownAnimation.fade : GptMarkdownAnimation.none,
      isStreaming: isStreaming,
      components: inlineOnly ? MarkdownComponent.inlineComponents : null,
    );
  }
}
