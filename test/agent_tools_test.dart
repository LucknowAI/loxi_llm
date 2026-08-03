import 'package:flutter_test/flutter_test.dart';
import 'package:loki_llm/features/agent/agent_model_support.dart';
import 'package:loki_llm/features/agent/tools/calculator_tool.dart';
import 'package:loki_llm/features/agent/tools/datetime_tool.dart';
import 'package:loki_llm/features/agent/tools/document_search_tool.dart';
import 'package:loki_llm/features/agent/tools/list_documents_tool.dart';
import 'package:loki_llm/features/agent/tools/recall_memory_tool.dart';
import 'package:loki_llm/features/agent/tools/unit_convert_tool.dart';
import 'package:loki_llm/features/agent/domain/tool_call_grammar.dart';
import 'package:loki_llm/features/agent/data/tool_registry.dart';
import 'package:loki_llm/features/chat/domain/message.dart';
import 'package:loki_llm/features/chat/domain/message_role.dart';
import 'package:loki_llm/features/documents/domain/document.dart';
import 'package:loki_llm/features/documents/domain/document_chunk.dart';

DocumentChunk _chunk(String id, String content) => DocumentChunk(
      chunkId: id,
      documentId: 'doc-1',
      content: content,
      chunkIndex: 0,
      createdAtMs: 0,
    );

Message _msg(String id, String content, {MessageRole role = MessageRole.user}) =>
    Message(
      id: id,
      conversationId: 'conv-1',
      role: role,
      content: content,
      createdAtMs: 0,
    );

Document _doc(String id, String name, {int chunks = 3}) => Document(
      id: id,
      name: name,
      format: 'pdf',
      chunkCount: chunks,
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

  group('isAgentCapableModel', () {
    test('allows Phi-3 and Llama 3.2', () {
      expect(isAgentCapableModel('phi3-mini-4k-q4km'), isTrue);
      expect(isAgentCapableModel('llama32-3b-q4km'), isTrue);
    });
    test('blocks Gemma 270M', () {
      expect(isAgentCapableModel('gemma3-270m-it'), isFalse);
    });
    test('blocks null or empty model id', () {
      expect(isAgentCapableModel(null), isFalse);
      expect(isAgentCapableModel(''), isFalse);
    });
  });

  group('RecallMemoryTool', () {
    RecallMemoryTool build({
      List<Message> messages = const [],
      String summary = '',
      int historyWindow = 3,
    }) =>
        RecallMemoryTool(
          conversationId: 'conv-1',
          getMessages: (_) => messages,
          summary: summary,
          historyWindow: historyWindow,
        );

    test('finds matches outside the recent window', () async {
      final messages = [
        _msg('1', 'We discussed the budget in Q1'),
        _msg('2', 'assistant reply', role: MessageRole.assistant),
        _msg('3', 'recent user'),
        _msg('4', 'recent assistant', role: MessageRole.assistant),
      ];
      final out =
          await build(messages: messages).call({'query': 'budget'});
      expect(out, contains('budget'));
      expect(out, contains('(user)'));
    });

    test('falls back to rolling summary when no message matches', () async {
      final out = await build(summary: 'Earlier we talked about the launch date.')
          .call({'query': 'launch'});
      expect(out, contains('Rolling summary'));
      expect(out, contains('launch date'));
    });

    test('reports when no older messages exist', () async {
      final out = await build(messages: [_msg('1', 'only recent')])
          .call({'query': 'x'});
      expect(out, contains('No older messages'));
    });

    test('requires a query argument', () async {
      expect(await build().call({}), startsWith('Error:'));
    });
  });

  group('ListDocumentsTool', () {
    test('formats document list', () async {
      final tool = ListDocumentsTool(
        listDocuments: () => [
          _doc('d1', 'report.pdf'),
          _doc('d2', 'notes.txt', chunks: 1),
        ],
      );
      final out = await tool.call({});
      expect(out, contains('[1] report.pdf'));
      expect(out, contains('[2] notes.txt'));
      expect(out, contains('3 chunks'));
    });

    test('reports when no documents imported', () async {
      final tool = ListDocumentsTool(listDocuments: () => []);
      expect(await tool.call({}), contains('No documents'));
    });
  });

  group('UnitConvertTool', () {
    final tool = UnitConvertTool();

    test('converts length units', () async {
      expect(
        await tool.call({'value': 1, 'from': 'km', 'to': 'm'}),
        '1000',
      );
      expect(
        await tool.call({'value': 1, 'from': 'mi', 'to': 'km'}),
        startsWith('1.609'),
      );
    });

    test('converts weight units', () async {
      expect(
        await tool.call({'value': 1, 'from': 'kg', 'to': 'g'}),
        '1000',
      );
    });

    test('converts temperature units', () async {
      expect(
        await tool.call({'value': 0, 'from': 'c', 'to': 'f'}),
        '32',
      );
      expect(
        await tool.call({'value': 32, 'from': 'f', 'to': 'c'}),
        '0',
      );
    });

    test('rejects cross-category conversion', () async {
      expect(
        await tool.call({'value': 1, 'from': 'km', 'to': 'kg'}),
        startsWith('Error:'),
      );
    });

    test('requires value, from, and to', () async {
      expect(await tool.call({'from': 'km', 'to': 'm'}), startsWith('Error:'));
      expect(await tool.call({'value': 1, 'to': 'm'}), startsWith('Error:'));
      expect(await tool.call({'value': 1, 'from': 'km'}), startsWith('Error:'));
    });
  });

  group('ToolCallGrammar', () {
    test('build includes registered tool names', () {
      final registry = ToolRegistry([CalculatorTool(), UnitConvertTool()]);
      final grammar = ToolCallGrammar.build(registry);
      expect(grammar, isNotNull);
      expect(grammar, contains('calculator'));
      expect(grammar, contains('unit_convert'));
    });

    test('build returns null for empty registry', () {
      expect(ToolCallGrammar.build(ToolRegistry([])), isNull);
    });
  });
}
