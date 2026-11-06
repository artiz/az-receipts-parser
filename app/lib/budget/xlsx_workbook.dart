/// Minimal xlsx access at the zip + XML level.
///
/// The yearly `Budget <year>.xlsx` is the database. It also carries formulas,
/// conditional formats, a table, data validation, comments and charts that a
/// generic spreadsheet library would drop on re-save. So the app never
/// re-serialises the workbook: it reads the sheet XML it needs, and when it
/// writes it patches individual `<c>` cells (new rows in `Buchungen`, input
/// cells in `Übersicht`) and leaves every other zip entry byte-for-byte as it
/// was.
///
/// Supported cell kinds: numbers, shared strings, inline strings, formula
/// strings, booleans. Dates are numbers in Excel's 1900 serial system.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

class XlsxException implements Exception {
  XlsxException(this.message);
  final String message;
  @override
  String toString() => 'XlsxException: $message';
}

/// A cell value as read from a sheet: [number] xor [text] (either may be null
/// for an empty cell). [formula] is kept so callers can tell inputs apart.
class XlsxCell {
  const XlsxCell({this.number, this.text, this.formula});
  final double? number;
  final String? text;
  final String? formula;

  /// No value and no formula (a formula without a cached value still counts
  /// as content: openpyxl writes formulas that way).
  bool get isEmpty => number == null && (text == null || text!.isEmpty) && formula == null;

  /// Text for display: numbers as-is, strings as-is.
  String? get asString => text ?? number?.toString();
}

/// Excel's serial day number (1900 system) ↔ dates. Serial 1 = 1900-01-01;
/// the 1900 leap-year bug means the epoch is 1899-12-30.
class XlsxDate {
  static final DateTime _epoch = DateTime.utc(1899, 12, 30);

  static DateTime fromSerial(double serial) {
    final days = serial.floor();
    final d = _epoch.add(Duration(days: days));
    return DateTime(d.year, d.month, d.day);
  }

  static int toSerial(DateTime date) {
    final utc = DateTime.utc(date.year, date.month, date.day);
    return utc.difference(_epoch).inDays;
  }
}

/// Column letters ↔ 1-based index.
class XlsxRef {
  static int columnIndex(String letters) {
    var n = 0;
    for (final c in letters.toUpperCase().codeUnits) {
      n = n * 26 + (c - 64);
    }
    return n;
  }

  static String columnLetters(int index) {
    var n = index;
    final buf = <int>[];
    while (n > 0) {
      final rem = (n - 1) % 26;
      buf.insert(0, 65 + rem);
      n = (n - 1) ~/ 26;
    }
    return String.fromCharCodes(buf);
  }

  static final _re = RegExp(r'^([A-Z]+)(\d+)$');

  /// ("C", 12) for "C12".
  static (String, int) split(String ref) {
    final m = _re.firstMatch(ref);
    if (m == null) throw XlsxException('bad cell reference $ref');
    return (m.group(1)!, int.parse(m.group(2)!));
  }
}

class XlsxSheet {
  XlsxSheet._(this.name, this.path, this._workbook);

  final String name;

  /// Zip entry path, e.g. `xl/worksheets/sheet1.xml`.
  final String path;
  final XlsxWorkbook _workbook;

  XmlDocument? _doc;
  bool _dirty = false;

  XmlDocument get _document => _doc ??= XmlDocument.parse(_workbook._entryText(path));

  XmlElement get _sheetData =>
      _document.rootElement.findElements('sheetData').firstOrNull ??
      (throw XlsxException('sheet $name has no sheetData'));

  /// Every cell of the sheet, keyed by reference ("A1").
  Map<String, XlsxCell> readCells() {
    final out = <String, XlsxCell>{};
    for (final row in _sheetData.findElements('row')) {
      for (final c in row.findElements('c')) {
        final ref = c.getAttribute('r');
        if (ref == null) continue;
        out[ref] = _readCell(c);
      }
    }
    return out;
  }

  /// Cells of one row (1-based), keyed by column letters.
  Map<String, XlsxCell> readRow(int rowIndex) {
    final row = _findRow(rowIndex);
    if (row == null) return const {};
    final out = <String, XlsxCell>{};
    for (final c in row.findElements('c')) {
      final ref = c.getAttribute('r');
      if (ref == null) continue;
      out[XlsxRef.split(ref).$1] = _readCell(c);
    }
    return out;
  }

  /// Rows that have at least one non-empty cell, in sheet order.
  List<(int, Map<String, XlsxCell>)> readRows() {
    final out = <(int, Map<String, XlsxCell>)>[];
    for (final row in _sheetData.findElements('row')) {
      final r = int.tryParse(row.getAttribute('r') ?? '');
      if (r == null) continue;
      final cells = <String, XlsxCell>{};
      for (final c in row.findElements('c')) {
        final ref = c.getAttribute('r');
        if (ref == null) continue;
        final cell = _readCell(c);
        if (!cell.isEmpty) cells[XlsxRef.split(ref).$1] = cell;
      }
      if (cells.isNotEmpty) out.add((r, cells));
    }
    return out;
  }

  XlsxCell _readCell(XmlElement c) {
    final t = c.getAttribute('t');
    final f = c.findElements('f').firstOrNull?.innerText;
    final v = c.findElements('v').firstOrNull?.innerText;
    switch (t) {
      case 's':
        final idx = int.tryParse(v ?? '');
        return XlsxCell(text: idx == null ? null : _workbook.sharedString(idx), formula: f);
      case 'inlineStr':
        final text = c.findElements('is').map((is_) => is_.findAllElements('t').map((t) => t.innerText).join()).join();
        return XlsxCell(text: text, formula: f);
      case 'str':
        return XlsxCell(text: v, formula: f);
      case 'b':
        return XlsxCell(number: v == '1' ? 1 : 0, formula: f);
      case 'e':
        return XlsxCell(text: v, formula: f);
      default:
        return XlsxCell(number: v == null ? null : double.tryParse(v), formula: f);
    }
  }

  Map<int, XmlElement>? _rowIndex;

  XmlElement? _findRow(int rowIndex) {
    var index = _rowIndex;
    if (index == null) {
      index = _rowIndex = {};
      for (final row in _sheetData.findElements('row')) {
        final r = int.tryParse(row.getAttribute('r') ?? '');
        if (r != null) index[r] = row;
      }
    }
    return index[rowIndex];
  }

  /// Highest row index that has a non-empty cell in [column].
  int lastRowWithValue(String column) {
    var last = 0;
    for (final row in _sheetData.findElements('row')) {
      final r = int.tryParse(row.getAttribute('r') ?? '');
      if (r == null) continue;
      for (final c in row.findElements('c')) {
        final ref = c.getAttribute('r');
        if (ref == null || XlsxRef.split(ref).$1 != column) continue;
        if (!_readCell(c).isEmpty) last = r;
      }
    }
    return last;
  }

  // --- writing -----------------------------------------------------------------

  /// Set a numeric value (also used for dates via [XlsxDate.toSerial]).
  void setNumber(String ref, num value) => _setCell(ref, number: value);

  /// Set a text value as an inline string (no shared-string table edits).
  void setText(String ref, String value) => _setCell(ref, text: value);

  /// Clear a cell's value (keeps its style).
  void clear(String ref) => _setCell(ref);

  /// Store a formula (without the leading '=') together with its computed
  /// value, so readers that do not recalculate still see the number. Without
  /// [cached] the cell has no value, which makes every reader (LibreOffice
  /// included, which otherwise trusts cached values) compute it on load.
  void setFormula(String ref, String formula, [num? cached]) => _setCell(ref, number: cached, formula: formula.startsWith('=') ? formula.substring(1) : formula);

  void _setCell(String ref, {num? number, String? text, String? formula}) {
    final (col, rowIndex) = XlsxRef.split(ref);
    final row = _findRow(rowIndex) ?? _insertRow(rowIndex);
    var cell = row.findElements('c').where((c) => c.getAttribute('r') == ref).firstOrNull;
    cell ??= _insertCell(row, ref, col, rowIndex);
    // Drop the old content but keep the style attribute.
    cell.children.clear();
    cell.removeAttribute('t');
    if (formula != null) {
      cell.children.add(XmlElement(XmlName('f'), [], [XmlText(formula)]));
    }
    if (number != null) {
      cell.children.add(XmlElement(XmlName('v'), [], [XmlText(_formatNumber(number))]));
    } else if (text != null) {
      cell.setAttribute('t', 'inlineStr');
      final t = XmlElement(XmlName('t'), [], [XmlText(text)]);
      if (text.startsWith(' ') || text.endsWith(' ')) {
        t.setAttribute('xml:space', 'preserve');
      }
      cell.children.add(XmlElement(XmlName('is'), [], [t]));
    }
    _dirty = true;
  }

  static String _formatNumber(num v) {
    if (v is int || v == v.roundToDouble()) return v.toInt().toString();
    return v.toString();
  }

  XmlElement _insertRow(int rowIndex) {
    final sheetData = _sheetData;
    final row = XmlElement(XmlName('row'), [XmlAttribute(XmlName('r'), '$rowIndex')]);
    XmlElement? before;
    for (final r in sheetData.findElements('row')) {
      final ri = int.tryParse(r.getAttribute('r') ?? '') ?? 0;
      if (ri > rowIndex) {
        before = r;
        break;
      }
    }
    if (before == null) {
      sheetData.children.add(row);
    } else {
      sheetData.children.insert(sheetData.children.indexOf(before), row);
    }
    _rowIndex?[rowIndex] = row;
    return row;
  }

  XmlElement _insertCell(XmlElement row, String ref, String col, int rowIndex) {
    final cell = XmlElement(XmlName('c'), [XmlAttribute(XmlName('r'), ref)]);
    // Inherit the style of the same column in the row above so new rows look
    // like the existing ones (number formats, font).
    final above = _findRow(rowIndex - 1)
        ?.findElements('c')
        .where((c) => c.getAttribute('r') == '$col${rowIndex - 1}')
        .firstOrNull;
    final style = above?.getAttribute('s');
    if (style != null) cell.setAttribute('s', style);
    final colIdx = XlsxRef.columnIndex(col);
    XmlElement? before;
    for (final c in row.findElements('c')) {
      final r = c.getAttribute('r');
      if (r == null) continue;
      if (XlsxRef.columnIndex(XlsxRef.split(r).$1) > colIdx) {
        before = c;
        break;
      }
    }
    if (before == null) {
      row.children.add(cell);
    } else {
      row.children.insert(row.children.indexOf(before), cell);
    }
    return cell;
  }

  /// Replace [from] by [to] in every conditional-formatting formula of the
  /// sheet (a rule like `$C2="Kreditkarte"` follows a renamed category).
  int replaceInConditionalFormatting(String from, String to) {
    var n = 0;
    for (final cf in _document.rootElement.findElements('conditionalFormatting')) {
      for (final f in cf.findAllElements('formula')) {
        final text = f.innerText;
        if (!text.contains(from)) continue;
        f.children.clear();
        f.children.add(XmlText(text.replaceAll(from, to)));
        n++;
      }
    }
    if (n > 0) _dirty = true;
    return n;
  }

  /// Copy every conditional-formatting block whose formula contains [from]
  /// (e.g. `"Kreditkarte"`) with [to] in its place, so a new transfer
  /// category gets the same look as the existing one. Returns the count.
  int cloneConditionalFormatting(String from, String to) {
    var n = 0;
    final root = _document.rootElement;
    for (final cf in root.findElements('conditionalFormatting').toList()) {
      if (!cf.findAllElements('formula').any((f) => f.innerText.contains(from))) continue;
      final copy = cf.copy();
      for (final f in copy.findAllElements('formula')) {
        final text = f.innerText;
        f.children.clear();
        f.children.add(XmlText(text.replaceAll(from, to)));
      }
      root.children.insert(root.children.indexOf(cf) + 1, copy);
      n++;
    }
    if (n > 0) _dirty = true;
    return n;
  }

  /// Remove every conditional-formatting block whose formula contains [text].
  int removeConditionalFormatting(String text) {
    var n = 0;
    final root = _document.rootElement;
    for (final cf in root.findElements('conditionalFormatting').toList()) {
      if (!cf.findAllElements('formula').any((f) => f.innerText.contains(text))) continue;
      root.children.remove(cf);
      n++;
    }
    if (n > 0) _dirty = true;
    return n;
  }

  /// Grow every list validation of the form `$A$5:$A$22` to end at
  /// [lastRow] (the category dropdown follows an added category).
  int extendListValidations(int lastRow) {
    var n = 0;
    final range = RegExp(r'(\$A\$\d+:\$A\$)(\d+)');
    for (final dv in _document.rootElement.findAllElements('dataValidation')) {
      for (final f in dv.findElements('formula1')) {
        final text = f.innerText;
        final m = range.firstMatch(text);
        if (m == null || int.parse(m.group(2)!) >= lastRow) continue;
        f.children.clear();
        f.children.add(XmlText(text.replaceFirst(range, '${m.group(1)}$lastRow')));
        n++;
      }
    }
    if (n > 0) _dirty = true;
    return n;
  }

  /// Turn text wrapping off for every cell of [col] (and the column's own
  /// default style): each wrapped style is swapped for an unwrapped copy, so
  /// other columns that share the style keep it. The height Excel stored
  /// for a wrapped row is dropped unless the user set it by hand. Returns
  /// the number of changed cells and column entries.
  int unwrapColumn(String col) {
    var n = 0;
    final colIdx = XlsxRef.columnIndex(col);
    for (final cols in _document.rootElement.findElements('cols')) {
      for (final c in cols.findElements('col').toList()) {
        final min = int.tryParse(c.getAttribute('min') ?? '');
        final max = int.tryParse(c.getAttribute('max') ?? '');
        final s = int.tryParse(c.getAttribute('style') ?? '');
        if (min == null || max == null || s == null || colIdx < min || colIdx > max) continue;
        final u = _workbook.unwrappedStyle(s);
        if (u == s) continue;
        // Split a range so only this column changes.
        final at = cols.children.indexOf(c);
        final parts = <XmlElement>[];
        if (min < colIdx) parts.add(c.copy()..setAttribute('max', '${colIdx - 1}'));
        parts.add(c.copy()
          ..setAttribute('min', '$colIdx')
          ..setAttribute('max', '$colIdx')
          ..setAttribute('style', '$u'));
        if (max > colIdx) parts.add(c.copy()..setAttribute('min', '${colIdx + 1}'));
        cols.children.removeAt(at);
        cols.children.insertAll(at, parts);
        n++;
      }
    }
    for (final row in _sheetData.findElements('row')) {
      for (final c in row.findElements('c')) {
        final ref = c.getAttribute('r');
        if (ref == null || XlsxRef.split(ref).$1 != col) continue;
        final s = int.tryParse(c.getAttribute('s') ?? '');
        if (s == null) continue;
        final u = _workbook.unwrappedStyle(s);
        if (u == s) continue;
        c.setAttribute('s', '$u');
        final custom = row.getAttribute('customHeight');
        if (custom != '1' && custom != 'true') row.removeAttribute('ht');
        n++;
      }
    }
    if (n > 0) _dirty = true;
    return n;
  }

  /// Ensure column B of [rowIndex] carries the month formula the template
  /// pre-fills (rows beyond the pre-filled range need it).
  void ensureMonthFormula(int rowIndex, String formulaTemplate) {
    final row = _findRow(rowIndex) ?? _insertRow(rowIndex);
    final ref = 'B$rowIndex';
    var cell = row.findElements('c').where((c) => c.getAttribute('r') == ref).firstOrNull;
    if (cell != null && cell.findElements('f').isNotEmpty) return;
    cell ??= _insertCell(row, ref, 'B', rowIndex);
    cell.children.clear();
    cell.removeAttribute('t');
    cell.children.add(XmlElement(XmlName('f'), [], [XmlText(formulaTemplate.replaceAll('{r}', '$rowIndex'))]));
    _dirty = true;
  }

  /// Grow `<dimension ref>` when rows were added past it.
  void ensureDimension(int lastRow, String lastColumn) {
    final dim = _document.rootElement.findElements('dimension').firstOrNull;
    if (dim == null) return;
    final ref = dim.getAttribute('ref') ?? '';
    final parts = ref.split(':');
    if (parts.length != 2) return;
    final (_, endRow) = XlsxRef.split(parts[1]);
    if (lastRow > endRow) {
      dim.setAttribute('ref', '${parts[0]}:$lastColumn$lastRow');
      _dirty = true;
    }
  }

  String? _serialize() => _dirty ? _document.toXmlString() : null;
}

class XlsxWorkbook {
  XlsxWorkbook._(this._archive, this._bytes);

  final Archive _archive;
  final Uint8List _bytes;
  final Map<String, XlsxSheet> _sheets = {};
  List<String>? _sharedStrings;
  final Map<String, String> _replacedEntries = {};
  XmlDocument? _styles;
  bool _stylesDirty = false;
  final Map<int, int> _unwrapped = {};

  XmlDocument get _stylesDoc => _styles ??= XmlDocument.parse(_entryText('xl/styles.xml'));

  /// Index of a cell style like [styleIndex] but without text wrapping: the
  /// same index when it does not wrap, else a copy appended to `cellXfs`.
  int unwrappedStyle(int styleIndex) {
    final cached = _unwrapped[styleIndex];
    if (cached != null) return cached;
    final xfs = _stylesDoc.rootElement.findElements('cellXfs').firstOrNull;
    if (xfs == null) return styleIndex;
    final list = xfs.findElements('xf').toList();
    if (styleIndex < 0 || styleIndex >= list.length) return styleIndex;
    final alignment = list[styleIndex].findElements('alignment').firstOrNull;
    final wrap = alignment?.getAttribute('wrapText');
    if (wrap == null || wrap == '0' || wrap == 'false') return _unwrapped[styleIndex] = styleIndex;
    final clone = list[styleIndex].copy();
    clone.findElements('alignment').first.removeAttribute('wrapText');
    xfs.children.add(clone);
    xfs.setAttribute('count', '${list.length + 1}');
    _stylesDirty = true;
    return _unwrapped[styleIndex] = list.length;
  }

  static XlsxWorkbook open(Uint8List bytes) {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (e) {
      throw XlsxException('not a zip/xlsx file: $e');
    }
    if (archive.findFile('xl/workbook.xml') == null) {
      throw XlsxException('xl/workbook.xml missing: not an xlsx file');
    }
    final wb = XlsxWorkbook._(archive, bytes);
    wb._loadSheets();
    return wb;
  }

  String _entryText(String path) {
    final replaced = _replacedEntries[path];
    if (replaced != null) return replaced;
    final file = _archive.findFile(path);
    if (file == null) throw XlsxException('$path missing from the xlsx');
    return utf8.decode(file.content as List<int>);
  }

  List<String> get sheetNames => _sheets.keys.toList();

  XlsxSheet? sheet(String name) => _sheets[name];

  XlsxSheet requireSheet(String name) =>
      _sheets[name] ?? (throw XlsxException('sheet "$name" not found (have: ${sheetNames.join(', ')})'));

  void _loadSheets() {
    final wbDoc = XmlDocument.parse(_entryText('xl/workbook.xml'));
    final relsDoc = XmlDocument.parse(_entryText('xl/_rels/workbook.xml.rels'));
    final targets = <String, String>{};
    for (final rel in relsDoc.rootElement.findElements('Relationship')) {
      final id = rel.getAttribute('Id');
      var target = rel.getAttribute('Target') ?? '';
      if (id == null) continue;
      if (target.startsWith('/')) {
        target = target.substring(1);
      } else if (!target.startsWith('xl/')) {
        target = 'xl/$target';
      }
      targets[id] = target;
    }
    for (final s in wbDoc.rootElement.findAllElements('sheet')) {
      final name = s.getAttribute('name');
      final rid = s.getAttribute('r:id') ?? s.attributes.where((a) => a.name.local == 'id').map((a) => a.value).firstOrNull;
      if (name == null || rid == null) continue;
      final path = targets[rid];
      if (path == null) continue;
      _sheets[name] = XlsxSheet._(name, path, this);
    }
  }

  String sharedString(int index) {
    final list = _sharedStrings ??= _loadSharedStrings();
    return index >= 0 && index < list.length ? list[index] : '';
  }

  List<String> _loadSharedStrings() {
    if (_archive.findFile('xl/sharedStrings.xml') == null) return const [];
    final doc = XmlDocument.parse(_entryText('xl/sharedStrings.xml'));
    return [
      for (final si in doc.rootElement.findElements('si')) si.findAllElements('t').map((t) => t.innerText).join(),
    ];
  }

  /// Ask Excel/LibreOffice to recalculate everything on open: the app only
  /// changes input cells, so cached formula results in the file are stale.
  void _markFullCalcOnLoad() {
    final text = _entryText('xl/workbook.xml');
    final doc = XmlDocument.parse(text);
    var calcPr = doc.rootElement.findElements('calcPr').firstOrNull;
    if (calcPr == null) {
      calcPr = XmlElement(XmlName('calcPr'));
      doc.rootElement.children.add(calcPr);
    }
    if (calcPr.getAttribute('fullCalcOnLoad') == '1') return;
    calcPr.setAttribute('fullCalcOnLoad', '1');
    _replacedEntries['xl/workbook.xml'] = doc.toXmlString();
  }

  /// Whether any sheet was modified since [open].
  bool get isDirty => _sheets.values.any((s) => s._dirty) || _replacedEntries.isNotEmpty || _stylesDirty;

  /// Re-zip: untouched entries are copied as they were.
  Uint8List save() {
    final replaced = Map<String, String>.from(_replacedEntries);
    for (final s in _sheets.values) {
      final xml = s._serialize();
      if (xml != null) replaced[s.path] = xml;
    }
    if (replaced.isEmpty) return _bytes;
    _markFullCalcOnLoad();
    final wbXml = _replacedEntries['xl/workbook.xml'];
    if (wbXml != null) replaced['xl/workbook.xml'] = wbXml;
    if (_stylesDirty) replaced['xl/styles.xml'] = _stylesDoc.toXmlString();
    final out = Archive();
    for (final f in _archive.files) {
      if (!f.isFile) continue;
      final name = f.name;
      final newText = replaced[name];
      if (newText != null) {
        final data = utf8.encode(newText);
        out.addFile(ArchiveFile(name, data.length, data));
      } else {
        final content = f.content as List<int>;
        out.addFile(ArchiveFile(name, content.length, content));
      }
    }
    final encoded = ZipEncoder().encode(out);
    return Uint8List.fromList(encoded);
  }
}
