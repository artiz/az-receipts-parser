/// The yearly budget workbook as a model.
///
/// Layout contract (shared with the Python builder that made the files and
/// with the user's own edits):
/// * `Buchungen`: header row 1, then A Datum, B Monat (formula), C Kategorie,
///   D Beschreibung, E Betrag (€), F Notiz. Rows are pre-formatted to 2000.
/// * `Einstellungen`: categories from the row after the "Kategorie" header
///   (A name, B type, D hint) until the first empty name; settings as
///   label/value pairs in columns F/G. New settings may be appended below.
/// * `Übersicht`: input rows are found by their label in column A
///   (Kontostand…, Sparkonto, Kreditkarte offen…), months in columns B..M;
///   the "Plan" block starts at the row whose A is "Plan" and ends before
///   "Summe Plan".
///
/// Nothing in here is hard-coded to the category names: they come from the
/// file.
library;

import 'dart:typed_data';

import 'xlsx_workbook.dart';

const String sheetEntries = 'Buchungen';
const String sheetOverview = 'Übersicht';
const String sheetSettings = 'Einstellungen';

/// Legacy name of the settings sheet (files before the rename).
const String sheetSettingsLegacy = 'Kategorien';

const String monthFormula = 'IF(A{r}="","",MONTH(A{r}))';

enum CategoryType { expense, income, transfer }

CategoryType categoryTypeFrom(String? label) {
  final l = (label ?? '').trim().toLowerCase();
  if (l.startsWith('einnahme') || l == 'income') return CategoryType.income;
  if (l.startsWith('umbuchung') || l == 'transfer') return CategoryType.transfer;
  return CategoryType.expense;
}

class BudgetCategory {
  const BudgetCategory({required this.name, required this.type, this.hint = '', this.legacyGroups = ''});
  final String name;
  final CategoryType type;
  final String hint;
  final String legacyGroups;

  bool get isExpense => type == CategoryType.expense;
  bool get isIncome => type == CategoryType.income;
  bool get isTransfer => type == CategoryType.transfer;

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

  (int, List<double?>)? byLabelPrefix(String prefix) {
    for (final e in rows.entries) {
      if (e.key.toLowerCase().startsWith(prefix.toLowerCase())) return e.value;
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
    if (wb.sheet(sheetEntries) == null) {
      throw XlsxException('sheet "$sheetEntries" not found: not a Budget file');
    }
    var year = yearHint ?? 0;
    if (year == 0) {
      final title = wb.sheet(sheetOverview)?.readRow(1)['A']?.text ?? '';
      final m = RegExp(r'(20\d\d)').firstMatch(title);
      if (m != null) year = int.parse(m.group(1)!);
    }
    final file = BudgetFile._(wb, year);
    if (file.year == 0 && file.entries.isNotEmpty) {
      return BudgetFile._(wb, file.entries.last.date.year);
    }
    return file;
  }

  XlsxSheet get _settingsSheet =>
      workbook.sheet(sheetSettings) ?? workbook.sheet(sheetSettingsLegacy) ?? (throw XlsxException('sheet "$sheetSettings" not found'));

  BudgetCategory? category(String name) {
    for (final c in categories) {
      if (c.name == name) return c;
    }
    return null;
  }

  List<BudgetCategory> get expenseCategories => categories.where((c) => c.isExpense).toList();

  double? setting(String labelPrefix) {
    for (final s in settings) {
      if (s.label.toLowerCase().startsWith(labelPrefix.toLowerCase())) return s.value;
    }
    return null;
  }

  // --- reading ---------------------------------------------------------------

  List<BudgetCategory> _readCategories() {
    final rows = _settingsSheet.readRows();
    var headerRow = -1;
    for (final (r, cells) in rows) {
      if ((cells['A']?.text ?? '').trim().toLowerCase() == 'kategorie') {
        headerRow = r;
        break;
      }
    }
    if (headerRow < 0) throw XlsxException('"Kategorie" header not found in $sheetSettings');
    final byRow = {for (final (r, cells) in rows) r: cells};
    final out = <BudgetCategory>[];
    for (var r = headerRow + 1; r < headerRow + 200; r++) {
      final cells = byRow[r];
      final name = cells?['A']?.text?.trim();
      if (name == null || name.isEmpty) break;
      out.add(BudgetCategory(
        name: name,
        type: categoryTypeFrom(cells!['B']?.text),
        legacyGroups: cells['C']?.text?.trim() ?? '',
        hint: cells['D']?.text?.trim() ?? '',
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
      if (label.toLowerCase() == 'einstellung' || label.toLowerCase() == 'legende') continue;
      if (value == null) continue;
      out.add(BudgetSetting(label: label, value: value.number, row: r, note: cells['H']?.text ?? ''));
    }
    return out;
  }

  List<BudgetEntry> _readEntries() {
    final out = <BudgetEntry>[];
    for (final (r, cells) in workbook.requireSheet(sheetEntries).readRows()) {
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
    final sheet = workbook.sheet(sheetOverview);
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
      if (label == 'Plan') {
        planHeader = r;
        inPlan = true;
        continue;
      }
      if (inPlan) {
        if (label.startsWith('Summe')) {
          inPlan = false;
        } else {
          plan[label] = (r, values());
        }
        continue;
      }
      final l = label.toLowerCase();
      if (l.startsWith('kontostand') || l.startsWith('sparkonto') || l.startsWith('kreditkarte')) {
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
    final sheet = workbook.requireSheet(sheetEntries);
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

  /// Overwrite an existing entry row in place.
  void updateEntry(int row, BudgetEntry e) {
    final sheet = workbook.requireSheet(sheetEntries);
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
    final sheet = workbook.requireSheet(sheetOverview);
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
    final sheet = workbook.requireSheet(sheetOverview);
    final target = overview.plan[category] ?? (throw XlsxException('plan row "$category" not found'));
    sheet.setNumber('${XlsxRef.columnLetters(1 + month)}${target.$1}', _round2(value));
  }

  /// Add or update a label/value setting in `Einstellungen` (columns F/G).
  void setSetting(String label, double value, {String note = ''}) {
    final sheet = _settingsSheet;
    for (final s in settings) {
      if (s.label.toLowerCase() == label.toLowerCase()) {
        sheet.setNumber('G${s.row}', value);
        return;
      }
    }
    var row = settings.isEmpty ? 5 : settings.map((s) => s.row).reduce((a, b) => a > b ? a : b) + 1;
    // Never overwrite something else that sits in column F.
    while (!(sheet.readRow(row)['F']?.isEmpty ?? true)) {
      row++;
    }
    sheet.setText('F$row', label);
    sheet.setNumber('G$row', value);
    if (note.isNotEmpty) sheet.setText('H$row', note);
  }

  /// Remove every entry row (keeps the pre-formatted rows and their month
  /// formulas) so the file can serve as the template of a new year.
  void clearEntries() {
    final sheet = workbook.requireSheet(sheetEntries);
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
    final sheet = workbook.requireSheet(sheetOverview);
    for (final e in overview.rows.values) {
      for (var m = 1; m <= 12; m++) {
        sheet.clear('${XlsxRef.columnLetters(1 + m)}${e.$1}');
      }
    }
  }

  /// Replace the year in the title cells ("Budget 2026" → "Budget 2027").
  void setTitleYear(int newYear) {
    for (final name in [sheetOverview, sheetSettings, sheetSettingsLegacy]) {
      final sheet = workbook.sheet(name);
      if (sheet == null) continue;
      final a1 = sheet.readRow(1)['A']?.text;
      if (a1 != null && RegExp(r'20\d\d').hasMatch(a1)) {
        sheet.setText('A1', a1.replaceAll(RegExp(r'20\d\d'), '$newYear'));
      }
    }
  }

  Uint8List save() => workbook.save();

  static double _round2(double v) => (v * 100).round() / 100;
}
