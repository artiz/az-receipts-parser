/// Texts of the limit notifications. They are built outside the widget tree
/// (no BuildContext), so the language comes from the setting, else German,
/// the language of the spreadsheet.
library;

import 'package:intl/intl.dart';

import '../theme.dart';
import 'budget_service.dart' show MonthForecast;

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

/// Texts of the pace warning: at this rate limit 1 is reached on day N.
(String, String) forecastNotificationTexts(String localeCode, MonthForecast forecast, double limit, {String symbol = '€'}) {
  final f = NumberFormat('#,##0', 'de_AT');
  final p = '${f.format(forecast.projected)} $symbol';
  final l = '${f.format(limit)} $symbol';
  final d = forecast.limit1Day;
  switch (localeCode) {
    case 'en':
      return ('Heading for limit 1', 'At this pace the month ends at about $p; limit 1 ($l) would be reached on day $d.');
    case 'ru':
      return ('Идём к лимиту 1', 'При таком темпе месяц закончится примерно на $p; лимит 1 ($l) будет достигнут $d-го.');
    default:
      return ('Kurs auf Limit 1', 'Bei diesem Tempo endet der Monat bei etwa $p; Limit 1 ($l) wäre am $d. erreicht.');
  }
}
