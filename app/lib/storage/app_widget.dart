/// The home-screen widget (Android): the month's expenses against the limit.
/// The budget pushes new numbers after every sync; the native side stores
/// and draws them.
library;

import 'package:flutter/services.dart';

abstract class WidgetSink {
  Future<void> update({required String title, required String amount, required int color});
}

class PlatformWidget implements WidgetSink {
  static const _channel = MethodChannel('dev.artiz.az_budget/widget');
  String? _last;

  @override
  Future<void> update({required String title, required String amount, required int color}) async {
    final key = '$title|$amount|$color';
    if (key == _last) return;
    _last = key;
    try {
      await _channel.invokeMethod<void>('update', {'title': title, 'amount': amount, 'color': color});
    } on MissingPluginException {
      // No widget on this platform.
    }
  }
}
