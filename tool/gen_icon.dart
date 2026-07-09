// Generates a simple placeholder app icon at assets/icon/icon.png.
// Run with: fvm dart run tool/gen_icon.dart
// Replace assets/icon/icon.png with a real 1024x1024 logo, then re-run
// `fvm dart run flutter_launcher_icons` before store submission.
import 'dart:io';

import 'package:image/image.dart' as img;

void main() {
  const size = 1024;
  final image = img.Image(width: size, height: size);

  // Deep-purple background (matches the app's seed color).
  img.fill(image, color: img.ColorRgb8(0x67, 0x3A, 0xB7));

  // A light "orb" mark with a small purple notch — a minimal, non-default glyph.
  img.fillCircle(
    image,
    x: size ~/ 2,
    y: size ~/ 2,
    radius: (size * 0.30).round(),
    color: img.ColorRgb8(0xF3, 0xE5, 0xF5),
  );
  img.fillCircle(
    image,
    x: (size * 0.60).round(),
    y: (size * 0.40).round(),
    radius: (size * 0.11).round(),
    color: img.ColorRgb8(0x67, 0x3A, 0xB7),
  );

  Directory('assets/icon').createSync(recursive: true);
  File('assets/icon/icon.png').writeAsBytesSync(img.encodePng(image));
  stdout.writeln('Wrote assets/icon/icon.png (${size}x$size)');
}
