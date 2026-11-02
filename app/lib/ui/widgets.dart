/// Small shared widgets and formatting helpers for the UI.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../categorize/categories.dart';
import '../core/money.dart';
import '../data/database.dart';
import '../l10n/app_localizations.dart';

String localizedCategoryName(AppLocalizations l, String key, {List<Category>? categories}) {
  final custom = categories?.where((c) => c.key == key).map((c) => c.customName).firstOrNull;
  if (custom != null && custom.isNotEmpty) return custom;
  switch (key) {
    case 'groceries':
      return l.categoryGroceries;
    case 'bakery':
      return l.categoryBakery;
    case 'drugstore':
      return l.categoryDrugstore;
    case 'pharmacy':
      return l.categoryPharmacy;
    case 'household':
      return l.categoryHousehold;
    case 'clothing':
      return l.categoryClothing;
    case 'toys':
      return l.categoryToys;
    case 'electronics':
      return l.categoryElectronics;
    case 'books':
      return l.categoryBooks;
    case 'sports':
      return l.categorySports;
    case 'diy':
      return l.categoryDiy;
    case 'restaurant':
      return l.categoryRestaurant;
    case 'fuel':
      return l.categoryFuel;
    case 'transport':
      return l.categoryTransport;
    case 'pets':
      return l.categoryPets;
    case 'health':
      return l.categoryHealth;
    case 'entertainment':
      return l.categoryEntertainment;
    case 'other':
      return l.categoryOther;
  }
  return categoryName(key, l.localeName);
}

String money(int cents, String currency, Locale locale) {
  final f = NumberFormat.currency(locale: locale.toString(), name: currency, symbol: _symbol(currency));
  return f.format(cents / 100);
}

String _symbol(String currency) => switch (currency) {
      'EUR' => '€',
      'USD' => r'$',
      'CHF' => 'CHF',
      _ => currency,
    };

String moneyPlain(int cents) => formatCents(cents);

String dateShort(DateTime d, Locale locale) => DateFormat.yMd(locale.toString()).add_Hm().format(d);

String monthLabel(DateTime d, Locale locale) => DateFormat.yMMMM(locale.toString()).format(d);

class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar({super.key, required this.categoryKey, this.radius = 20});
  final String categoryKey;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final def = categoryDef(categoryKey);
    return CircleAvatar(
      radius: radius,
      backgroundColor: def.color.withValues(alpha: 0.18),
      foregroundColor: def.color,
      child: Icon(def.icon, size: radius * 1.1),
    );
  }
}

class CategoryDropdown extends StatelessWidget {
  const CategoryDropdown({
    super.key,
    required this.value,
    required this.categories,
    required this.onChanged,
    this.dense = false,
    this.label,
  });

  final String value;
  final List<Category> categories;
  final ValueChanged<String> onChanged;
  final bool dense;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final visible = categories.where((c) => !c.hidden || c.key == value).toList();
    final keys = visible.map((c) => c.key).toSet();
    final current = keys.contains(value) ? value : (visible.isNotEmpty ? visible.first.key : otherCategory);
    return DropdownButtonFormField<String>(
      initialValue: current,
      isDense: dense,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        isDense: dense,
        contentPadding: dense ? const EdgeInsets.symmetric(horizontal: 8, vertical: 8) : null,
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final c in visible)
          DropdownMenuItem(
            value: c.key,
            child: Row(
              children: [
                Icon(categoryDef(c.key).icon, size: 18, color: categoryDef(c.key).color),
                const SizedBox(width: 8),
                Expanded(child: Text(localizedCategoryName(l, c.key, categories: categories), overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
