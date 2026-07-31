import '../domain/tool.dart';

/// Converts common length, weight, and temperature units.
class UnitConvertTool extends Tool {
  @override
  String get name => 'unit_convert';

  @override
  String get description =>
      'Convert a numeric value between supported units '
      '(length: m, km, mi, ft, cm, in; weight: kg, g, lb, oz; '
      'temperature: c, f, k).';

  @override
  Map<String, Object?> get parameterSchema => const {
        'value': 'number — the quantity to convert',
        'from': 'string — source unit (e.g. "km", "lb", "c")',
        'to': 'string — target unit (e.g. "mi", "kg", "f")',
      };

  @override
  Future<String> call(Map<String, Object?> arguments) async {
    final valueRaw = arguments['value'];
    final from = _normUnit(arguments['from']);
    final to = _normUnit(arguments['to']);

    if (valueRaw == null) return 'Error: "value" argument is required.';
    if (from.isEmpty) return 'Error: "from" unit is required.';
    if (to.isEmpty) return 'Error: "to" unit is required.';

    final value = _parseNumber(valueRaw);
    if (value == null) {
      return 'Error: "value" must be a number, got "$valueRaw".';
    }

    try {
      final result = _convert(value, from, to);
      return _formatResult(result);
    } catch (e) {
      return 'Error: $e';
    }
  }

  static String _normUnit(Object? unit) {
    final s = unit?.toString().trim().toLowerCase() ?? '';
    return switch (s) {
      'celsius' || 'cel' => 'c',
      'fahrenheit' || 'fah' => 'f',
      'kelvin' => 'k',
      'meters' || 'meter' => 'm',
      'kilometers' || 'kilometer' => 'km',
      'miles' || 'mile' => 'mi',
      'feet' || 'foot' => 'ft',
      'centimeters' || 'centimeter' => 'cm',
      'inches' || 'inch' => 'in',
      'kilograms' || 'kilogram' => 'kg',
      'grams' || 'gram' => 'g',
      'pounds' || 'pound' => 'lb',
      'ounces' || 'ounce' => 'oz',
      _ => s,
    };
  }

  static double? _parseNumber(Object raw) {
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString().trim());
  }

  static String _formatResult(double result) {
    if (result == result.roundToDouble() && result.abs() < 1e15) {
      return result.toInt().toString();
    }
    return result.toStringAsFixed(6).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  static double _convert(double value, String from, String to) {
    if (from == to) return value;

    if (_lengthUnits.contains(from) && _lengthUnits.contains(to)) {
      final meters = value * _lengthToMeters[from]!;
      return meters / _lengthToMeters[to]!;
    }
    if (_weightUnits.contains(from) && _weightUnits.contains(to)) {
      final kg = value * _weightToKg[from]!;
      return kg / _weightToKg[to]!;
    }
    if (_tempUnits.contains(from) && _tempUnits.contains(to)) {
      final celsius = _toCelsius(value, from);
      return _fromCelsius(celsius, to);
    }

    throw StateError(
        'Cannot convert from "$from" to "$to". Units must be in the same category.');
  }

  static const _lengthUnits = {'m', 'km', 'mi', 'ft', 'cm', 'in'};
  static const _weightUnits = {'kg', 'g', 'lb', 'oz'};
  static const _tempUnits = {'c', 'f', 'k'};

  static const _lengthToMeters = {
    'm': 1.0,
    'km': 1000.0,
    'mi': 1609.344,
    'ft': 0.3048,
    'cm': 0.01,
    'in': 0.0254,
  };

  static const _weightToKg = {
    'kg': 1.0,
    'g': 0.001,
    'lb': 0.45359237,
    'oz': 0.028349523125,
  };

  static double _toCelsius(double value, String from) => switch (from) {
        'c' => value,
        'f' => (value - 32) * 5 / 9,
        'k' => value - 273.15,
        _ => throw StateError('Unknown temperature unit: $from'),
      };

  static double _fromCelsius(double celsius, String to) => switch (to) {
        'c' => celsius,
        'f' => celsius * 9 / 5 + 32,
        'k' => celsius + 273.15,
        _ => throw StateError('Unknown temperature unit: $to'),
      };
}
