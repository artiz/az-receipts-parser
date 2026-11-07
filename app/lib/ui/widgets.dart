/// Shared widgets and formatting for the budget UI.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app.dart';
import '../budget/budget_file.dart';
import '../budget/budget_service.dart';
import '../core/text_normalize.dart';
import '../core/expression.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';

/// Symbol after amounts, from Settings ('€' unless changed); the file does
/// not carry a currency.
String moneySymbol = '€';

/// "1.234,56 €" (the file's convention), sign kept.
String euro(double amount, {bool showPlus = false}) {
  final f = NumberFormat('#,##0.00', 'de_AT');
  final s = '${f.format(amount.abs())} $moneySymbol';
  if (amount < 0) return '-$s';
  return showPlus ? '+$s' : s;
}

/// Short form for tiles: "10 €", "35,09 €".
String euroShort(double amount) {
  final abs = amount.abs();
  final s = abs == abs.roundToDouble() ? '${abs.toInt()} $moneySymbol' : '${NumberFormat('#,##0.00', 'de_AT').format(abs)} $moneySymbol';
  return amount < 0 ? '-$s' : s;
}

/// "3000" / "3000,5" for edit fields.
String euroShortPlain(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2).replaceAll('.', ',');

String dateDm(DateTime d) => DateFormat('dd.MM.').format(d);
String dateDmy(DateTime d) => DateFormat('dd.MM.yyyy').format(d);
String monthName(int year, int month, Locale locale) => DateFormat.yMMMM(locale.toString()).format(DateTime(year, month));

/// Parse "12,5", "12.50", "1.234,56", "-3,2" the way a German user types it.
/// Also accepts a small formula: "=500+232,23+100.34", "12,5*3".
double? parseAmount(String text) {
  var t = text.trim().replaceAll('€', '').replaceAll(' ', '');
  if (t.isEmpty) return null;
  if (t.startsWith('=') || RegExp(r'[+*/()]|\d-').hasMatch(t)) return evalExpression(t);
  if (t.contains(',') && t.contains('.')) {
    t = t.replaceAll('.', '').replaceAll(',', '.');
  } else if (t.contains(',')) {
    t = t.replaceAll(',', '.');
  }
  return double.tryParse(t);
}

/// A note's lines on one line, for list rows ("a; b; c").
String oneLine(String note) => note.split(RegExp(r'\r?\n')).map((l) => l.trim()).where((l) => l.isNotEmpty).join('; ');

/// The icons a category can be given in the app (key as stored in the file).
const Map<String, IconData> categoryIcons = {
  'home': Icons.home_outlined,
  'basket': Icons.shopping_basket_outlined,
  'bag': Icons.shopping_bag_outlined,
  'restaurant': Icons.restaurant_outlined,
  'coffee': Icons.local_cafe_outlined,
  'bar': Icons.local_bar_outlined,
  'chair': Icons.chair_outlined,
  'tools': Icons.handyman_outlined,
  'bolt': Icons.bolt_outlined,
  'water': Icons.water_drop_outlined,
  'clothes': Icons.checkroom_outlined,
  'beauty': Icons.content_cut_outlined,
  'health': Icons.favorite_outline,
  'medical': Icons.medical_services_outlined,
  'school': Icons.school_outlined,
  'book': Icons.menu_book_outlined,
  'child': Icons.child_care_outlined,
  'family': Icons.family_restroom_outlined,
  'bus': Icons.directions_bus_outlined,
  'car': Icons.directions_car_outlined,
  'bike': Icons.pedal_bike_outlined,
  'fuel': Icons.local_gas_station_outlined,
  'flight': Icons.flight_takeoff_outlined,
  'hotel': Icons.hotel_outlined,
  'wifi': Icons.wifi_outlined,
  'phone': Icons.smartphone_outlined,
  'tv': Icons.live_tv_outlined,
  'music': Icons.music_note_outlined,
  'game': Icons.sports_esports_outlined,
  'sport': Icons.fitness_center_outlined,
  'work': Icons.work_outline,
  'business': Icons.business_center_outlined,
  'card': Icons.credit_card_outlined,
  'bank': Icons.account_balance_outlined,
  'savings': Icons.savings_outlined,
  'donate': Icons.volunteer_activism_outlined,
  'income': Icons.payments_outlined,
  'gift': Icons.card_giftcard_outlined,
  'celebration': Icons.celebration_outlined,
  'pet': Icons.pets_outlined,
  'tax': Icons.receipt_long_outlined,
  'shield': Icons.shield_outlined,
  'more': Icons.more_horiz,
};

/// The colours offered in the category editor.
const List<Color> categoryPalette = [
  Color(0xFFFF2E7E),
  Color(0xFFD6105E),
  Color(0xFFE0453A),
  Color(0xFFF08A24),
  Color(0xFFD9A400),
  Color(0xFF8DB600),
  Color(0xFF3BA55D),
  Color(0xFF1FA59A),
  Color(0xFF1E9FD6),
  Color(0xFF3A6FE0),
  Color(0xFF5B4FD9),
  Color(0xFF8E4FD6),
  Color(0xFFB23AC2),
  Color(0xFFA0623A),
  Color(0xFF7A7A85),
  Color(0xFF4A5B7A),
];

Color? parseHexColor(String hex) {
  final m = RegExp(r'^#?([0-9a-fA-F]{6})$').firstMatch(hex.trim());
  return m == null ? null : Color(0xFF000000 | int.parse(m.group(1)!, radix: 16));
}

String hexOfColor(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// The colour of a category as the file's settings say, falling back to one
/// derived from the name.
Color categoryColorOf(BuildContext context, String name) =>
    categoryColor(name, Theme.of(context).brightness, hex: AppScope.of(context).budget.file?.category(name)?.color);

/// A stable accent per category: the [hex] chosen in the file, else derived
/// from the name so new categories get a colour without any code change.
Color categoryColor(String name, Brightness brightness, {String? hex}) {
  if (hex != null && hex.isNotEmpty) {
    final c = parseHexColor(hex);
    if (c != null) return c;
  }
  const hues = [335.0, 20.0, 45.0, 90.0, 150.0, 185.0, 210.0, 250.0, 280.0, 310.0];
  var h = 0;
  for (final c in name.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  final hue = hues[h % hues.length];
  final dark = brightness == Brightness.dark;
  return HSLColor.fromAHSL(1, hue, dark ? 0.55 : 0.5, dark ? 0.62 : 0.42).toColor();
}

/// An icon per category, chosen by keywords in its name (German, English and
/// Russian) so a renamed or new category in the file still gets a fitting one.
IconData categoryIcon(BudgetCategory? c, [String? name]) {
  final chosen = categoryIcons[c?.icon ?? ''];
  if (chosen != null) return chosen;
  final n = normalize(name ?? c?.name ?? '');
  const rules = <(List<String>, IconData)>[
    (['wohn', 'miete', 'rent', 'home', 'housing', 'haus ', 'жиль', 'аренд'], Icons.home_outlined),
    (['lebensmittel', 'grocer', 'food', 'essen', 'supermarkt', 'продукт', 'еда'], Icons.shopping_basket_outlined),
    (['restaurant', 'cafe', 'gastro', 'dining', 'ресторан', 'кафе'], Icons.restaurant_outlined),
    (['haushalt', 'household', 'drogerie', 'быт', 'дом '], Icons.chair_outlined),
    (['kleidung', 'cloth', 'schuhe', 'одежд', 'обувь'], Icons.checkroom_outlined),
    (['gesundheit', 'health', 'apotheke', 'arzt', 'medic', 'здоров', 'аптек', 'врач'], Icons.favorite_outline),
    (['schul', 'school', 'kurs', 'bildung', 'education', 'learn', 'обучен', 'школ', 'курс'], Icons.school_outlined),
    (['kinder', 'kids', 'child', 'family', 'familie', 'taschengeld', 'дети', 'детск', 'семь'], Icons.child_care_outlined),
    (['transport', 'verkehr', 'auto', 'ticket', 'bahn', 'fuel', 'tank', 'транспорт', 'авто', 'бензин'], Icons.directions_bus_outlined),
    (['freizeit', 'reise', 'travel', 'urlaub', 'leisure', 'hobby', 'sport', 'отдых', 'поездк', 'путеш', 'спорт'], Icons.flight_takeoff_outlined),
    (['abo', 'internet', 'subscription', 'mobil', 'telefon', 'streaming', 'подписк', 'интернет', 'связь'], Icons.wifi_outlined),
    (['arbeit', 'work', 'job', 'работ'], Icons.work_outline),
    (['business', 'firma', 'unternehmen', 'geschaeft', 'бизнес'], Icons.business_center_outlined),
    (['kreditkarte', 'credit card', 'kredit', 'кредит'], Icons.credit_card_outlined),
    (['bank', 'gebuehr', 'fee', 'zins', 'банк', 'комисси'], Icons.account_balance_outlined),
    (['spende', 'charity', 'donat', 'пожертв', 'благотвор'], Icons.volunteer_activism_outlined),
    (['einnahme', 'income', 'gehalt', 'salary', 'lohn', 'доход', 'зарплат'], Icons.payments_outlined),
    (['sonstig', 'other', 'misc', 'divers', 'проч', 'разно'], Icons.more_horiz),
    (['geschenk', 'gift', 'подарк'], Icons.card_giftcard_outlined),
    (['tier', 'pet', 'питом', 'животн'], Icons.pets_outlined),
    (['steuer', 'tax', 'налог'], Icons.receipt_long_outlined),
    (['versicherung', 'insurance', 'страхов'], Icons.shield_outlined),
  ];
  for (final (keys, icon) in rules) {
    if (keys.any(n.contains)) return icon;
  }
  if (c == null) return Icons.label_outline;
  switch (c.type) {
    case CategoryType.income:
      return Icons.payments_outlined;
    case CategoryType.transfer:
      return Icons.swap_horiz;
    case CategoryType.expense:
      return Icons.label_outline;
  }
}

class CategoryDot extends StatelessWidget {
  const CategoryDot({super.key, required this.name, this.size = 10});
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: categoryColorOf(context, name), shape: BoxShape.circle),
    );
  }
}

/// Colour of an amount: income green, expenses over the entry limits pink.
Color amountColor(BuildContext context, BudgetEntry e, BudgetService budget) {
  final scheme = Theme.of(context).colorScheme;
  final cat = budget.file?.category(e.category);
  if (cat?.isTransfer ?? false) return scheme.onSurfaceVariant;
  if (e.amount < 0) return scheme.tertiary;
  final limits = budget.entryLimits;
  if (limits.length >= 3 && e.amount >= limits[2]) return AzColors.pinkInk;
  if (limits.length >= 2 && e.amount >= limits[1]) return scheme.primary;
  if (limits.isNotEmpty && e.amount >= limits[0]) return scheme.primary;
  return scheme.onSurface;
}

class EntryTile extends StatelessWidget {
  const EntryTile({super.key, required this.entry, this.onTap, this.onLongPress, this.trailing, this.zebra = false, this.dayStart = false});
  final BudgetEntry entry;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget? trailing;

  /// Alternate row shading.
  final bool zebra;

  /// First row of a day: a heavier line above it.
  final bool dayStart;

  @override
  Widget build(BuildContext context) {
    final budget = AppScope.of(context).budget;
    final scheme = Theme.of(context).colorScheme;
    final cat = budget.file?.category(entry.category);
    final isTransfer = cat?.isTransfer ?? false;
    final color = categoryColorOf(context, entry.category);
    return Container(
      decoration: BoxDecoration(
        color: zebra ? scheme.surfaceContainerLow : null,
        border: dayStart ? Border(top: BorderSide(color: scheme.outline, width: 2)) : null,
      ),
      child: ListTile(
      onTap: onTap,
      onLongPress: onLongPress,
      dense: true,
      leading: SizedBox(
        width: 44,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(dateDm(entry.date), style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Icon(categoryIcon(cat, entry.category), size: 16, color: color),
          ],
        ),
      ),
      title: Text(
        entry.description.isEmpty ? entry.category : entry.description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontWeight: FontWeight.w500, fontStyle: isTransfer ? FontStyle.italic : null, color: isTransfer ? scheme.onSurfaceVariant : null),
      ),
      subtitle: Text(
        [entry.category, if (entry.note.isNotEmpty) oneLine(entry.note)].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (entry.isPending)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(Icons.cloud_upload_outlined, size: 16, color: scheme.onSurfaceVariant),
            ),
          Text(
            euro(entry.amount),
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: amountColor(context, entry, budget), fontFeatures: const [FontFeature.tabularFigures()]),
          ),
          ?trailing,
        ],
      ),
      ),
    );
  }
}

class SyncStatusBar extends StatelessWidget {
  const SyncStatusBar({super.key, required this.budget, this.onTap, this.leading});
  final BudgetService budget;
  final VoidCallback? onTap;

  /// Left side of the bar (e.g. the quick-entries toggle).
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: budget,
      builder: (context, _) {
        final (icon, text, color) = switch (budget.state) {
          SyncState.noFolder => (Icons.folder_off_outlined, l.syncNoFolder, scheme.primary),
          SyncState.syncing => (Icons.sync, l.syncSyncing, scheme.onSurfaceVariant),
          SyncState.idle => (Icons.cloud_done_outlined, l.syncIdle(budget.year ?? 0), scheme.tertiary),
          SyncState.offline => (Icons.cloud_off_outlined, l.syncOffline(budget.pending.length), scheme.primary),
          SyncState.error => (Icons.error_outline, budget.lastError ?? l.syncError, scheme.error),
        };
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 8, 4),
          child: Row(
            children: [
              ?leading,
              const Spacer(),
              if (budget.pending.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(l.pendingCount(budget.pending.length), style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                ),
              IconButton(
                tooltip: text,
                visualDensity: VisualDensity.compact,
                icon: Icon(icon, size: 20, color: color),
                onPressed: onTap,
              ),
              if (budget.yearFiles.isNotEmpty)
                DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: budget.year,
                    isDense: true,
                    style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: scheme.onSurface),
                    items: [for (final f in budget.yearFiles) DropdownMenuItem(value: f.year, child: Text('${f.year}'))],
                    onChanged: (y) => y == null ? null : budget.selectYear(y),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Row(
        children: [
          Expanded(child: Text(text, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.2))),
          ?trailing,
        ],
      ),
    );
  }
}

class EmptyHint extends StatelessWidget {
  const EmptyHint({super.key, required this.icon, required this.text, this.action});
  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: scheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)),
            if (action case final a?) ...[const SizedBox(height: 16), a],
          ],
        ),
      ),
    );
  }
}

/// Title row of a dialog with a close cross on the right: every alert can
/// be dismissed without picking an answer (pops with no result).
class DialogTitle extends StatelessWidget {
  const DialogTitle({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: child),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.close),
          visualDensity: VisualDensity.compact,
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
