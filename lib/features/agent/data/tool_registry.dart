import 'dart:convert';

import '../domain/tool.dart';

/// Holds the available [Tool]s, looks them up by name, and renders the
/// instructions injected into the system prompt when tools are enabled.
class ToolRegistry {
  ToolRegistry(this._tools);

  final List<Tool> _tools;

  List<Tool> get tools => List.unmodifiable(_tools);

  Tool? byName(String name) {
    for (final tool in _tools) {
      if (tool.name == name) return tool;
    }
    return null;
  }

  /// System-prompt text describing the tool-call protocol and every tool.
  String promptDescription() {
    final b = StringBuffer();
    b.writeln(
        'You can use tools to help answer. To call a tool, respond with ONLY a '
        'fenced block in this exact format:');
    b.writeln('```tool_call');
    b.writeln('{"name": "<tool>", "arguments": { ... }}');
    b.writeln('```');
    b.writeln(
        'You will then receive an "Observation" with the result. Use it to call '
        'another tool or to write your final answer in plain text. Do not '
        'mention tools or tool_call blocks in your final answer.');
    b.writeln();
    b.writeln('Available tools:');
    for (final tool in _tools) {
      b.writeln('- ${tool.name}: ${tool.description} '
          'Arguments: ${jsonEncode(tool.parameterSchema)}');
    }
    return b.toString().trimRight();
  }
}
