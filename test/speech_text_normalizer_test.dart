import 'package:flutter_test/flutter_test.dart';
import 'package:loki_llm/core/services/speech_text_normalizer.dart';

void main() {
  group('SpeechTextNormalizer', () {
    test('removes horizontal rules instead of reading dashes', () {
      const input = 'Here is the answer:\n\n---\n\nResult: 5 km';
      expect(
        SpeechTextNormalizer.normalize(input),
        'Here is the answer: Result: 5 km',
      );
    });

    test('strips fenced code and tool_call blocks', () {
      const input = '''
Done.

```tool_call
{"name": "unit_convert", "arguments": {"value": 5}}
```

The result is 3.1 miles.
''';
      final out = SpeechTextNormalizer.normalize(input);
      expect(out, isNot(contains('tool_call')));
      expect(out, isNot(contains('{')));
      expect(out, contains('3.1 miles'));
    });

    test('flattens bold, headers, and bullets', () {
      const input = '''
# Summary

**Answer:** 5 km

- First point
- Second point
''';
      final out = SpeechTextNormalizer.normalize(input);
      expect(out, contains('Summary'));
      expect(out, contains('Answer: 5 km'));
      expect(out, isNot(contains('**')));
      expect(out, contains('First point'));
      expect(out, contains('Second point'));
    });

    test('uses link label instead of raw URL syntax', () {
      const input = 'See [Loki docs](https://example.com/docs) for details.';
      expect(
        SpeechTextNormalizer.normalize(input),
        'See Loki docs for details.',
      );
    });

    test('returns empty for whitespace-only input', () {
      expect(SpeechTextNormalizer.normalize('   \n\n---\n'), isEmpty);
    });
  });
}
