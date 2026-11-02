/// Text normalisation shared by the parser and the categoriser.
library;

const Map<String, String> _folding = {
  'ä': 'ae',
  'ö': 'oe',
  'ü': 'ue',
  'ß': 'ss',
  'é': 'e',
  'è': 'e',
  'ê': 'e',
  'á': 'a',
  'à': 'a',
  'â': 'a',
  'ó': 'o',
  'ò': 'o',
  'ô': 'o',
  'í': 'i',
  'ì': 'i',
  'î': 'i',
  'ú': 'u',
  'ù': 'u',
  'û': 'u',
  'ç': 'c',
  'ñ': 'n',
};

/// Lower-case, fold umlauts and accents, collapse whitespace.
String normalize(String s) {
  final sb = StringBuffer();
  for (final rune in s.toLowerCase().runes) {
    final ch = String.fromCharCode(rune);
    sb.write(_folding[ch] ?? ch);
  }
  return sb.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Alphabetic tokens of length >= 3 from a normalised string, plus
/// letter+digit tokens like `200ml` reduced to their letters (`ml`).
List<String> tokens(String s) {
  final n = normalize(s);
  final out = <String>[];
  for (final raw in n.split(RegExp(r'[^a-z0-9&]+'))) {
    if (raw.isEmpty) continue;
    final letters = raw.replaceAll(RegExp(r'[0-9]'), '');
    if (letters.length >= 3) out.add(letters);
  }
  return out;
}

/// Common OCR confusions in German receipt print, applied to names only.
String cleanOcrName(String s) {
  var t = s.trim();
  // Trailing VAT class markers ("… 3,75 1", "… A") are stripped by the row
  // parser; here only collapse duplicate spaces and stray separators.
  t = t.replaceAll(RegExp(r'\s+'), ' ');
  t = t.replaceAll(RegExp(r'^[\-_:.,|]+'), '').replaceAll(RegExp(r'[\-_:|]+$'), '');
  return t.trim();
}
