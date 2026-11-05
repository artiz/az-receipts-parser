/// System notifications through the activity (no plugin): the limit alerts.
library;

import 'package:flutter/services.dart';

abstract class NotificationSink {
  Future<void> requestPermission();
  Future<void> show({required int id, required String title, required String body});
}

class PlatformNotifications implements NotificationSink {
  static const _channel = MethodChannel('dev.artiz.az_budget/notifications');

  @override
  Future<void> requestPermission() async {
    try {
      await _channel.invokeMethod<void>('requestPermission');
    } on MissingPluginException {
      // Not on Android: nothing to ask.
    } on PlatformException {
      // Denied or unavailable: the in-app colours still show the state.
    }
  }

  @override
  Future<void> show({required int id, required String title, required String body}) async {
    try {
      await _channel.invokeMethod<void>('show', {'id': id, 'title': title, 'body': body});
    } on MissingPluginException {
      // ignore
    } on PlatformException {
      // ignore
    }
  }
}
