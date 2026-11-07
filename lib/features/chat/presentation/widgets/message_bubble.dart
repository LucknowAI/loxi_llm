import 'package:flutter/material.dart';

import 'chat_markdown_text.dart';
import 'image_attachment_thumbnail.dart';

/// Speed and wait for the bottom row of a finished reply.
///
/// [speed] is the model call. [time] is the whole wait from send.
({String? speed, String time})? replyStats({
  required int? tokenCount,
  required int? totalDurationMs,
  required int? timeToFirstTokenMs,
  int? replyWaitMs,
}) {
  final shownMs = replyWaitMs ?? totalDurationMs;
  if (shownMs == null) return null;
  final time = '${(shownMs / 1000).toStringAsFixed(1)} s';
  final speedMs = totalDurationMs;
  if (tokenCount == null ||
      timeToFirstTokenMs == null ||
      speedMs == null ||
      tokenCount < 2) {
    return (speed: null, time: time);
  }
  final decodeMs = speedMs - timeToFirstTokenMs;
  if (decodeMs <= 0) return (speed: null, time: time);
  final tps = (tokenCount - 1) * 1000 / decodeMs;
  return (speed: '${tps.toStringAsFixed(1)} tok/s', time: time);
}

/// A single chat message bubble with optional copy / read-aloud actions.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    this.content,
    this.child,
    this.imagePath,
    required this.isUser,
    required this.isStreaming,
    this.onCopy,
    this.onReadAloud,
    this.isSpeaking = false,
    this.speedLabel,
    this.timeLabel,
  }) : assert(content != null || child != null,
            'Provide either content or child');

  final String? content;
  final Widget? child;

  /// Path to an image attached to this message, if any.
  final String? imagePath;
  final bool isUser;
  final bool isStreaming;
  final VoidCallback? onCopy;
  final VoidCallback? onReadAloud;

  /// When true, the read-aloud button shows a stop icon.
  final bool isSpeaking;

  /// Model speed, shown at the bottom only after the reply is saved.
  final String? speedLabel;

  /// Whole wait from send, on the same bottom row as [speedLabel].
  final String? timeLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statColor = (isUser
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSecondaryContainer)
        .withValues(alpha: 0.7);
    final showFooter = !isStreaming &&
        (speedLabel != null ||
            timeLabel != null ||
            onCopy != null ||
            onReadAloud != null);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? colorScheme.primaryContainer
              : colorScheme.secondaryContainer,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (imagePath != null) ...[
                ImageAttachmentThumbnail(path: imagePath!, size: 200),
                const SizedBox(height: 8),
              ],
              if (child != null || (content?.isNotEmpty ?? false))
                child ??
                    ChatMarkdownText(
                      content!,
                      style: TextStyle(
                        color: isUser
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSecondaryContainer,
                      ),
                      isStreaming: isStreaming,
                    ),
              if (showFooter) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (speedLabel != null)
                      Text(
                        speedLabel!,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: statColor),
                      ),
                    if (timeLabel != null) ...[
                      if (speedLabel != null) const SizedBox(width: 8),
                      Text(
                        timeLabel!,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: statColor),
                      ),
                    ],
                    const Spacer(),
                    if (onCopy != null)
                      _ActionIcon(
                        icon: Icons.copy_outlined,
                        tooltip: 'Copy message',
                        onPressed: onCopy!,
                        color: isUser
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSecondaryContainer,
                      ),
                    if (onReadAloud != null)
                      _ActionIcon(
                        icon: isSpeaking
                            ? Icons.stop_circle_outlined
                            : Icons.volume_up_outlined,
                        tooltip: isSpeaking ? 'Stop reading' : 'Read aloud',
                        onPressed: onReadAloud!,
                        color: isUser
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSecondaryContainer,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 18),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      color: color.withValues(alpha: 0.75),
      onPressed: onPressed,
    );
  }
}
