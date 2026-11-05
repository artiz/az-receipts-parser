/// Tiny arithmetic for amount fields: "=500+232,23+100.34", "12,5*3",
/// "(10+5)/2". Numbers may use a decimal comma. Returns null when the text
/// is not a valid expression.
library;

double? evalExpression(String text) {
  var t = text.trim();
  if (t.startsWith('=')) t = t.substring(1);
  t = t.replaceAll('€', '').replaceAll(' ', '');
  if (t.isEmpty) return null;
  // "1.234,56" → 1234.56; a lone comma is a decimal point.
  if (t.contains(',')) {
    t = t.replaceAll(RegExp(r'(?<=\d)\.(?=\d{3}(\D|$))'), '').replaceAll(',', '.');
  }
  final p = _Parser(t);
  try {
    final v = p._expr();
    if (!p._atEnd) return null;
    return v.isFinite ? v : null;
  } catch (_) {
    return null;
  }
}

/// The expression normalised for a spreadsheet formula ("=500+232.23").
String? normalizeFormula(String text) {
  var t = text.trim();
  if (!t.startsWith('=')) return null;
  if (evalExpression(t) == null) return null;
  t = t.substring(1).replaceAll('€', '').replaceAll(' ', '');
  if (t.contains(',')) t = t.replaceAll(RegExp(r'(?<=\d)\.(?=\d{3}(\D|$))'), '').replaceAll(',', '.');
  return '=$t';
}

class _Parser {
  _Parser(this.s);
  final String s;
  int i = 0;

  bool get _atEnd => i >= s.length;
  String get _c => s[i];

  double _expr() {
    var v = _term();
    while (!_atEnd && (_c == '+' || _c == '-')) {
      final op = _c;
      i++;
      final r = _term();
      v = op == '+' ? v + r : v - r;
    }
    return v;
  }

  double _term() {
    var v = _factor();
    while (!_atEnd && (_c == '*' || _c == '/')) {
      final op = _c;
      i++;
      final r = _factor();
      v = op == '*' ? v * r : v / r;
    }
    return v;
  }

  double _factor() {
    if (_atEnd) throw const FormatException();
    if (_c == '-') {
      i++;
      return -_factor();
    }
    if (_c == '+') {
      i++;
      return _factor();
    }
    if (_c == '(') {
      i++;
      final v = _expr();
      if (_atEnd || _c != ')') throw const FormatException();
      i++;
      return v;
    }
    final start = i;
    while (!_atEnd && (RegExp(r'[0-9.]').hasMatch(_c))) {
      i++;
    }
    if (start == i) throw const FormatException();
    return double.parse(s.substring(start, i));
  }
}
