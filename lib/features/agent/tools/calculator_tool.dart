import '../domain/tool.dart';

/// Evaluates a basic arithmetic expression. Uses a closed recursive-descent
/// grammar over digits, `+ - * /`, and parentheses — no `eval`, no code
/// execution, so it is safe to run on arbitrary model output.
class CalculatorTool extends Tool {
  @override
  String get name => 'calculator';

  @override
  String get description =>
      'Evaluate a basic arithmetic expression with + - * / and parentheses.';

  @override
  Map<String, Object?> get parameterSchema => const {
        'expression': 'string — e.g. "12 * (3 + 4)"',
      };

  @override
  Future<String> call(Map<String, Object?> arguments) async {
    final expr = (arguments['expression'] as String?)?.trim() ?? '';
    if (expr.isEmpty) return 'Error: "expression" argument is required.';
    try {
      final result = _Calc(expr).parse();
      if (result == result.roundToDouble() && result.abs() < 1e15) {
        return result.toInt().toString();
      }
      return result.toString();
    } catch (e) {
      return 'Error: could not evaluate "$expr".';
    }
  }
}

/// Recursive-descent evaluator: expr = term (('+'|'-') term)*;
/// term = factor (('*'|'/') factor)*; factor = number | '(' expr ')' | unary.
class _Calc {
  _Calc(this._s);

  final String _s;
  int _pos = 0;

  double parse() {
    final v = _expr();
    _skipWs();
    if (_pos != _s.length) {
      throw FormatException('unexpected "${_s.substring(_pos)}"');
    }
    return v;
  }

  double _expr() {
    var v = _term();
    while (true) {
      if (_match('+')) {
        v += _term();
      } else if (_match('-')) {
        v -= _term();
      } else {
        break;
      }
    }
    return v;
  }

  double _term() {
    var v = _factor();
    while (true) {
      if (_match('*')) {
        v *= _factor();
      } else if (_match('/')) {
        final d = _factor();
        if (d == 0) throw const FormatException('division by zero');
        v /= d;
      } else {
        break;
      }
    }
    return v;
  }

  double _factor() {
    if (_match('(')) {
      final v = _expr();
      if (!_match(')')) throw const FormatException('expected )');
      return v;
    }
    if (_match('-')) return -_factor();
    if (_match('+')) return _factor();
    return _number();
  }

  double _number() {
    _skipWs();
    final start = _pos;
    while (_pos < _s.length && (_isDigit(_s[_pos]) || _s[_pos] == '.')) {
      _pos++;
    }
    if (_pos == start) throw FormatException('expected number at $_pos');
    return double.parse(_s.substring(start, _pos));
  }

  bool _match(String c) {
    _skipWs();
    if (_pos < _s.length && _s[_pos] == c) {
      _pos++;
      return true;
    }
    return false;
  }

  void _skipWs() {
    while (_pos < _s.length && _s[_pos] == ' ') {
      _pos++;
    }
  }

  bool _isDigit(String c) {
    final u = c.codeUnitAt(0);
    return u >= 48 && u <= 57;
  }
}
