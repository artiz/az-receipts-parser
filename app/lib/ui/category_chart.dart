/// Bars per expense category for one month: plan in light grey, the actual
/// amount over it in the category's colour, icons on the x axis, the largest
/// on the right. Tapping a bar shows its name and numbers.
library;

import 'package:flutter/material.dart';

import '../budget/budget_file.dart';
import '../l10n/app_localizations.dart';
import 'widgets.dart';

class CategoryBar {
  const CategoryBar({required this.category, required this.actual, required this.plan});
  final BudgetCategory category;
  final double actual;
  final double plan;
}

class CategoryChart extends StatefulWidget {
  const CategoryChart({super.key, required this.bars, this.height = 150});
  final List<CategoryBar> bars;
  final double height;

  /// Expense categories with an actual or planned amount, ascending by the
  /// actual amount so the main one ends up on the right.
  static List<CategoryBar> barsFor(BudgetFile file, Map<String, double> actualByCategory, int month) {
    final out = <CategoryBar>[];
    for (final c in file.expenseCategories) {
      final actual = actualByCategory[c.name] ?? 0;
      final plan = file.overview.plan[c.name]?.$2[month - 1] ?? 0;
      if (actual > 0 || plan > 0) out.add(CategoryBar(category: c, actual: actual, plan: plan));
    }
    out.sort((a, b) => a.actual != b.actual ? a.actual.compareTo(b.actual) : a.plan.compareTo(b.plan));
    return out;
  }

  @override
  State<CategoryChart> createState() => _CategoryChartState();
}

class _CategoryChartState extends State<CategoryChart> {
  int? _selected;

  @override
  void didUpdateWidget(CategoryChart old) {
    super.didUpdateWidget(old);
    if (_selected != null && _selected! >= widget.bars.length) _selected = null;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final bars = widget.bars;
    if (bars.isEmpty) return const SizedBox.shrink();
    final colors = [for (final b in bars) categoryColor(b.category.name, brightness, hex: b.category.color)];
    final sel = _selected == null ? null : bars[_selected!];
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 22,
              child: sel == null
                  ? Text(l.chartHint, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12))
                  : Row(
                      children: [
                        Icon(categoryIcon(sel.category), size: 16, color: colors[_selected!]),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${sel.category.name} · ${l.actual} ${euroShort(sel.actual)}${sel.plan > 0 ? ' · ${l.planLabel} ${euroShort(sel.plan)}' : ''}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 4),
            LayoutBuilder(
              builder: (context, constraints) {
                final slot = constraints.maxWidth / bars.length;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (d) {
                    final i = (d.localPosition.dx / slot).floor().clamp(0, bars.length - 1);
                    setState(() => _selected = _selected == i ? null : i);
                  },
                  child: Column(
                    children: [
                      CustomPaint(
                        size: Size(constraints.maxWidth, widget.height),
                        painter: _BarsPainter(
                          bars: bars,
                          colors: colors,
                          planColor: scheme.surfaceContainerHighest,
                          baseline: scheme.outlineVariant,
                          selected: _selected,
                          highlight: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          for (final (i, b) in bars.indexed)
                            SizedBox(
                              width: slot,
                              child: Icon(
                                categoryIcon(b.category),
                                size: slot < 24 ? 14 : 18,
                                color: _selected == null || _selected == i ? colors[i] : colors[i].withValues(alpha: 0.45),
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

class _BarsPainter extends CustomPainter {
  _BarsPainter({required this.bars, required this.colors, required this.planColor, required this.baseline, required this.selected, required this.highlight});
  final List<CategoryBar> bars;
  final List<Color> colors;
  final Color planColor;
  final Color baseline;
  final Color highlight;
  final int? selected;

  @override
  void paint(Canvas canvas, Size size) {
    var max = 0.0;
    for (final b in bars) {
      if (b.actual > max) max = b.actual;
      if (b.plan > max) max = b.plan;
    }
    if (max <= 0) return;
    final slot = size.width / bars.length;
    final barWidth = (slot * 0.68).clamp(6.0, 40.0);
    final bottom = size.height - 1;
    final usable = size.height - 6;
    const radius = Radius.circular(3);
    canvas.drawLine(Offset(0, bottom), Offset(size.width, bottom), Paint()..color = baseline..strokeWidth = 1);
    for (final (i, b) in bars.indexed) {
      final x = slot * i + (slot - barWidth) / 2;
      if (b.plan > 0) {
        final h = usable * b.plan / max;
        canvas.drawRRect(RRect.fromRectAndCorners(Rect.fromLTWH(x, bottom - h, barWidth, h), topLeft: radius, topRight: radius), Paint()..color = planColor);
      }
      if (b.actual > 0) {
        final h = usable * b.actual / max;
        final rect = Rect.fromLTWH(x, bottom - h, barWidth, h);
        canvas.drawRRect(RRect.fromRectAndCorners(rect, topLeft: radius, topRight: radius), Paint()..color = colors[i].withValues(alpha: 0.72));
        if (selected == i) {
          canvas.drawRRect(
            RRect.fromRectAndCorners(rect.inflate(1), topLeft: radius, topRight: radius),
            Paint()
              ..color = highlight
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5,
          );
        }
      } else if (selected == i && b.plan > 0) {
        final h = usable * b.plan / max;
        canvas.drawRRect(
          RRect.fromRectAndCorners(Rect.fromLTWH(x, bottom - h, barWidth, h).inflate(1), topLeft: radius, topRight: radius),
          Paint()
            ..color = highlight
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) => old.bars != bars || old.selected != selected || old.colors != colors || old.planColor != planColor;
}
