/// Two-level categorisation.
///
/// * Receipt level: a merchant rule (`pattern` is a substring of the
///   normalised merchant name) gives the receipt's category.
/// * Item level: the longest keyword rule found in the normalised item name
///   wins; learned rules (from user edits) beat seed rules of the same
///   length; without any match the item inherits the receipt category.
///
/// The class is pure Dart (no DB) so it is unit-testable; the repository
/// feeds it the rules and persists what the user teaches it.
library;

import '../core/text_normalize.dart';
import '../parser/merchants.dart';
import '../parser/parsed_receipt.dart';

import 'default_rules.dart';

const String otherCategory = 'other';

enum RuleSource { seed, learned }

class MerchantRule {
  const MerchantRule(this.pattern, this.categoryKey, {this.source = RuleSource.seed});
  final String pattern; // normalised substring
  final String categoryKey;
  final RuleSource source;
}

class KeywordRule {
  const KeywordRule(this.keyword, this.categoryKey, {this.source = RuleSource.seed});
  final String keyword; // normalised substring
  final String categoryKey;
  final RuleSource source;
}

class Categorizer {
  Categorizer({List<MerchantRule>? merchantRules, List<KeywordRule>? keywordRules})
      : merchantRules = merchantRules ?? defaultMerchantRules(),
        keywordRules = keywordRules ?? defaultKeywordRules();

  final List<MerchantRule> merchantRules;
  final List<KeywordRule> keywordRules;

  static List<MerchantRule> defaultMerchantRules() => [
        for (final m in knownMerchants) MerchantRule(m.needle, m.categoryKey),
        for (final m in knownMerchants)
          for (final a in m.aliases) MerchantRule(a, m.categoryKey),
      ];

  static List<KeywordRule> defaultKeywordRules() => [
        for (final e in seedKeywordRules.entries)
          for (final k in e.value) KeywordRule(k.trim(), e.key),
      ];

  /// Category for a merchant name, or null when no rule applies.
  String? categorizeMerchant(String? merchant) {
    if (merchant == null || merchant.isEmpty) return null;
    final n = normalize(merchant);
    MerchantRule? best;
    for (final r in merchantRules) {
      if (r.pattern.isEmpty || !n.contains(r.pattern)) continue;
      if (best == null ||
          r.pattern.length > best.pattern.length ||
          (r.pattern.length == best.pattern.length && r.source == RuleSource.learned)) {
        best = r;
      }
    }
    return best?.categoryKey;
  }

  /// Category for an item name; `fallback` when no keyword matches.
  String categorizeItem(String name, {String? fallback}) {
    final n = normalize(name);
    KeywordRule? best;
    for (final r in keywordRules) {
      final k = r.keyword;
      if (k.isEmpty || !n.contains(k)) continue;
      // Whole-word match for short keywords to avoid "tee" in "tastatur".
      if (k.length <= 4 && !RegExp('(^|[^a-z])${RegExp.escape(k)}([^a-z]|\$)').hasMatch(n)) continue;
      if (best == null ||
          k.length > best.keyword.length ||
          (k.length == best.keyword.length && r.source == RuleSource.learned)) {
        best = r;
      }
    }
    return best?.categoryKey ?? fallback ?? otherCategory;
  }

  /// Fill in receipt and item categories (keeps what is already set unless
  /// `force`).
  void apply(ParsedReceipt receipt, {bool force = false}) {
    final merchantCategory = categorizeMerchant(receipt.merchant) ?? categorizeMerchant(receipt.merchantRaw);
    if (force || receipt.categoryKey == null) {
      receipt.categoryKey = merchantCategory ?? receipt.categoryKey;
    }
    for (final item in receipt.items) {
      if (force || item.categoryKey == null) {
        item.categoryKey = categorizeItem(item.name, fallback: receipt.categoryKey ?? otherCategory);
      }
    }
    receipt.categoryKey ??= _majority(receipt.items.map((i) => i.categoryKey)) ?? otherCategory;
  }

  String? _majority(Iterable<String?> keys) {
    final counts = <String, int>{};
    for (final k in keys) {
      if (k == null) continue;
      counts[k] = (counts[k] ?? 0) + 1;
    }
    if (counts.isEmpty) return null;
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  /// A keyword to learn from an item the user re-categorised: the normalised
  /// name without sizes/numbers, e.g. "nivea deospray 150ml fresh flower" →
  /// "nivea deospray fresh flower".
  static String learnKeywordFor(String itemName) {
    final n = normalize(itemName)
        .replaceAll(RegExp(r'\b\d+([.,]\d+)?\s*(ml|l|g|kg|cm|mm|m|stk|st|x|er|pack|pcs)\b'), ' ')
        .replaceAll(RegExp(r'[^a-z&\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return n;
  }

  static String learnMerchantPatternFor(String merchant) => normalize(merchant);
}
