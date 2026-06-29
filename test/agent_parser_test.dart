import 'package:flutter_test/flutter_test.dart';
import 'package:loki_llm/features/agent/domain/tool_call_parser.dart';

void main() {
  group('parseToolCall', () {
    test('parses a well-formed fenced block', () {
      const out = '''
Sure, let me compute that.
```tool_call
{"name": "calculator", "arguments": {"expression": "12 * 7"}}
```
''';
      final call = parseToolCall(out);
      expect(call, isNotNull);
      expect(call!.name, 'calculator');
      expect(call.arguments['expression'], '12 * 7');
    });

    test('tolerates an upper-case fence tag and surrounding prose', () {
      const out = 'prefix ```TOOL_CALL\n{"name":"datetime","arguments":{}}\n``` suffix';
      final call = parseToolCall(out);
      expect(call?.name, 'datetime');
      expect(call!.arguments, isEmpty);
    });

    test('falls back to a bare JSON object with a name field', () {
      const out = 'Let me search: {"name": "document_search", "arguments": {"query": "rag"}}';
      final call = parseToolCall(out);
      expect(call?.name, 'document_search');
      expect(call!.arguments['query'], 'rag');
    });

    test('returns null when there is no tool call', () {
      expect(parseToolCall('The answer is 84.'), isNull);
      expect(parseToolCall(''), isNull);
    });

    test('returns null for a malformed JSON body', () {
      const out = '```tool_call\n{"name": "calculator", "arguments": }\n```';
      expect(parseToolCall(out), isNull);
    });

    test('returns null when name is missing or empty', () {
      expect(parseToolCall('```tool_call\n{"arguments": {}}\n```'), isNull);
      expect(parseToolCall('```tool_call\n{"name": "", "arguments": {}}\n```'),
          isNull);
    });

    test('defaults arguments to empty when absent', () {
      final call = parseToolCall('```tool_call\n{"name": "datetime"}\n```');
      expect(call?.name, 'datetime');
      expect(call!.arguments, isEmpty);
    });
  });
}
