import 'dart:io';

import 'package:flutter/material.dart';

/// Rounded file thumbnail for chat bubbles and the composer preview.
class ImageAttachmentThumbnail extends StatelessWidget {
  const ImageAttachmentThumbnail({
    super.key,
    required this.path,
    required this.size,
    this.borderRadius = 12,
  });

  final String path;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final cache = (size * MediaQuery.of(context).devicePixelRatio).round();
    final colors = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.file(
        File(path),
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: cache,
        cacheHeight: cache,
        errorBuilder: (context, error, stackTrace) => Container(
          width: size,
          height: size,
          color: colors.surfaceContainerHighest,
          alignment: Alignment.center,
          child: Icon(
            Icons.broken_image_outlined,
            color: colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
