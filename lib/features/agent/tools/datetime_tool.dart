import '../domain/tool.dart';

/// Returns the current local date and time. [now] is injectable for tests.
class DateTimeTool extends Tool {
  DateTimeTool({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  @override
  String get name => 'datetime';

  @override
  String get description => 'Get the current local date and time.';

  @override
  Map<String, Object?> get parameterSchema => const {};

  @override
  Future<String> call(Map<String, Object?> arguments) async =>
      _now().toString();
}
