import '../data/tool_registry.dart';

/// Builds a lazy GBNF grammar that constrains agent tool-call JSON once the
/// model begins a ` ```tool_call` fence. Plain-text final answers are unaffected
/// until the trigger pattern matches.
class ToolCallGrammar {
  ToolCallGrammar._();

  /// Trigger word(s) for llama.cpp lazy grammar (auto regex-escaped natively).
  static const triggerWords = [
    '```tool_call',
  ];

  /// Returns a GBNF grammar string for [registry]'s tools, or null when empty.
  static String? build(ToolRegistry registry) {
    final names = registry.tools.map((t) => t.name).toList();
    if (names.isEmpty) return null;

    final toolNameAlt = names.map((n) => '"\\"$n\\""').join(' | ');

    return '''
root ::= tool-call-block
tool-call-block ::= "```tool_call" "\\n" object "\\n```"
object ::= "{" space "\\"name\\"" space ":" space tool-name "," space "\\"arguments\\"" space ":" space arg-object "}"
tool-name ::= $toolNameAlt
arg-object ::= "{" space ( arg-pair ( "," space arg-pair )* )? space "}" | "{" space "}"
arg-pair ::= string space ":" space arg-value
arg-value ::= string | number
string ::= "\\"" [^"\\\\\\n]* "\\""
number ::= "-"? [0-9]+ ("." [0-9]+)?
space ::= [ \\t\\n]*
''';
  }
}
