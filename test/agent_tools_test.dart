import 'package:flutter_test/flutter_test.dart';
import 'package:loki_llm/features/agent/tools/calculator_tool.dart';
import 'package:loki_llm/features/agent/tools/datetime_tool.dart';
import 'package:loki_llm/features/agent/tools/document_search_tool.dart';
import 'package:loki_llm/features/documents/domain/document_chunk.dart';

DocumentChunk _chunk(String id, String content) => DocumentChunk(
      chunkId: id,
      documentId: 'doc-1',
      content: content,
      chunkIndex: 0,
      createdAtMs: 0,
    );

void main() {
  group('CalculatorTool', () {
    final calc = CalculatorTool();

    test('respects operator precedence', () async {
      expect(await calc.call({'expression': '2 + 3 * 4'}), '14');
    });
    test('handles parentheses and unary minus', () async {
      expect(await calc.call({'expression': '(2 + 3) * 4'}), '20');
      expect(await calc.call({'expression': '-5 + 2'}), '-3');
    });
    test('returns decimals when not whole', () async {
      expect(await calc.call({'expression': '10 / 4'}), '2.5');
    });
    test('reports division by zero without throwing', () async {
      expect(await calc.call({'expression': '1/0'}), startsWith('Error:'));
    });
    test('rejects non-arithmetic input', () async {
      expect(await calc.call({'expression': 'rm -rf /'}), startsWith('Error:'));
      expect(await calc.call({'expression': '2 +'}), startsWith('Error:'));
    });
    test('requires an expression argument', () async {
      expect(await calc.call({}), startsWith('Error:'));
    });
  });

  group('DateTimeTool', () {
    test('returns the injected time', () async {
      final tool = DateTimeTool(now: () => DateTime(2026, 6, 29, 10, 30));
      expect(await tool.call({}), contains('2026-06-29'));
    });
  });

  group('DocumentSearchTool', () {
    DocumentSearchTool build({
      Future<List<double>> Function(String)? embed,
      List<DocumentChunk> Function(List<double>, int)? search,
    }) =>
        DocumentSearchTool(
          embed: embed ?? (q) async => [0.1, 0.2],
          search: search ?? (v, k) => [_chunk('c1', 'first'), _chunk('c2', 'second')],
        );

    test('formats the retrieved chunks', () async {
      final out = await build().call({'query': 'rag'});
      expect(out, contains('[1] first'));
      expect(out, contains('[2] second'));
    });
    test('reports when nothing matches', () async {
      final out = await build(search: (v, k) => []).call({'query': 'x'});
      expect(out, contains('No matching passages'));
    });
    test('catches embedding errors without throwing', () async {
      final out = await build(embed: (q) async => throw StateError('not ready'))
          .call({'query': 'x'});
      expect(out, startsWith('Error searching documents'));
    });
    test('requires a query argument', () async {
      expect(await build().call({}), startsWith('Error:'));
    });
  });
}
