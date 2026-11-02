/// Groups detector boxes into printed rows.
///
/// The detector returns one box per text run; a receipt row ("Socken … 5,99")
/// is often two or three boxes with the same vertical centre. Rows are what
/// the parser works on.
library;

import 'ocr_types.dart';

class OcrRow {
  OcrRow(this.lines);

  final List<OcrLine> lines; // left to right

  double get y0 => lines.map((l) => l.y0).reduce((a, b) => a < b ? a : b);
  double get y1 => lines.map((l) => l.y1).reduce((a, b) => a > b ? a : b);
  double get x0 => lines.first.x0;
  double get x1 => lines.last.x1;
  double get cy => (y0 + y1) / 2;
  double get height => y1 - y0;

  /// The row text with fragments separated by two spaces.
  String get text => lines.map((l) => l.text.trim()).where((t) => t.isNotEmpty).join('  ');

  /// Rightmost fragment (where the price usually is).
  String get rightText => lines.last.text.trim();

  /// Everything except the rightmost fragment.
  String get leftText =>
      lines.length == 1 ? '' : lines.sublist(0, lines.length - 1).map((l) => l.text.trim()).join(' ');

  double get minConfidence => lines.map((l) => l.confidence).reduce((a, b) => a < b ? a : b);
}

/// Median box height, used as the row tolerance.
double medianLineHeight(List<OcrLine> lines) {
  if (lines.isEmpty) return 0;
  final hs = lines.map((l) => l.height).toList()..sort();
  return hs[hs.length ~/ 2];
}

/// Group lines into rows: a line joins a row when its vertical centre lies
/// inside the row's span (with a tolerance of `factor` × median height).
List<OcrRow> groupRows(List<OcrLine> lines, {double factor = 0.45}) {
  if (lines.isEmpty) return const [];
  final sorted = [...lines]..sort((a, b) => a.cy.compareTo(b.cy));
  final tol = medianLineHeight(lines) * factor;
  final rows = <List<OcrLine>>[];
  for (final line in sorted) {
    if (rows.isNotEmpty) {
      final row = rows.last;
      final rowCy = row.map((l) => l.cy).reduce((a, b) => a + b) / row.length;
      final overlapsX = row.any((l) => _xOverlap(l, line) > 0.5 * _min(l.width, line.width));
      if ((line.cy - rowCy).abs() <= tol && !overlapsX) {
        row.add(line);
        continue;
      }
    }
    rows.add([line]);
  }
  return rows.map((r) => OcrRow(r..sort((a, b) => a.x0.compareTo(b.x0)))).toList();
}

double _xOverlap(OcrLine a, OcrLine b) {
  final left = a.x0 > b.x0 ? a.x0 : b.x0;
  final right = a.x1 < b.x1 ? a.x1 : b.x1;
  return right - left;
}

double _min(double a, double b) => a < b ? a : b;
