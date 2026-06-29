import 'dart:convert';

import 'tool.dart';

/// Extract a tool call from model output.
///
/// The model is instructed to emit a single fenced block:
///
/// ```tool_call
/// {"name": "calculator", "arguments": {"expression": "2 + 2"}}
/// ```
///
/// Returns the [ToolCall] when a well-formed block is present, or `null` when
/// there is no block or the JSON is malformed — in which case the caller treats
/// the output as a final answer (rather than looping forever).
ToolCall? parseToolCall(String output) {
  final json = _extractToolCallJson(output);
  if (json == null) return null;

  try {
    final decoded = jsonDecode(json);
    if (decoded is! Map) return null;

    final name = decoded['name'];
    if (name is! String || name.isEmpty) return null;

    final rawArgs = decoded['arguments'];
    final arguments = rawArgs is Map
        ? rawArgs.map((k, v) => MapEntry(k.toString(), v))
        : <String, Object?>{};

    return ToolCall(name: name, arguments: arguments);
  } catch (_) {
    return null;
  }
}

/// Pull the JSON body out of the first ```` ```tool_call ```` fence, or — as a
/// fallback for models that drop the fence — the first balanced `{...}` object
/// that mentions a `"name"` key.
String? _extractToolCallJson(String output) {
  final fence = RegExp(
    r'```\s*tool_call\s*\n(.*?)```',
    dotAll: true,
    caseSensitive: false,
  );
  final match = fence.firstMatch(output);
  if (match != null) return match.group(1)!.trim();

  // Fallback: a bare JSON object containing a "name" field.
  final start = output.indexOf('{');
  if (start == -1) return null;
  final body = _firstBalancedObject(output, start);
  if (body == null || !body.contains('"name"')) return null;
  return body;
}

/// Return the substring from [start] (a `{`) to its matching `}`, respecting
/// string literals, or null if unbalanced.
String? _firstBalancedObject(String s, int start) {
  var depth = 0;
  var inString = false;
  var escaped = false;
  for (var i = start; i < s.length; i++) {
    final c = s[i];
    if (inString) {
      if (escaped) {
        escaped = false;
      } else if (c == r'\') {
        escaped = true;
      } else if (c == '"') {
        inString = false;
      }
      continue;
    }
    if (c == '"') {
      inString = true;
    } else if (c == '{') {
      depth++;
    } else if (c == '}') {
      depth--;
      if (depth == 0) return s.substring(start, i + 1);
    }
  }
  return null;
}
