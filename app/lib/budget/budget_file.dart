/// The yearly budget workbook as a model.
///
/// Layout contract (shared with `tools/budget_template.py`, which builds the
/// templates, and with the user's own edits); the sheet and label names are
/// those of the file's language (see [BudgetLabels]), German here:
/// * `Buchungen`: header row 1, then A Datum, B Monat (formula), C Kategorie,
///   D Beschreibung, E Betrag (€), F Notiz. Rows are pre-formatted to 2000.
/// * `Einstellungen`: categories from the row after the "Kategorie" header
///   (A name, B type, D hint, E "icon #colour" as chosen in the app) until
///   the first empty name; settings as label/value pairs in columns F/G.
///   New settings may be appended below.
/// * `Übersicht`: input rows are found by their label in column A
///   (Kontostand…, Sparkonto, Kreditkarte offen…), months in columns B..M;
///   the "Plan" block starts at the row whose A is "Plan" and ends before
///   "Summe Plan".
///
/// Nothing in here is hard-coded to the category names: they come from the
/// file.
library;

import 'dart:typed_data';

import 'budget_labels.dart';
import 'template_texts.dart';
import 'xlsx_workbook.dart';

export 'budget_labels.dart';

/// German sheet names (the names of the files this app started with).
const String sheetEntries = 'Buchungen';
const String sheetOverview = 'Übersicht';
const String sheetSettings = 'Einstellungen';

/// Legacy name of the settings sheet (files before the rename).
const String sheetSettingsLegacy = 'Kategorien';

const String monthFormula = 'IF(A{r}="","",MONTH(A{r}))';

enum CategoryType { expense, income, transfer }

CategoryType categoryTypeFrom(String? label) {
  if (BudgetLabels.startsWithOneOf(label, BudgetLabels.incomeType)) return CategoryType.income;
  if (BudgetLabels.startsWithOneOf(label, BudgetLabels.transferType)) return CategoryType.transfer;
  return CategoryType.expense;
}

class BudgetCategory {
  const BudgetCategory({required this.name, required this.type, this.hint = '', this.legacyGroups = '', this.icon = '', this.color = '', this.row});
  final String name;
  final CategoryType type;
  final String hint;
  final String legacyGroups;

  /// Icon key chosen in the app ('' = by the name's keywords).
  final String icon;

  /// '#RRGGBB' chosen in the app ('' = derived from the name).
  final String color;

  /// Row in the settings sheet (null for a category not read from a file).
  final int? row;

  bool get isExpense => type == CategoryType.expense;
  bool get isIncome => type == CategoryType.income;
  bool get isTransfer => type == CategoryType.transfer;

  BudgetCategory copyWith({String? name, String? hint, String? icon, String? color}) => BudgetCategory(
        name: name ?? this.name,
        type: type,
        hint: hint ?? this.hint,
        legacyGroups: legacyGroups,
        icon: icon ?? this.icon,
        color: color ?? this.color,
        row: row,
      );

  /// Column E as stored: "home #FF2E7E" (either part may be missing).
  String get styleCell => [if (icon.isNotEmpty) icon, if (color.isNotEmpty) color].join(' ');

  static (String icon, String color) parseStyle(String? text) {
    var icon = '';
    var color = '';
    for (final part in (text ?? '').split(RegExp(r'[\s,;]+'))) {
      if (part.isEmpty) continue;
      if (RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(part)) {
        color = part.toUpperCase();
      } else if (icon.isEmpty) {
        icon = part.toLowerCase();
      }
    }
    return (icon, color);
  }

  @override
  String toString() => 'BudgetCategory($name, $type)';
}

class BudgetSetting {
  const BudgetSetting({required this.label, required this.value, required this.row, this.note = ''});
  final String label;
  final double? value;
  final int row;
  final String note;
}

/// One line of `Buchungen`. [row] is the sheet row (null for an entry that is
/// not in the file yet). Expenses are positive, income negative, as in the
/// file.
class BudgetEntry {
  BudgetEntry({
    required this.date,
    required this.category,
    required this.description,
    required this.amount,
    this.note = '',
    this.row,
    this.pendingId,
  });

  final DateTime date;
  final String category;
  final String description;
  final double amount;
  final String note;
  final int? row;

  /// Set while the entry waits in the local queue for the next sync.
  final String? pendingId;

  bool get isPending => pendingId != null;
  int get month => date.month;

  BudgetEntry copyWith({DateTime? date, String? category, String? description, double? amount, String? note, int? row, String? pendingId, bool clearPending = false}) =>
      BudgetEntry(
        date: date ?? this.date,
        category: category ?? this.category,
        description: description ?? this.description,
        amount: amount ?? this.amount,
        note: note ?? this.note,
        row: row ?? this.row,
        pendingId: clearPending ? null : (pendingId ?? this.pendingId),
      );

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String().substring(0, 10),
        'category': category,
        'description': description,
        'amount': amount,
        'note': note,
        if (pendingId != null) 'pendingId': pendingId,
      };

  static BudgetEntry fromJson(Map<String, dynamic> m) => BudgetEntry(
        date: DateTime.parse(m['date'] as String),
        category: m['category'] as String,
        description: (m['description'] as String?) ?? '',
        amount: (m['amount'] as num).toDouble(),
        note: (m['note'] as String?) ?? '',
        pendingId: m['pendingId'] as String?,
      );

  @override
  String toString() => 'BudgetEntry(${date.toIso8601String().substring(0, 10)}, $category, $description, $amount)';
}

/// Monthly input rows of `Übersicht` (values per month 1..12, null = empty).
class OverviewInputs {
  OverviewInputs({required this.rows, required this.plan, required this.planHeaderRow, this.formulas = const {}});

  /// label → (sheet row, 12 values).
  final Map<String, (int, List<double?>)> rows;

  /// label → 12 formulas ("=500+232.23", null when the cell holds a number),
  /// so the app can show how an input was composed.
  final Map<String, List<String?>> formulas;

  /// category → (sheet row, 12 plan values).
  final Map<String, (int, List<double?>)> plan;
  final int? planHeaderRow;

  /// The row whose label starts with [prefix] in any language ("Kontostand"
  /// also finds "Balance at start of month").
  (int, List<double?>)? byLabelPrefix(String prefix) {
    final spellings = BudgetLabels.spellings(prefix, BudgetLabels.inputRows);
    for (final e in rows.entries) {
      final l = e.key.toLowerCase();
      if (spellings.any(l.startsWith)) return e.value;
    }
    return null;
  }
}

class BudgetFile {
  BudgetFile._(this.workbook, this.year);

  final XlsxWorkbook workbook;

  /// Year of the file (from the entries, else from the title cell).
  final int year;

  late final List<BudgetCategory> categories = _readCategories();
  late final List<BudgetSetting> settings = _readSettings();
  late final List<BudgetEntry> entries = _readEntries();
  late final OverviewInputs overview = _readOverview();

  static BudgetFile open(Uint8List bytes, {int? yearHint}) {
    final wb = XlsxWorkbook.open(bytes);
    if (_find(wb, BudgetLabels.entriesSheet.values) == null) {
      throw XlsxException('sheet "$sheetEntries" not found: not a Budget file');
    }
    var year = yearHint ?? 0;
    if (year == 0) {
      final title = _find(wb, BudgetLabels.overviewSheet.values)?.readRow(1)['A']?.text ?? '';
      final m = RegExp(r'(20\d\d)').firstMatch(title);
      if (m != null) year = int.parse(m.group(1)!);
    }
    final file = BudgetFile._(wb, year);
    if (file.year == 0 && file.entries.isNotEmpty) {
      return BudgetFile._(wb, file.entries.last.date.year);
    }
    return file;
  }

  static XlsxSheet? _find(XlsxWorkbook wb, Iterable<String> names) {
    for (final n in names) {
      final s = wb.sheet(n);
      if (s != null) return s;
    }
    return null;
  }

  XlsxSheet get _entriesSheet => _find(workbook, BudgetLabels.entriesSheet.values)!;
  XlsxSheet? get _overviewSheet => _find(workbook, BudgetLabels.overviewSheet.values);
  XlsxSheet get _settingsSheet =>
      _find(workbook, [...BudgetLabels.settingsSheet.values, ...BudgetLabels.legacySettingsSheets]) ?? (throw XlsxException('sheet "$sheetSettings" not found'));
  XlsxSheet? get _historySheet => _find(workbook, BudgetLabels.historySheet.values);

  /// Language of the file ('de', 'en', 'ru'): the language of its category
  /// header (which a translation changes), else of its entries sheet name;
  /// German for anything unknown.
  late final String language = _headerLanguage() ?? BudgetLabels.languageOfSheet(BudgetLabels.entriesSheet, _entriesSheet.name) ?? 'de';

  String? _headerLanguage() {
    final row = _categoryHeaderRow;
    if (row < 0) return null;
    final header = _settingsSheet.readRow(row)['A']?.text?.trim().toLowerCase();
    for (final lang in BudgetLabels.languages) {
      if (templateTexts[lang]!['cat_cols.0']!.toLowerCase() == header) return lang;
    }
    return null;
  }

  late final int _categoryHeaderRow = () {
    for (final (r, cells) in _settingsSheet.readRows()) {
      if (BudgetLabels.isOneOf(cells['A']?.text, BudgetLabels.categoryHeader)) return r;
    }
    return -1;
  }();

  BudgetCategory? category(String name) {
    for (final c in categories) {
      if (c.name == name) return c;
    }
    return null;
  }

  List<BudgetCategory> get expenseCategories => categories.where((c) => c.isExpense).toList();

  /// Value of the setting whose label starts with [labelPrefix], in any
  /// language ("Monatslimit 1" also finds "Month limit 1").
  double? setting(String labelPrefix) {
    for (final s in settings) {
      if (BudgetLabels.settingMatches(s.label, labelPrefix)) return s.value;
    }
    return null;
  }

  // --- reading ---------------------------------------------------------------

  List<BudgetCategory> _readCategories() {
    final headerRow = _categoryHeaderRow;
    if (headerRow < 0) throw XlsxException('"Kategorie" header not found in $sheetSettings');
    final byRow = {for (final (r, cells) in _settingsSheet.readRows()) r: cells};
    final out = <BudgetCategory>[];
    for (var r = headerRow + 1; r < headerRow + 200; r++) {
      final cells = byRow[r];
      final name = cells?['A']?.text?.trim();
      if (name == null || name.isEmpty) break;
      final (icon, color) = BudgetCategory.parseStyle(cells!['E']?.text);
      out.add(BudgetCategory(
        name: name,
        type: categoryTypeFrom(cells['B']?.text),
        legacyGroups: cells['C']?.text?.trim() ?? '',
        hint: cells['D']?.text?.trim() ?? '',
        icon: icon,
        color: color,
        row: r,
      ));
    }
    return out;
  }

  List<BudgetSetting> _readSettings() {
    final out = <BudgetSetting>[];
    for (final (r, cells) in _settingsSheet.readRows()) {
      final label = cells['F']?.text?.trim();
      if (label == null || label.isEmpty) continue;
      final value = cells['G'];
      if (BudgetLabels.isOneOf(label, BudgetLabels.settingsHeader) || BudgetLabels.isOneOf(label, BudgetLabels.legend)) continue;
      if (value == null) continue;
      out.add(BudgetSetting(label: label, value: value.number, row: r, note: cells['H']?.text ?? ''));
    }
    return out;
  }

  List<BudgetEntry> _readEntries() {
    final out = <BudgetEntry>[];
    for (final (r, cells) in _entriesSheet.readRows()) {
      if (r < 2) continue;
      final a = cells['A'];
      if (a == null || a.number == null) continue;
      final amount = cells['E']?.number;
      final category = cells['C']?.text?.trim() ?? '';
      if (amount == null && category.isEmpty) continue;
      out.add(BudgetEntry(
        date: XlsxDate.fromSerial(a.number!),
        category: category,
        description: cells['D']?.text?.trim() ?? '',
        amount: amount ?? 0,
        note: cells['F']?.text?.trim() ?? '',
        row: r,
      ));
    }
    return out;
  }

  OverviewInputs _readOverview() {
    final sheet = _overviewSheet;
    if (sheet == null) return OverviewInputs(rows: const {}, plan: const {}, planHeaderRow: null);
    final rows = sheet.readRows();
    final inputs = <String, (int, List<double?>)>{};
    final formulas = <String, List<String?>>{};
    final plan = <String, (int, List<double?>)>{};
    int? planHeader;
    var inPlan = false;
    for (final (r, cells) in rows) {
      final label = cells['A']?.text?.trim() ?? '';
      if (label.isEmpty) continue;
      List<double?> values() => [for (var m = 1; m <= 12; m++) cells[XlsxRef.columnLetters(1 + m)]?.number];
      if (BudgetLabels.isOneOf(label, BudgetLabels.plan)) {
        planHeader = r;
        inPlan = true;
        continue;
      }
      if (inPlan) {
        if (BudgetLabels.startsWithOneOf(label, BudgetLabels.total)) {
          inPlan = false;
        } else {
          plan[label] = (r, values());
        }
        continue;
      }
      if (BudgetLabels.isInputRow(label)) {
        // Input rows: typed numbers or the user's own sums ("=500+232.23");
        // cell references would mean a computed row, which is not an input.
        final fs = [for (var m = 1; m <= 12; m++) cells[XlsxRef.columnLetters(1 + m)]?.formula];
        final computed = fs.any((f) => f != null && RegExp(r'[A-Za-z]').hasMatch(f));
        if (!computed) {
          inputs[label] = (r, values());
          formulas[label] = [for (final f in fs) f == null ? null : '=$f'];
        }
      }
    }
    return OverviewInputs(rows: inputs, plan: plan, planHeaderRow: planHeader, formulas: formulas);
  }

  // --- writing ---------------------------------------------------------------

  /// Append entries as new rows after the last used one. Returns the rows
  /// they landed in.
  List<int> appendEntries(List<BudgetEntry> newEntries) {
    final sheet = _entriesSheet;
    var row = sheet.lastRowWithValue('A');
    if (row < 1) row = 1;
    final placed = <int>[];
    for (final e in newEntries) {
      row += 1;
      sheet.setNumber('A$row', XlsxDate.toSerial(e.date));
      sheet.ensureMonthFormula(row, monthFormula);
      sheet.setText('C$row', e.category);
      sheet.setText('D$row', e.description);
      sheet.setNumber('E$row', _round2(e.amount));
      if (e.note.isNotEmpty) {
        sheet.setText('F$row', e.note);
      } else {
        sheet.clear('F$row');
      }
      placed.add(row);
    }
    sheet.ensureDimension(row, 'F');
    return placed;
  }

  /// Blank an entry row (the row stays, empty, so no other row moves).
  void clearEntryRow(int row) {
    final sheet = _entriesSheet;
    for (final col in ['A', 'C', 'D', 'E', 'F']) {
      sheet.clear('$col$row');
    }
  }

  /// Remove an entry row: every later entry moves up one slot (blank rows
  /// in between are compacted away) and the last used row is cleared. The
  /// pre-formatted rows, their styles and month formulas stay where they are.
  void deleteEntryRow(int row) {
    final later = [for (final e in entries) if (e.row != null && e.row! > row) e]..sort((a, b) => a.row!.compareTo(b.row!));
    var target = row;
    for (final e in later) {
      updateEntry(target, e);
      target = e.row!;
    }
    clearEntryRow(target);
  }

  /// Overwrite an existing entry row in place.
  void updateEntry(int row, BudgetEntry e) {
    final sheet = _entriesSheet;
    sheet.setNumber('A$row', XlsxDate.toSerial(e.date));
    sheet.setText('C$row', e.category);
    sheet.setText('D$row', e.description);
    sheet.setNumber('E$row', _round2(e.amount));
    if (e.note.isNotEmpty) {
      sheet.setText('F$row', e.note);
    } else {
      sheet.clear('F$row');
    }
  }

  /// Set a monthly input (Kontostand, Sparkonto, Kreditkarte offen) in
  /// `Übersicht`; [month] 1..12.
  /// [formula] ("=500+232.23") is stored next to the computed [value] so the
  /// spreadsheet keeps the composition of the number.
  void setOverviewInput(String labelPrefix, int month, double? value, {String? formula}) {
    final sheet = _overviewSheet ?? (throw XlsxException('sheet "$sheetOverview" not found'));
    final target = overview.byLabelPrefix(labelPrefix) ?? (throw XlsxException('row "$labelPrefix" not found in $sheetOverview'));
    final ref = '${XlsxRef.columnLetters(1 + month)}${target.$1}';
    if (value == null) {
      sheet.clear(ref);
    } else if (formula != null) {
      sheet.setFormula(ref, formula, _round2(value));
    } else {
      sheet.setNumber(ref, _round2(value));
    }
  }

  /// Set a plan value for a category and month.
  void setPlan(String category, int month, double value) {
    final sheet = _overviewSheet ?? (throw XlsxException('sheet "$sheetOverview" not found'));
    final target = overview.plan[category] ?? (throw XlsxException('plan row "$category" not found'));
    sheet.setNumber('${XlsxRef.columnLetters(1 + month)}${target.$1}', _round2(value));
  }

  /// Add or update a label/value setting in `Einstellungen` (columns F/G).
  /// [label] is matched in any language; a new row gets the label in the
  /// file's language.
  void setSetting(String label, double value, {String note = ''}) {
    final sheet = _settingsSheet;
    for (final s in settings) {
      if (BudgetLabels.settingMatches(s.label, label, exact: true)) {
        sheet.setNumber('G${s.row}', value);
        return;
      }
    }
    label = BudgetLabels.settingInLanguage(label, language);
    var row = settings.isEmpty ? 5 : settings.map((s) => s.row).reduce((a, b) => a > b ? a : b) + 1;
    // Never overwrite something else that sits in column F.
    while (!(sheet.readRow(row)['F']?.isEmpty ?? true)) {
      row++;
    }
    sheet.setText('F$row', label);
    sheet.setNumber('G$row', value);
    if (note.isNotEmpty) sheet.setText('H$row', note);
  }

  // --- categories -------------------------------------------------------------

  /// Change a category's name, hint, icon or colour in its settings row. A
  /// renamed category is renamed everywhere: the bookings, the overview
  /// labels and the formulas and conditional formats that quote the name.
  void updateCategory(BudgetCategory old, BudgetCategory updated) {
    final row = old.row ?? (throw XlsxException('category "${old.name}" is not in the file'));
    final sheet = _settingsSheet;
    final newName = updated.name.trim();
    if (newName.isEmpty) throw XlsxException('empty category name');
    if (newName != old.name) {
      if (categories.any((c) => c.name == newName)) throw XlsxException('category "$newName" exists already');
      _renameCategory(old.name, newName);
    }
    final hint = updated.hint.trim();
    if (hint != old.hint) {
      hint.isEmpty ? sheet.clear('D$row') : sheet.setText('D$row', hint);
    }
    final style = updated.styleCell;
    if (style != old.styleCell) {
      style.isEmpty ? sheet.clear('E$row') : sheet.setText('E$row', style);
      final header = 'E$_categoryHeaderRow';
      if (sheet.readRow(_categoryHeaderRow)['E']?.text?.trim().isEmpty ?? true) {
        sheet.setText(header, templateTexts[language]!['cat_cols.4']!);
      }
    }
  }

  /// Rename a category in every place the name is written out: the settings
  /// row, booking rows, overview labels, formulas quoting the name
  /// (`"<>Einnahmen"`) and the entries sheet's conditional formats.
  void _renameCategory(String from, String to) {
    final settingsSheet = _settingsSheet;
    for (final c in categories) {
      if (c.name == from && c.row != null) settingsSheet.setText('A${c.row}', to);
    }
    final entriesSheet = _entriesSheet;
    for (final e in entries) {
      if (e.category == from && e.row != null) entriesSheet.setText('C${e.row}', to);
    }
    entriesSheet.replaceInConditionalFormatting('"$from"', '"$to"');
    final overview = _overviewSheet;
    if (overview != null) {
      final quoted = RegExp('("(?:<>)?)${RegExp.escape(from)}"');
      for (final (r, cells) in overview.readRows()) {
        for (final e in cells.entries) {
          final ref = '${e.key}$r';
          final f = e.value.formula;
          if (f != null) {
            // No cached value: the old one is stale and LibreOffice would show it.
            if (quoted.hasMatch(f)) overview.setFormula(ref, f.replaceAllMapped(quoted, (m) => '${m[1]}$to"'));
          } else if (e.value.text?.trim() == from) {
            overview.setText(ref, to);
          }
        }
      }
    }
  }

  /// Translate the file's template texts (category names and hints, type
  /// labels, settings labels, overview and history labels) into [target]
  /// ('de', 'en', 'ru'); bookings follow the renamed categories. Texts that
  /// are not in any template (the user's own) stay. Sheet names stay too:
  /// formulas refer to them. Returns the number of changed cells.
  int translateTo(String target) {
    final texts = templateTexts[target] ?? (throw XlsxException('no template texts for "$target"'));
    final reverse = <String, String>{};
    for (final e in templateTexts.entries) {
      if (e.key == target) continue;
      for (final t in e.value.entries) {
        if (t.key.startsWith('types.') || t.value.isEmpty) continue;
        reverse.putIfAbsent(t.value, () => t.key);
      }
    }
    var changed = 0;
    final settingsSheet = _settingsSheet;
    for (final c in categories) {
      final row = c.row!;
      final nameKey = reverse[c.name];
      final newName = nameKey == null ? null : texts[nameKey];
      if (newName != null && newName != c.name && !categories.any((o) => o.name == newName)) {
        _renameCategory(c.name, newName);
        changed++;
      }
      final hintKey = reverse[c.hint];
      final newHint = hintKey == null ? null : texts[hintKey];
      if (newHint != null && newHint != c.hint) {
        settingsSheet.setText('D$row', newHint);
        changed++;
      }
      final typeLabel = texts['types.${c.type.index}']!;
      if (settingsSheet.readRow(row)['B']?.text?.trim() != typeLabel) {
        settingsSheet.setText('B$row', typeLabel);
        changed++;
      }
    }
    for (final sheet in [_overviewSheet, settingsSheet, _historySheet]) {
      if (sheet == null) continue;
      for (final (r, cells) in sheet.readRows()) {
        for (final e in cells.entries) {
          final t = e.value.text?.trim();
          if (t == null || t.isEmpty || e.value.formula != null) continue;
          final key = reverse[t];
          if (key == null) continue;
          final n = texts[key]!;
          if (n == t) continue;
          sheet.setText('${e.key}$r', n);
          changed++;
        }
      }
    }
    return changed;
  }

  /// Remove every entry row (keeps the pre-formatted rows and their month
  /// formulas) so the file can serve as the template of a new year.
  void clearEntries() {
    final sheet = _entriesSheet;
    for (final e in entries) {
      final r = e.row;
      if (r == null) continue;
      for (final col in ['A', 'C', 'D', 'E', 'F']) {
        sheet.clear('$col$r');
      }
    }
  }

  /// Clear the monthly inputs of `Übersicht` (Kontostand, Sparkonto,
  /// Kreditkarte offen) for a fresh year.
  void clearOverviewInputs() {
    final sheet = _overviewSheet;
    if (sheet == null) return;
    for (final e in overview.rows.values) {
      for (var m = 1; m <= 12; m++) {
        sheet.clear('${XlsxRef.columnLetters(1 + m)}${e.$1}');
      }
    }
  }

  /// Replace the year in the title cells ("Budget 2026" → "Budget 2027") and
  /// in the month labels of the history sheet ("2026-01" → "2027-01").
  void setTitleYear(int newYear) {
    final year = RegExp(r'20\d\d');
    for (final sheet in [_overviewSheet, _settingsSheet, _historySheet]) {
      if (sheet == null) continue;
      final a1 = sheet.readRow(1)['A']?.text;
      if (a1 != null && year.hasMatch(a1)) {
        sheet.setText('A1', a1.replaceAll(year, '$newYear'));
      }
    }
    final history = _historySheet;
    if (history != null) {
      final monthLabel = RegExp(r'^20\d\d-\d\d$');
      for (final (r, cells) in history.readRows()) {
        final a = cells['A']?.text?.trim();
        if (a != null && monthLabel.hasMatch(a)) history.setText('A$r', '$newYear${a.substring(4)}');
      }
    }
  }

  Uint8List save() => workbook.save();

  static double _round2(double v) => (v * 100).round() / 100;
}
