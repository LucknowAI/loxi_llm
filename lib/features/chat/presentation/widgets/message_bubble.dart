import 'dart:io';

import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final showActions =
        !isStreaming && (onCopy != null || onReadAloud != null);

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imagePath != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(imagePath!),
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                  cacheWidth: (200 * MediaQuery.of(context).devicePixelRatio)
                      .round(),
                  cacheHeight: (200 * MediaQuery.of(context).devicePixelRatio)
                      .round(),
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 200,
                    height: 200,
                    color: colorScheme.surfaceContainerHighest,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (child != null || (content?.isNotEmpty ?? false))
              child ??
                  Text(
                    content!,
                    style: TextStyle(
                      color: isUser
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSecondaryContainer,
                      fontStyle:
                          isStreaming ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
            if (showActions) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                      icon: isSpeaking ? Icons.stop_circle_outlined : Icons.volume_up_outlined,
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
