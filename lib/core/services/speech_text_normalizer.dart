/// Converts assistant/chat text (often Markdown) into plain language suitable
/// for platform TTS — strips formatting symbols that engines read literally.
class SpeechTextNormalizer {
  SpeechTextNormalizer._();

  /// Returns speakable plain text, or empty when nothing worth reading remains.
  static String normalize(String input) {
    if (input.trim().isEmpty) return '';

    var text = input.replaceAll('\r\n', '\n');

    // Drop fenced blocks (tool calls, code, etc.) — not meant to be spoken.
    text = text.replaceAll(RegExp(r'```[\s\S]*?```', multiLine: true), ' ');
    text = text.replaceAll(RegExp(r'~~~[\s\S]*?~~~', multiLine: true), ' ');

    // ATX headers (# Title) → title text.
    text = text.replaceAllMapped(
      RegExp(r'^#{1,6}\s+(.+)$', multiLine: true),
      (m) => m.group(1)!.trim(),
    );

    // Horizontal rules (---, ***, ___) — common source of "dash dash dash…".
    text = text.replaceAll(
      RegExp(r'^\s*([-*_]\s*){3,}\s*$', multiLine: true),
      ' ',
    );

    // Markdown links [label](url) → label.
    text = text.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\([^)]*\)'),
      (m) => m.group(1)!,
    );

    // Bold / italic (order matters: ** before *).
    text = text.replaceAllMapped(
      RegExp(r'\*\*(.+?)\*\*'),
      (m) => m.group(1)!,
    );
    text = text.replaceAllMapped(
      RegExp(r'__(.+?)__'),
      (m) => m.group(1)!,
    );
    text = text.replaceAllMapped(
      RegExp(r'(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)'),
      (m) => m.group(1)!,
    );
    text = text.replaceAllMapped(
      RegExp(r'(?<!_)_(?!_)(.+?)(?<!_)_(?!_)'),
      (m) => m.group(1)!,
    );

    // Inline code.
    text = text.replaceAllMapped(
      RegExp(r'`([^`]+)`'),
      (m) => m.group(1)!,
    );

    // Bullet / numbered list markers at line start.
    text = text.replaceAll(RegExp(r'^\s*[-*+•]\s+', multiLine: true), '');
    text = text.replaceAll(RegExp(r'^\s*\d+[.)]\s+', multiLine: true), '');

    // Table pipe characters and separator rows.
    text = text.replaceAll(
      RegExp(r'^\s*\|?[\s:-]+\|[\s|:-]+\|?\s*$', multiLine: true),
      ' ',
    );
    text = text.replaceAll('|', ', ');

    // Strip remaining markdown / punctuation clutter.
    text = text.replaceAll(RegExp(r'[*_`#>~]'), ' ');

    // Bare URLs — skip speaking long links.
    text = text.replaceAll(
      RegExp(r'https?://\S+'),
      ' link ',
    );

    // Collapse whitespace and repeated sentence breaks.
    text = text.replaceAll(RegExp(r'[ \t]+'), ' ');
    text = text.replaceAll(RegExp(r'\n{2,}'), '. ');
    text = text.replaceAll(RegExp(r'\n'), ' ');
    text = text.replaceAll(RegExp(r'\.(\s*\.)+'), '.');
    text = text.replaceAll(RegExp(r'\s+'), ' ');

    return text.trim();
  }
}
