/// Suggestions learned from the entries themselves: quick tiles for the home
/// screen, per-category description autocomplete, the usual amount for a
/// description, and the category a merchant usually gets. No hard-coded
/// names anywhere; everything adapts to what is in the file.
library;

import 'package:collection/collection.dart';

import '../core/text_normalize.dart';
import 'budget_file.dart';

class QuickTile {
  const QuickTile({required this.category, required this.description, required this.amount, required this.count});
  final String category;
  final String description;

  /// The amount used last time for this (category, description).
  final double amount;
  final int count;
}

class DescriptionSuggestion {
  const DescriptionSuggestion({required this.description, required this.count, required this.lastAmount, required this.lastDate});
  final String description;
  final int count;
  final double lastAmount;
  final DateTime lastDate;
}

class EntrySuggestions {
  EntrySuggestions(List<BudgetEntry> entries, {DateTime? now, this.recentDays = 90})
      : _entries = entries,
        _now = now ?? DateTime.now();

  final List<BudgetEntry> _entries;
  final DateTime _now;
  final int recentDays;

  /// Score: frequency in the recent window counts fully, older entries a
  /// quarter, so a tile reflects current habits without forgetting.
  double _weight(BudgetEntry e) => _now.difference(e.date).inDays <= recentDays ? 1.0 : 0.25;

  /// Most used (category, description) pairs for the home screen.
  List<QuickTile> quickTiles({int limit = 8, int perCategory = 3}) {
    final score = <String, double>{};
    final count = <String, int>{};
    final last = <String, BudgetEntry>{};
    for (final e in _entries) {
      if (e.description.isEmpty || e.category.isEmpty) continue;
      final key = '${e.category}\u0000${_norm(e.description)}';
      score[key] = (score[key] ?? 0) + _weight(e);
      count[key] = (count[key] ?? 0) + 1;
      final prev = last[key];
      if (prev == null || !e.date.isBefore(prev.date)) last[key] = e;
    }
    final keys = score.keys.toList()..sort((a, b) => score[b]!.compareTo(score[a]!));
    final perCat = <String, int>{};
    final out = <QuickTile>[];
    for (final k in keys) {
      final e = last[k]!;
      final n = perCat[e.category] ?? 0;
      if (n >= perCategory) continue;
      perCat[e.category] = n + 1;
      out.add(QuickTile(category: e.category, description: e.description, amount: e.amount, count: count[k]!));
      if (out.length >= limit) break;
    }
    return out;
  }

  /// Descriptions used with [category], best first; [prefix] filters by a
  /// case-insensitive prefix match on any word ("S" → "SPAR", "Pizza NAR").
  List<DescriptionSuggestion> descriptions(String category, {String prefix = '', int limit = 12}) {
    final score = <String, double>{};
    final count = <String, int>{};
    final last = <String, BudgetEntry>{};
    final display = <String, String>{};
    final p = _norm(prefix);
    for (final e in _entries) {
      if (e.category != category || e.description.isEmpty) continue;
      final n = _norm(e.description);
      if (p.isNotEmpty && !_prefixMatch(n, p)) continue;
      score[n] = (score[n] ?? 0) + _weight(e);
      count[n] = (count[n] ?? 0) + 1;
      final prev = last[n];
      if (prev == null || !e.date.isBefore(prev.date)) {
        last[n] = e;
        display[n] = e.description;
      }
    }
    final keys = score.keys.toList()
      ..sort((a, b) {
        // A match at the start of the description beats a match on a later word.
        final sa = p.isNotEmpty && a.startsWith(p) ? 1 : 0;
        final sb = p.isNotEmpty && b.startsWith(p) ? 1 : 0;
        if (sa != sb) return sb - sa;
        return score[b]!.compareTo(score[a]!);
      });
    return [
      for (final k in keys.take(limit))
        DescriptionSuggestion(description: display[k]!, count: count[k]!, lastAmount: last[k]!.amount, lastDate: last[k]!.date),
    ];
  }

  /// Categories ordered by how often they are used (for the picker).
  List<String> categoriesByUse(Iterable<String> all) {
    final score = <String, double>{};
    for (final e in _entries) {
      score[e.category] = (score[e.category] ?? 0) + _weight(e);
    }
    final list = all.toList()..sort((a, b) => (score[b] ?? 0).compareTo(score[a] ?? 0));
    return list;
  }

  /// The category most often used for a merchant / description, learned
  /// from the entries: "spar" → Lebensmittel. Null when unknown.
  String? categoryFor(String description) {
    final needle = _norm(description);
    if (needle.length < 3) return null;
    final needleTokens = _keyTokens(needle);
    final score = <String, double>{};
    for (final e in _entries) {
      final d = _norm(e.description);
      var hit = d == needle || d.contains(needle) || needle.contains(d) && d.length >= 4;
      if (!hit && needleTokens.isNotEmpty) {
        // "Santander Consumer Bank GmbH" ↔ "Küche Santander": a shared
        // distinctive word is enough.
        hit = _keyTokens(d).any(needleTokens.contains);
      }
      if (hit) score[e.category] = (score[e.category] ?? 0) + _weight(e);
    }
    if (score.isEmpty) return null;
    return score.entries.sorted((a, b) => b.value.compareTo(a.value)).first.key;
  }

  static const _generic = {
    'gmbh', 'gesmbh', 'bank', 'wien', 'austria', 'consumer', 'service', 'services', 'shop', 'store', 'markt', 'online', 'payment', 'payments',
    'europe', 'limited', 'international', 'deutschland', 'germany', 'kate', 'artem', 'platon', 'marina', 'rechnung', 'zahlung', 'kauf',
  };

  /// Distinctive words (4+ letters, not generic company fluff) of a
  /// normalised description.
  static Set<String> _keyTokens(String normalized) => {
        for (final t in normalized.split(RegExp(r'[^a-z]+')))
          if (t.length >= 4 && !_generic.contains(t)) t,
      };

  /// Usual amount for a (category, description), null when unknown.
  double? usualAmount(String category, String description) {
    final n = _norm(description);
    final amounts = _entries.where((e) => e.category == category && _norm(e.description) == n).map((e) => e.amount).toList();
    if (amounts.isEmpty) return null;
    final counts = <double, int>{};
    for (final a in amounts) {
      counts[a] = (counts[a] ?? 0) + 1;
    }
    final best = counts.entries.sorted((a, b) => b.value.compareTo(a.value)).first;
    // A clear favourite wins, otherwise the latest amount.
    return best.value > 1 ? best.key : amounts.last;
  }

  static bool _prefixMatch(String normalized, String prefix) {
    if (normalized.startsWith(prefix)) return true;
    for (final word in normalized.split(' ')) {
      if (word.startsWith(prefix)) return true;
    }
    return false;
  }

  static String _norm(String s) => normalize(s).trim();
}
