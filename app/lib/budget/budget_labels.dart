/// The words the reader looks for in a budget workbook, in the three
/// template languages. Files are found by what the labels *mean*, so a
/// German, English or Russian template, or a user's renamed sheet, all read
/// the same way. Category names are never in here: they come from the file.
library;

class BudgetLabels {
  BudgetLabels._();

  static const List<String> languages = ['de', 'en', 'ru'];

  static const Map<String, String> entriesSheet = {'de': 'Buchungen', 'en': 'Entries', 'ru': 'Записи'};
  static const Map<String, String> overviewSheet = {'de': 'Übersicht', 'en': 'Overview', 'ru': 'Обзор'};
  static const Map<String, String> settingsSheet = {'de': 'Einstellungen', 'en': 'Settings', 'ru': 'Настройки'};
  static const Map<String, String> historySheet = {'de': 'Verlauf', 'en': 'History', 'ru': 'История'};

  /// Settings sheet name of files before the rename.
  static const List<String> legacySettingsSheets = ['Kategorien'];

  static const List<String> categoryHeader = ['kategorie', 'category', 'категория'];
  static const List<String> incomeType = ['einnahme', 'income', 'доход'];
  static const List<String> transferType = ['umbuchung', 'transfer', 'перевод'];
  static const List<String> settingsHeader = ['einstellung', 'setting', 'настройка'];
  static const List<String> legend = ['legende', 'legend', 'легенда', 'eingabe', 'input', 'ввод'];
  static const List<String> plan = ['plan', 'план'];
  static const List<String> total = ['summe', 'total', 'итого'];

  /// The monthly input rows of the overview, one alias group per row.
  static const List<List<String>> inputRows = [
    ['kontostand', 'balance', 'остаток'],
    ['sparkonto', 'savings', 'сберег'],
    ['kreditkarte', 'credit card', 'кредитка'],
  ];

  /// Setting labels, one alias group per setting (German first, which is the
  /// name the app uses in code).
  static const List<List<String>> settings = [
    ['monatslimit', 'month limit', 'месячный лимит'],
    ['ausgabenlimit', 'expense limit', 'лимит записи'],
  ];

  static String _norm(String s) => s.trim().toLowerCase();

  static bool isOneOf(String? text, List<String> words) => text != null && words.contains(_norm(text));

  static bool startsWithOneOf(String? text, List<String> prefixes) {
    if (text == null) return false;
    final n = _norm(text);
    return prefixes.any(n.startsWith);
  }

  static String? languageOfSheet(Map<String, String> names, String? sheet) {
    if (sheet == null) return null;
    for (final e in names.entries) {
      if (_norm(e.value) == _norm(sheet)) return e.key;
    }
    return null;
  }

  /// Every spelling of [prefix] across the alias [groups]: "Monatslimit 1"
  /// → ["monatslimit 1", "month limit 1", "месячный лимит 1"]. A prefix that
  /// belongs to no group comes back alone.
  static List<String> spellings(String prefix, List<List<String>> groups) {
    final n = _norm(prefix);
    for (final group in groups) {
      for (final word in group) {
        if (n.startsWith(word)) {
          final rest = n.substring(word.length);
          return [for (final w in group) '$w$rest'];
        }
      }
    }
    return [n];
  }

  static bool isInputRow(String label) => startsWithOneOf(label, [for (final g in inputRows) ...g]);

  /// Does [label] mean the same as [prefix] (any language)?
  static bool settingMatches(String label, String prefix, {bool exact = false}) {
    final n = _norm(label);
    for (final s in spellings(prefix, settings)) {
      if (exact ? n == s : n.startsWith(s)) return true;
    }
    return false;
  }

  /// [label] as the file language spells it, with the original casing of the
  /// first letter: "Monatslimit 1" in an English file → "Month limit 1".
  static String settingInLanguage(String label, String language) {
    final i = languages.indexOf(language);
    if (i < 0) return label;
    final n = _norm(label);
    for (final group in settings) {
      for (final word in group) {
        if (n.startsWith(word)) {
          final translated = group[i] + n.substring(word.length);
          return translated[0].toUpperCase() + translated.substring(1);
        }
      }
    }
    return label;
  }
}

/// Display name of a template language.
String languageDisplayName(String code) => switch (code) {
  'de' => 'Deutsch',
  'ru' => 'Русский',
  _ => 'English',
};

/// The template language for [preferred] ('' = follow [system]).
String templateLanguage(String preferred, String system) {
  final code = preferred.isEmpty ? system : preferred;
  return BudgetLabels.languages.contains(code) ? code : 'en';
}
