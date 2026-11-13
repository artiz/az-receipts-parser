/// Texts of the limit notifications. They are built outside the widget tree
/// (no BuildContext), so the language comes from the setting, else German,
/// the language of the spreadsheet.
library;

import 'package:intl/intl.dart';

import '../theme.dart';

(String, String) limitNotificationTexts(String localeCode, LimitLevel level, double expenses, double limit, {String symbol = '€'}) {
  final f = NumberFormat('#,##0', 'de_AT');
  final e = '${f.format(expenses)} $symbol';
  final l = '${f.format(limit)} $symbol';
  final over = level == LimitLevel.over;
  switch (localeCode) {
    case 'en':
      return (over ? 'Limit 2 exceeded' : 'Limit 1 reached', 'Expenses this month: $e, limit $l.');
    case 'ru':
      return (over ? 'Лимит 2 превышен' : 'Лимит 1 достигнут', 'Расходы за месяц: $e, лимит $l.');
    default:
      return (over ? 'Limit 2 überschritten' : 'Limit 1 erreicht', 'Ausgaben diesen Monat: $e, Limit $l.');
  }
}

/// Texts of the early warning: within the margin of limit [limitNo] (1 or 2),
/// the limit not reached.
(String, String) approachNotificationTexts(String localeCode, int limitNo, double expenses, double limit, {String symbol = '€'}) {
  final f = NumberFormat('#,##0', 'de_AT');
  final e = '${f.format(expenses)} $symbol';
  final l = '${f.format(limit)} $symbol';
  switch (localeCode) {
    case 'en':
      return ('Reaching limit $limitNo', 'Expenses this month: $e of $l.');
    case 'ru':
      return ('Приближается лимит $limitNo', 'Расходы за месяц: $e из $l.');
    default:
      return ('Limit $limitNo fast erreicht', 'Ausgaben diesen Monat: $e von $l.');
  }
}
