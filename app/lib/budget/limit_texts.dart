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
      return (over ? 'Month limit 2 exceeded' : 'Month limit 1 reached', 'Expenses this month: $e, limit $l.');
    case 'ru':
      return (over ? 'Превышен месячный лимит 2' : 'Достигнут месячный лимит 1', 'Расходы за месяц: $e, лимит $l.');
    default:
      return (over ? 'Monatslimit 2 überschritten' : 'Monatslimit 1 erreicht', 'Ausgaben diesen Monat: $e, Limit $l.');
  }
}
