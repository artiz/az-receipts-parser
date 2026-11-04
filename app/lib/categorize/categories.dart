/// Built-in category keys. Display names come from the ARB localisations
/// (`category_<key>`); custom categories carry their own name in the DB.
library;

import 'package:flutter/material.dart';

class CategoryDef {
  const CategoryDef(this.key, this.icon, this.color);
  final String key;
  final IconData icon;
  final Color color;
}

const List<CategoryDef> builtinCategories = [
  CategoryDef('groceries', Icons.shopping_basket_outlined, Color(0xFF2E7D32)),
  CategoryDef('bakery', Icons.bakery_dining_outlined, Color(0xFF8D6E63)),
  CategoryDef('drugstore', Icons.soap_outlined, Color(0xFF00897B)),
  CategoryDef('pharmacy', Icons.medical_services_outlined, Color(0xFFD32F2F)),
  CategoryDef('household', Icons.chair_outlined, Color(0xFF6D4C41)),
  CategoryDef('clothing', Icons.checkroom_outlined, Color(0xFF7B1FA2)),
  CategoryDef('toys', Icons.toys_outlined, Color(0xFFF9A825)),
  CategoryDef('electronics', Icons.devices_other_outlined, Color(0xFF1565C0)),
  CategoryDef('books', Icons.menu_book_outlined, Color(0xFF5D4037)),
  CategoryDef('sports', Icons.sports_soccer_outlined, Color(0xFF00838F)),
  CategoryDef('diy', Icons.handyman_outlined, Color(0xFFEF6C00)),
  CategoryDef('restaurant', Icons.restaurant_outlined, Color(0xFFC62828)),
  CategoryDef('fuel', Icons.local_gas_station_outlined, Color(0xFF455A64)),
  CategoryDef('transport', Icons.directions_bus_outlined, Color(0xFF3949AB)),
  CategoryDef('pets', Icons.pets_outlined, Color(0xFF795548)),
  CategoryDef('health', Icons.favorite_outline, Color(0xFFAD1457)),
  CategoryDef('entertainment', Icons.movie_outlined, Color(0xFF6A1B9A)),
  CategoryDef('other', Icons.category_outlined, Color(0xFF757575)),
];

const String otherCategory = 'other';

CategoryDef categoryDef(String? key) =>
    builtinCategories.firstWhere((c) => c.key == key, orElse: () => builtinCategories.last);

/// Names in the three UI languages for the seed data and the l10n fallback.
const Map<String, Map<String, String>> categoryNames = {
  'groceries': {'en': 'Groceries', 'de': 'Lebensmittel', 'ru': 'Продукты'},
  'bakery': {'en': 'Bakery', 'de': 'Bäckerei', 'ru': 'Выпечка'},
  'drugstore': {'en': 'Drugstore & cosmetics', 'de': 'Drogerie & Kosmetik', 'ru': 'Бытовая химия и косметика'},
  'pharmacy': {'en': 'Pharmacy', 'de': 'Apotheke', 'ru': 'Аптека'},
  'household': {'en': 'Household', 'de': 'Haushalt', 'ru': 'Дом и хозяйство'},
  'clothing': {'en': 'Clothing & shoes', 'de': 'Kleidung & Schuhe', 'ru': 'Одежда и обувь'},
  'toys': {'en': 'Toys & kids', 'de': 'Spielzeug & Kinder', 'ru': 'Игрушки и дети'},
  'electronics': {'en': 'Electronics', 'de': 'Elektronik', 'ru': 'Электроника'},
  'books': {'en': 'Books & office', 'de': 'Bücher & Büro', 'ru': 'Книги и канцелярия'},
  'sports': {'en': 'Sports', 'de': 'Sport', 'ru': 'Спорт'},
  'diy': {'en': 'DIY & garden', 'de': 'Baumarkt & Garten', 'ru': 'Ремонт и сад'},
  'restaurant': {'en': 'Restaurants & cafés', 'de': 'Gastronomie', 'ru': 'Кафе и рестораны'},
  'fuel': {'en': 'Fuel', 'de': 'Tanken', 'ru': 'Топливо'},
  'transport': {'en': 'Transport', 'de': 'Verkehr', 'ru': 'Транспорт'},
  'pets': {'en': 'Pets', 'de': 'Haustiere', 'ru': 'Питомцы'},
  'health': {'en': 'Health', 'de': 'Gesundheit', 'ru': 'Здоровье'},
  'entertainment': {'en': 'Entertainment', 'de': 'Freizeit', 'ru': 'Развлечения'},
  'other': {'en': 'Other', 'de': 'Sonstiges', 'ru': 'Прочее'},
};

String categoryName(String key, String lang, {String? custom}) {
  if (custom != null && custom.isNotEmpty) return custom;
  final names = categoryNames[key];
  if (names == null) return key;
  return names[lang] ?? names['en'] ?? key;
}
