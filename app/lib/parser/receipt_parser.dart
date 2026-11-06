/// Turns OCR rows (+ an optional RKSV QR) into a [ParsedReceipt].
///
/// The parser is dictionary driven (German first, English second) and is
/// regression-tested against the golden fixtures in `samples/`. When adding
/// a keyword, add a fixture or a unit test that exercises it.
library;

import '../core/money.dart';
import '../core/text_normalize.dart';
import '../ocr/ocr_rows.dart';
import '../ocr/ocr_types.dart';
import 'merchants.dart';
import 'parsed_receipt.dart';
import 'rksv_qr.dart';

class ReceiptParser {
  ReceiptParser({this.rowFactor = 0.45});

  final double rowFactor;

  // --- dictionaries ---------------------------------------------------------

  /// Rows that carry the grand total, in priority order.
  static final List<RegExp> totalKeys = [
    RegExp(r'^(summe|gesamt|gesamtsumme|gesamtbetrag|total|totaal|betrag|zu zahlen|endbetrag|endsumme|amount due|balance due|grand total)\b'),
    RegExp(r'\b(summe|gesamt|total|zu zahlen|endbetrag)\b'),
  ];

  /// Rows that are never items (payment, VAT, change, headers, footers).
  static final RegExp notItemKeys = RegExp(
    r'\b(summe|zw[\-. ]?summe|zwischensumme|subtotal|sub-total|gesamt|total|mwst|mw\.st|ust|vat|netto|nettobetr|brutto|bruttobetr|'
    r'bar|cash|rueckgeld|rückgeld|wechselgeld|change|karte|card|kartenzahlung|mastercard|maestro|visa|debit|girocard|ec[\- ]karte|kontaktlos|contactless|'
    r'bezahlt|bezahlweise|zahlung|payment|gegeben|given|trinkgeld|tip|artikelanzahl|anzahl teile|anz\.? artikel|artikel\b|'
    r'eur\b|euro\b|betrag|datum|uhrzeit|kasse|kassier|bon\b|beleg|filiale|shop|tel\b|uid|atu\d|steuer|tax|eft|buchung|'
    r'genehmigung|auth|aid\b|tid\b|mid\b|pan\b|terminal|trace|tender|kundenbeleg|kunden beleg|haendlerbeleg|'
    r'payback|punkte|points|danke|thank|vielen dank|wiedersehen|oeffnungszeiten|www\.|\.at\b|\.de\b|\.com\b)\b',
  );

  // The year may be glued to a time ("02.11.202614:50" on dm receipts).
  static final RegExp dateRe = RegExp(r'(\d{1,2})[./\-](\d{1,2})[./\-](\d{4}|\d{2})(?=$|\D|\d{1,2}:\d{2})');
  static final RegExp isoDateRe = RegExp(r'(\d{4})-(\d{2})-(\d{2})');
  static final RegExp timeRe = RegExp(r'(?<!\d)(\d{1,2}):(\d{2})(?::(\d{2}))?(?!\d)');
  static final RegExp priceTailRe = RegExp(
      r'(-?)\s*(?:€|eur)?\s*(\d{1,6})[.,](\d{2})\s*(?:€|eur|€)?\s*(?:[a-d1-9]|\*)?\s*$',
      caseSensitive: false);
  /// Column headers that OCR glues to the first item row ("ARTIKEL schoko…").
  static final RegExp headerTokenRe = RegExp(r'^(artikel|article|bezeichnung|beschreibung|description|menge|qty|preis|price|eur|euro|betrag|€)\s+', caseSensitive: false);
  /// Keys checked with spaces removed, for OCR splits like "Rückge ld".
  static final RegExp notItemCompact = RegExp(r'(rueckgeld|zwischensumme|zwsumme|kartenzahlung|gesamtsumme|nettobetrag|bruttobetrag|artikelanzahl|anzahlteile)');
  static final RegExp vatRateRe = RegExp(r'(\d{1,2}(?:[.,][\dGOo]{1,2})?)\s*%');
  static final RegExp postalRe = RegExp(r'(?<!\d)(\d{4,5})\s+([A-ZÄÖÜ][A-Za-zÄÖÜäöüß.\- ]{2,})');
  static final RegExp legalSuffixRe = RegExp(
      r'\s*([gc]mbh\s*&\s*co\.?\s*kg|[gc]mbh|ag|kg|og|e\.?u\.?|ges\.?m\.?b\.?h\.?|s\.?r\.?o\.?|ltd|inc|llc|b\.?v\.?|warenhandels?|handels?|austria)\b.*$',
      caseSensitive: false);

  // --- entry point ----------------------------------------------------------

  ParsedReceipt parse(OcrResult ocr) {
    final rows = groupRows(ocr.lines, factor: rowFactor);
    final receipt = ParsedReceipt();

    final qr = _firstRksv(ocr.qrCodes);
    if (qr != null) {
      receipt.qrText = qr.raw;
      receipt.rksvKassenId = qr.kassenId;
      receipt.rksvBelegNummer = qr.belegNummer;
      receipt.purchasedAt = qr.timestamp;
      receipt.totalCents = qr.totalCents;
      for (final e in qr.grossByRate.entries) {
        if (e.value != 0) receipt.vat.add(ParsedVat(rate: e.key.toDouble(), grossCents: e.value));
      }
    } else if (ocr.qrCodes.isNotEmpty) {
      receipt.qrText = ocr.qrCodes.first.text;
    }

    _detectCurrency(rows, receipt);
    _detectMerchant(rows, receipt);
    _detectAddress(rows, receipt);
    final totalRowIndex = _detectTotal(rows, receipt);
    if (receipt.purchasedAt == null) _detectDate(rows, receipt);
    _detectPayment(rows, receipt);
    if (receipt.vat.isEmpty) _detectVat(rows, receipt);
    _detectItems(rows, receipt, totalRowIndex);
    _score(receipt, qr != null);
    return receipt;
  }

  // --- helpers --------------------------------------------------------------

  RksvQr? _firstRksv(List<OcrQr> codes) {
    for (final c in codes) {
      final r = RksvQr.tryParse(c.text);
      if (r != null) return r;
    }
    return null;
  }

  void _detectCurrency(List<OcrRow> rows, ParsedReceipt r) {
    final all = rows.map((x) => x.text).join(' ');
    if (RegExp(r'\bCHF\b').hasMatch(all)) {
      r.currency = 'CHF';
    } else if (RegExp(r'\bPLN\b|\bzł').hasMatch(all)) {
      r.currency = 'PLN';
    } else if (RegExp(r'\bCZK\b|\bKč').hasMatch(all)) {
      r.currency = 'CZK';
    } else if (RegExp(r'\bUSD\b|\$').hasMatch(all) && !all.contains('€') && !all.contains('EUR')) {
      r.currency = 'USD';
    }
  }

  void _detectMerchant(List<OcrRow> rows, ParsedReceipt r) {
    final headerCount = (rows.length * 0.45).ceil().clamp(1, 14);
    final header = rows.take(headerCount).toList();
    // 1. known merchant anywhere in the header (also catches logo text).
    for (final row in header) {
      final n = normalize(row.text);
      for (final m in knownMerchants) {
        if (m.matches(n)) {
          r.merchant = m.name;
          r.merchantRaw = row.text;
          r.categoryKey = m.categoryKey;
          return;
        }
      }
    }
    // 2. a legal-entity row ("… GmbH", "… KG") gives a good raw name.
    for (final row in header) {
      final t = row.text;
      if (legalSuffixRe.hasMatch(t) && RegExp(r'[A-Za-z]{3,}').hasMatch(t)) {
        r.merchantRaw = t;
        r.merchant = _cleanMerchant(t);
        return;
      }
    }
    // 3. first row that looks like a name (letters, not an address/date/number).
    for (final row in header) {
      final t = row.text.trim();
      if (t.length < 3) continue;
      if (RegExp(r'^[\d\s.:/\-]+$').hasMatch(t)) continue;
      if (postalRe.hasMatch(t) || dateRe.hasMatch(t) || timeRe.hasMatch(t)) continue;
      if (RegExp(r"^[A-Za-zÄÖÜäöüß&.' \-]{3,}").hasMatch(t) && row.minConfidence > 0.6) {
        r.merchantRaw = t;
        r.merchant = _cleanMerchant(t);
        return;
      }
    }
  }

  String _cleanMerchant(String t) {
    var s = t.replaceFirst(legalSuffixRe, '').trim();
    s = s.replaceAll(RegExp(r'\s{2,}'), ' ');
    if (s.isEmpty) s = t.trim();
    return s;
  }

  void _detectAddress(List<OcrRow> rows, ParsedReceipt r) {
    final headerCount = (rows.length * 0.5).ceil().clamp(1, 16);
    String? street;
    String? city;
    for (final row in rows.take(headerCount)) {
      final t = row.text.trim();
      final pm = postalRe.firstMatch(t);
      if (city == null && pm != null && !dateRe.hasMatch(t)) {
        // "1020 Wien" / "7067 Wien Olympiaplatz 2" — keep postal + city word(s).
        city = '${pm.group(1)} ${pm.group(2)!.split(RegExp(r'\s{2,}')).first.trim()}';
        final rest = t.replaceFirst(pm.group(0)!, '').trim();
        if (street == null && RegExp(r'[A-Za-zÄÖÜäöüß]{3,}.*\d').hasMatch(rest)) street = rest;
        continue;
      }
      if (street == null &&
          RegExp(r'^[A-ZÄÖÜ][A-Za-zÄÖÜäöüß\.\-]+(?:\s[A-Za-zÄÖÜäöüß\.\-]+)*\s+\d{1,4}[a-z]?(?:[/\-]\d+)*\s*(?:\(.*\))?$').hasMatch(t) &&
          !notItemKeys.hasMatch(normalize(t))) {
        street = t;
      }
    }
    if (street != null || city != null) {
      r.address = [street, city].whereType<String>().join(', ');
    }
  }

  /// Returns the index of the row the total was read from (or -1).
  int _detectTotal(List<OcrRow> rows, ParsedReceipt r) {
    int found = -1;
    int? cents;
    for (final re in totalKeys) {
      for (var i = 0; i < rows.length; i++) {
        final n = normalize(rows[i].text);
        if (!re.hasMatch(n)) continue;
        // Skip "Zw-Summe"/"Zwischensumme" (subtotals) and VAT table headers.
        if (RegExp(r'zw[\-. ]?summe|zwischensumme|subtotal|nettobetr|summe nettobetr|mwst\.?\s*summe').hasMatch(n)) continue;
        final amounts = parseAllCents(rows[i].text);
        if (amounts.isEmpty) {
          // "SUMME" on its own line, amount on the next row at the right edge.
          if (i + 1 < rows.length) {
            final next = parseAllCents(rows[i + 1].rightText);
            if (next.length == 1 && !notItemKeys.hasMatch(normalize(rows[i + 1].leftText))) {
              cents = next.first;
              found = i + 1;
              break;
            }
          }
          continue;
        }
        // VAT summary rows ("SUMME 6,30 5,25 1,05") carry several amounts: the
        // gross is the largest one. A plain total row carries one.
        cents = amounts.reduce((a, b) => a.abs() > b.abs() ? a : b);
        found = i;
        break;
      }
      if (found >= 0) break;
    }
    if (cents == null) {
      // Fallback: the payment row ("Mastercard EUR -6,30", "Bar 20,00" is the
      // tendered amount, so prefer card rows), else the largest amount.
      for (var i = 0; i < rows.length; i++) {
        final n = normalize(rows[i].text);
        if (RegExp(r'mastercard|maestro|visa|debit|karte|card|eft').hasMatch(n)) {
          final a = parseAllCents(rows[i].text);
          if (a.isNotEmpty) {
            cents = a.last.abs();
            found = i;
            break;
          }
        }
      }
    }
    if (cents == null) {
      final all = rows.expand((x) => parseAllCents(x.text)).where((c) => c > 0).toList();
      if (all.isNotEmpty) {
        cents = all.reduce((a, b) => a > b ? a : b);
        r.warnings.add('total_guessed');
      }
    }
    if (cents != null) {
      if (r.totalCents != null && r.totalCents != cents.abs()) {
        r.warnings.add('total_ocr_mismatch:${cents.abs()}');
      } else {
        r.totalCents ??= cents.abs();
      }
    } else {
      r.warnings.add('total_missing');
    }
    return found;
  }

  /// Date priority: a row labelled "Datum/Date" with a date on it, then a
  /// row carrying both a date and a time, then the first plausible date.
  /// The time comes from the same row, else from the first "Uhrzeit/Time"
  /// row, else the first time found anywhere.
  void _detectDate(List<OcrRow> rows, ParsedReceipt r) {
    int? labelled, withTime, first;
    for (var i = 0; i < rows.length; i++) {
      final t = rows[i].text;
      if (_dateIn(t) == null) continue;
      final n = normalize(t);
      if (labelled == null && RegExp(r'\b(datum|date|data)\b').hasMatch(n)) labelled = i;
      if (withTime == null && timeRe.hasMatch(t)) withTime = i;
      first ??= i;
    }
    final idx = labelled ?? withTime ?? first;
    if (idx == null) {
      r.warnings.add('date_missing');
      return;
    }
    final date = _dateIn(rows[idx].text)!;
    var time = _timeIn(rows[idx].text);
    if (time == null) {
      for (var i = idx + 1; i < rows.length && i <= idx + 3 && time == null; i++) {
        time = _timeIn(rows[i].text);
      }
      for (var i = 0; i < rows.length && time == null; i++) {
        final n = normalize(rows[i].text);
        if (RegExp(r'\b(uhrzeit|zeit|time)\b').hasMatch(n)) time = _timeIn(rows[i].text);
      }
      for (var i = 0; i < rows.length && time == null; i++) {
        time = _timeIn(rows[i].text);
      }
    }
    r.purchasedAt = DateTime(date.year, date.month, date.day, time?.$1 ?? 0, time?.$2 ?? 0, time?.$3 ?? 0);
  }

  DateTime? _dateIn(String t) {
    final m = dateRe.firstMatch(t);
    if (m != null) {
      var y = int.parse(m.group(3)!);
      if (y < 100) y += 2000;
      final d = int.parse(m.group(1)!);
      final mo = int.parse(m.group(2)!);
      if (mo >= 1 && mo <= 12 && d >= 1 && d <= 31 && y >= 2000 && y <= 2100) return DateTime(y, mo, d);
      return null;
    }
    final im = isoDateRe.firstMatch(t);
    if (im != null) {
      final y = int.parse(im.group(1)!), mo = int.parse(im.group(2)!), d = int.parse(im.group(3)!);
      if (mo >= 1 && mo <= 12 && d >= 1 && d <= 31) return DateTime(y, mo, d);
    }
    return null;
  }

  (int, int, int)? _timeIn(String t) {
    for (final tm in timeRe.allMatches(t)) {
      final hh = int.parse(tm.group(1)!), mm = int.parse(tm.group(2)!);
      if (hh < 24 && mm < 60) return (hh, mm, int.tryParse(tm.group(3) ?? '') ?? 0);
    }
    return null;
  }

  void _detectPayment(List<OcrRow> rows, ParsedReceipt r) {
    final card = RegExp(r'mastercard|maestro|visa|debit|girocard|ec[\- ]karte|kartenzahlung|kreditkarte|\bkarte\b|\bcard\b|kontaktlos|contactless|apple pay|google pay|\beft\b');
    final cashStart = RegExp(r'^(bar|bargeld|barzahlung|cash)\b');
    final cashAny = RegExp(r'rueckgeld|wechselgeld|\bbargeld\b|\bcash\b');
    var cash = false;
    for (final row in rows) {
      final n = normalize(row.text);
      if (card.hasMatch(n)) {
        r.payment = PaymentMethod.card;
        return;
      }
      if (cashStart.hasMatch(n) || cashAny.hasMatch(n.replaceAll(' ', ''))) cash = true;
    }
    if (cash) r.payment = PaymentMethod.cash;
  }

  void _detectVat(List<OcrRow> rows, ParsedReceipt r) {
    for (final row in rows) {
      final t = row.text;
      final rm = vatRateRe.firstMatch(t);
      if (rm == null) continue;
      final rate = double.tryParse(rm.group(1)!.replaceAll(',', '.').replaceAll(RegExp('[GOo]'), '0'));
      if (rate == null || rate > 30) continue;
      var amounts = parseAllCents(t.replaceFirst(rm.group(0)!, ''));
      if (amounts.isEmpty) {
        // "(1) 20.00 %" with the amounts on the next row (Ernsting's layout).
        final i = rows.indexOf(row);
        if (i + 1 < rows.length && !vatRateRe.hasMatch(rows[i + 1].text)) amounts = parseAllCents(rows[i + 1].text);
      }
      if (amounts.isEmpty) continue;
      // Layouts: "20% 8,94 1,79 10,73" (net, vat, gross) or "20,00 % MwSt A 1,55 0,26" (gross, vat)
      // or "€1,00 €4,99 €5,99" (vat, net, gross) — resolve by arithmetic.
      final sorted = [...amounts]..sort();
      int? gross, net, vat;
      if (amounts.length >= 3) {
        gross = sorted.last;
        for (final a in sorted) {
          for (final b in sorted) {
            if (a != b && a + b == gross) {
              net = a > b ? a : b;
              vat = a > b ? b : a;
            }
          }
        }
      } else if (amounts.length == 2) {
        final big = sorted.last, small = sorted.first;
        // gross & vat (TEDi) vs net & vat — check which product matches the rate.
        final vatFromGross = (big * rate / (100 + rate)).round();
        final vatFromNet = (big * rate / 100).round();
        if ((vatFromGross - small).abs() <= 1) {
          gross = big;
          vat = small;
          net = big - small;
        } else if ((vatFromNet - small).abs() <= 1) {
          net = big;
          vat = small;
          gross = big + small;
        } else {
          gross = big;
          vat = small;
        }
      } else {
        gross = amounts.first;
      }
      if (r.vat.any((v) => v.rate == rate)) continue;
      r.vat.add(ParsedVat(rate: rate, netCents: net, vatCents: vat, grossCents: gross));
    }
  }

  void _detectItems(List<OcrRow> rows, ParsedReceipt r, int totalRowIndex) {
    // Items live between the header (merchant/address/date) and the total.
    final end = totalRowIndex > 0 ? totalRowIndex : rows.length;
    var start = 0;
    // Skip the header: the last row before the first price that mentions
    // date/time/kasse/bon etc. is a good boundary.
    for (var i = 0; i < end; i++) {
      final n = normalize(rows[i].text);
      if (RegExp(r'\b(datum|uhrzeit|kasse|kassier|bon\b|beleg|filiale|shop|uid|tel\b|atu\d|rechnung|artikel\b|eur\b)').hasMatch(n) &&
          !_hasPriceTail(rows[i])) {
        start = i + 1;
      }
    }
    ParsedItem? last;
    // A quantity line whose product does not match the previous item: Billa
    // prints "2 x 1.79" above the item it belongs to, most shops below.
    ({double quantity, int unitCents})? pendingQty;
    ParsedItem? pendingFor;
    void applyQty(ParsedItem item, ({double quantity, int unitCents}) q) {
      item.quantity = q.quantity;
      item.unitCents = q.unitCents;
    }

    bool matches(ParsedItem item, ({double quantity, int unitCents}) q) => (item.totalCents - (q.quantity * q.unitCents).round()).abs() <= 1;

    for (var i = start; i < end; i++) {
      final row = rows[i];
      final text = row.text;
      final n = normalize(text);
      final price = _priceTail(row);

      // Quantity line: "= 2 x 1,89" / "2 Stk x 0,99" → the previous item when
      // the product matches it, else kept for the next one.
      final q = parseQuantityLine(text);
      if (q != null && (last != null || pendingQty == null) && (price == null || RegExp(r'^[=\s]*\d').hasMatch(text))) {
        if (last != null && matches(last, q)) {
          applyQty(last, q);
        } else {
          pendingQty = q;
          pendingFor = last;
        }
        continue;
      }

      if (price == null) {
        // Continuation of the previous item (size, article number, barcode).
        if (last != null && !notItemKeys.hasMatch(n) && !notItemCompact.hasMatch(n.replaceAll(' ', '')) && !_isNoise(text)) {
          if (RegExp(r'[A-Za-zÄÖÜäöüß]{3,}').hasMatch(text) && !RegExp(r'^[\d\s/\-]+$').hasMatch(text)) {
            last.name = '${last.name} ${cleanOcrName(text)}'.trim();
          }
        }
        continue;
      }

      final stripped = normalize(price.name.replaceFirst(headerTokenRe, ''));
      if ((notItemKeys.hasMatch(stripped) || notItemCompact.hasMatch(stripped.replaceAll(' ', ''))) && !_looksLikeItem(stripped)) {
        last = null;
        continue;
      }
      var name = cleanOcrName(price.name.replaceFirst(headerTokenRe, ''));
      // Leading article numbers ("3227582 schokoladenerdnuesse") → drop.
      name = name.replaceFirst(RegExp(r'^\d{5,}\s+'), '');
      // Leading quantity ("2 Semmel") stays in the name; a lone count row is skipped.
      if (name.isEmpty || !RegExp(r'[A-Za-zÄÖÜäöüß]{2,}').hasMatch(name)) {
        // A price with no name on this row: the name may be on the previous
        // row (two-line items, e.g. TEDi "4er Pack … A" / "776540011310000 1,55").
        if (last == null) {
          for (var j = i - 1; j >= start && j >= i - 3; j--) {
            final prev = rows[j];
            if (_hasPriceTail(prev) || notItemKeys.hasMatch(normalize(prev.text))) break;
            if (_isNoise(prev.text)) continue; // article numbers between name and price
            final pn = cleanOcrName(prev.text.replaceAll(RegExp(r'\s+[A-D]\s*$'), ''));
            if (RegExp(r'[A-Za-zÄÖÜäöüß]{3,}').hasMatch(pn)) name = pn;
            break;
          }
        }
        if (name.isEmpty || !RegExp(r'[A-Za-zÄÖÜäöüß]{2,}').hasMatch(name)) continue;
      }
      final item = ParsedItem(
        name: name,
        totalCents: price.cents,
        vatRate: price.vatClass != null ? _vatRateForClass(price.vatClass!, r) : null,
        confidence: row.minConfidence,
      );
      r.items.add(item);
      last = item;
      final pq = pendingQty;
      if (pq != null) {
        final pf = pendingFor;
        if (matches(item, pq)) {
          applyQty(item, pq);
        } else if (pf != null) {
          applyQty(pf, pq); // neither matches: the shop prints it below, as before
        }
        pendingQty = null;
        pendingFor = null;
      }
    }
    final pq = pendingQty;
    final pf = pendingFor;
    if (pq != null && pf != null) applyQty(pf, pq);
    // Drop a trailing pseudo-item that equals the total when there are >1 items.
    if (r.items.length > 1 && r.totalCents != null && r.items.last.totalCents == r.totalCents) {
      final n = normalize(r.items.last.name);
      if (RegExp(r'summe|total|gesamt|betrag').hasMatch(n)) r.items.removeLast();
    }
    // Two-line items where the price row had the article number: strip digits-only names.
    r.items.removeWhere((it) => RegExp(r'^[\d\s/\-]+$').hasMatch(it.name));
  }

  bool _looksLikeItem(String n) {
    // "Bar" would be matched by notItemKeys but "Barbie" or "Barista" are items.
    return RegExp(r'\b(bar|karte|card|total|summe)\w+').hasMatch(n) && !RegExp(r'\b(bar|karte|card|total|summe)\b').hasMatch(n);
  }

  bool _isNoise(String t) {
    final s = t.trim();
    if (s.length <= 2) return true;
    if (RegExp(r'^[\W_]+$').hasMatch(s)) return true;
    if (RegExp(r'^[\d\s/\-.,:#*]+$').hasMatch(s)) return true; // barcodes, article numbers
    return false;
  }

  bool _hasPriceTail(OcrRow row) => _priceTail(row) != null;

  ({String name, int cents, String? vatClass})? _priceTail(OcrRow row) {
    // Prefer the rightmost fragment; it must sit in the right 40% of the frame
    // for multi-fragment rows (prices are right-aligned on every layout seen).
    final right = row.rightText;
    final m = priceTailRe.firstMatch(right);
    if (m != null && (row.lines.length == 1 || row.lines.last.cx > row.lines.first.cx)) {
      final sign = m.group(1) == '-' ? -1 : 1;
      final cents = sign * (int.parse(m.group(2)!) * 100 + int.parse(m.group(3)!));
      final rest = right.substring(0, m.start).trim();
      final name = [row.leftText, rest].where((s) => s.isNotEmpty).join(' ');
      final tail = m.group(0)!;
      final cls = RegExp(r'([A-D1-9])\s*$').firstMatch(tail)?.group(1);
      return (name: name, cents: cents, vatClass: cls);
    }
    // OCR sometimes reads the decimal comma as a colon ("0:65"). Accept it only
    // for a lone hh:mm-shaped fragment next to a real item name, never on a
    // row that carries a date, seconds or a time label.
    final cm = RegExp(r'^(\d{1,3}):(\d{2})$').firstMatch(right);
    if (cm != null && row.lines.length > 1) {
      final left = row.leftText;
      final ln = normalize(left);
      if (RegExp(r'[A-Za-zÄÖÜäöüß]{3,}').hasMatch(left) &&
          !dateRe.hasMatch(row.text) &&
          !RegExp(r'\d{1,2}:\d{2}:\d{2}').hasMatch(row.text) &&
          !RegExp(r'uhrzeit|zeit|time|datum|date|bon|beleg|kasse|trace|buchung').hasMatch(ln) &&
          !notItemKeys.hasMatch(ln)) {
        return (name: left, cents: int.parse(cm.group(1)!) * 100 + int.parse(cm.group(2)!), vatClass: null);
      }
    }
    return null;
  }

  double? _vatRateForClass(String cls, ParsedReceipt r) {
    // "1=20,00%" style legends are rare in the OCR output; map A/1 → the
    // dominant rate when there is exactly one, else leave null.
    if (r.vat.length == 1) return r.vat.first.rate;
    return null;
  }

  void _score(ParsedReceipt r, bool hasQr) {
    var score = 0.0;
    if (r.merchant != null) score += 0.2;
    if (r.purchasedAt != null) score += 0.2;
    if (r.totalCents != null) score += 0.3;
    if (r.items.isNotEmpty) score += 0.2;
    if (hasQr) score += 0.1;
    if (r.totalCents != null && r.items.isNotEmpty) {
      final diff = (r.itemsSumCents - r.totalCents!).abs();
      if (diff == 0) {
        score += 0.1;
      } else if (diff > r.totalCents! * 0.05) {
        r.warnings.add('items_sum_mismatch:${r.itemsSumCents}');
        score -= 0.1;
      }
    }
    r.confidence = score.clamp(0, 1);
  }
}
