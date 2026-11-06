/// Twelve months of a year: expenses as bars coloured by the month limit,
/// the plan in grey behind them, the cumulated saldo as a line. Tapping a
/// month shows its numbers.
library;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme.dart';
import 'widgets.dart';

class YearMonth {
  const YearMonth({required this.month, required this.income, required this.expenses, required this.plan, required this.level});
  final int month;
  final double income;
  final double expenses;
  final double plan;
  final LimitLevel level;
  double get saldo => income - expenses;
}

class YearChart extends StatefulWidget {
  const YearChart({super.key, required this.months, required this.monthLabel, this.height = 170});
  final List<YearMonth> months;
  final String Function(int month) monthLabel;
  final double height;

  @override
  State<YearChart> createState() => _YearChartState();
}

class _YearChartState extends State<YearChart> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final months = widget.months;
    final sel = _selected == null ? null : months[_selected!];
    var cumulated = 0.0;
    final cumulatedAt = <double>[];
    for (final m in months) {
      cumulated += m.expenses > 0 || m.income > 0 ? m.saldo : 0;
      cumulatedAt.add(cumulated);
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 22,
              child: sel == null
                  ? Text(l.yearChartHint, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12))
                  : Text(
                      '${widget.monthLabel(sel.month)} · ${l.expenses} ${euroShort(sel.expenses)}${sel.plan > 0 ? ' / ${euroShort(sel.plan)}' : ''} · ${l.saldo} ${euroShort(sel.saldo)} · Σ ${euroShort(cumulatedAt[_selected!])}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
            const SizedBox(height: 4),
            LayoutBuilder(
              builder: (context, constraints) {
                final slot = constraints.maxWidth / months.length;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (d) {
                    final i = (d.localPosition.dx / slot).floor().clamp(0, months.length - 1);
                    setState(() => _selected = _selected == i ? null : i);
                  },
                  child: Column(
                    children: [
                      CustomPaint(
                        size: Size(constraints.maxWidth, widget.height),
                        painter: _YearPainter(
                          months: months,
                          cumulated: cumulatedAt,
                          colors: [for (final m in months) limitColor(context, m.level)],
                          planColor: scheme.surfaceContainerHighest,
                          baseline: scheme.outlineVariant,
                          line: scheme.tertiary,
                          selected: _selected,
                          highlight: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          for (final (i, m) in months.indexed)
                            SizedBox(
                              width: slot,
                              child: Text(
                                widget.monthLabel(m.month).substring(0, 1),
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 11, color: _selected == null || _selected == i ? scheme.onSurfaceVariant : scheme.outlineVariant),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _YearPainter extends CustomPainter {
  _YearPainter({required this.months, required this.cumulated, required this.colors, required this.planColor, required this.baseline, required this.line, required this.selected, required this.highlight});
  final List<YearMonth> months;
  final List<double> cumulated;
  final List<Color> colors;
  final Color planColor;
  final Color baseline;
  final Color line;
  final Color highlight;
  final int? selected;

  @override
  void paint(Canvas canvas, Size size) {
    var max = 0.0;
    for (final m in months) {
      if (m.expenses > max) max = m.expenses;
      if (m.plan > max) max = m.plan;
      if (m.income > max) max = m.income;
    }
    var cumMax = 0.0;
    for (final c in cumulated) {
      if (c.abs() > cumMax) cumMax = c.abs();
    }
    final slot = size.width / months.length;
    final barWidth = (slot * 0.62).clamp(6.0, 36.0);
    final bottom = size.height - 1;
    final usable = size.height - 8;
    const radius = Radius.circular(3);
    canvas.drawLine(Offset(0, bottom), Offset(size.width, bottom), Paint()..color = baseline..strokeWidth = 1);
    if (max > 0) {
      for (final (i, m) in months.indexed) {
        final x = slot * i + (slot - barWidth) / 2;
        if (m.plan > 0) {
          final h = usable * m.plan / max;
          canvas.drawRRect(RRect.fromRectAndCorners(Rect.fromLTWH(x, bottom - h, barWidth, h), topLeft: radius, topRight: radius), Paint()..color = planColor);
        }
        if (m.expenses > 0) {
          final h = usable * m.expenses / max;
          final rect = Rect.fromLTWH(x, bottom - h, barWidth, h);
          canvas.drawRRect(RRect.fromRectAndCorners(rect, topLeft: radius, topRight: radius), Paint()..color = colors[i].withValues(alpha: 0.72));
          if (selected == i) {
            canvas.drawRRect(RRect.fromRectAndCorners(rect.inflate(1), topLeft: radius, topRight: radius), Paint()..color = highlight..style = PaintingStyle.stroke..strokeWidth = 1.5);
          }
        }
      }
    }
    // Cumulated saldo: a line on its own scale, zero at half height.
    if (cumMax > 0) {
      final path = Path();
      final zero = size.height / 2;
      for (final (i, c) in cumulated.indexed) {
        final m = months[i];
        if (m.expenses == 0 && m.income == 0 && i > 0) break;
        final x = slot * i + slot / 2;
        final y = zero - (c / cumMax) * (usable / 2 - 4);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
        canvas.drawCircle(Offset(x, y), 2.5, Paint()..color = line);
      }
      canvas.drawPath(path, Paint()..color = line..style = PaintingStyle.stroke..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(_YearPainter old) => old.months != months || old.selected != selected || old.colors != colors;
}
