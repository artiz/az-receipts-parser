/// Files and text shared into the app ("Share" / "Open with" on Android):
/// the native side copies each stream into the cache and hands the list
/// over; whatever arrived before the Dart side was ready is fetched with
/// [init]. Listeners take the items with [take].
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SharedItem {
  const SharedItem({required this.name, required this.mime, this.path, this.text, this.error, this.action});
  final String name;
  final String mime;

  /// A launcher shortcut or widget button: 'scan', 'entry' or 'statement'.
  final String? action;

  /// Local copy of a shared file (null for shared text or a failed copy).
  final String? path;
  final String? text;
  final String? error;

  bool get isPdf => mime == 'application/pdf' || name.toLowerCase().endsWith('.pdf');
  bool get isImage => mime.startsWith('image/');
  bool get isText => text != null;

  static SharedItem fromMap(Map<Object?, Object?> m) => SharedItem(
        name: (m['name'] as String?) ?? '',
        mime: (m['mime'] as String?) ?? '',
        path: m['path'] as String?,
        text: m['text'] as String?,
        error: m['error'] as String?,
        action: m['action'] as String?,
      );
}

abstract class ShareSource {
  Future<List<SharedItem>> pending();
  void onShared(void Function(List<SharedItem>) handler);
  Future<void> discard(SharedItem item);
}

class PlatformShareSource implements ShareSource {
  static const _channel = MethodChannel('dev.artiz.az_budget/share');

  @override
  Future<List<SharedItem>> pending() async {
    try {
      final list = await _channel.invokeMethod<List<Object?>>('getPending');
      return [for (final m in list ?? const []) SharedItem.fromMap(m as Map<Object?, Object?>)];
    } on MissingPluginException {
      return const [];
    }
  }

  @override
  void onShared(void Function(List<SharedItem>) handler) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'shared') {
        final list = call.arguments as List<Object?>;
        handler([for (final m in list) SharedItem.fromMap(m as Map<Object?, Object?>)]);
      }
    });
  }

  @override
  Future<void> discard(SharedItem item) async {
    final p = item.path;
    if (p == null) return;
    try {
      await _channel.invokeMethod<void>('discard', {'path': p});
    } catch (_) {}
  }
}

/// Hand text to the system share sheet (a month summary).
class PlatformShare {
  PlatformShare._();
  static const _channel = MethodChannel('dev.artiz.az_budget/share');

  static Future<void> text({required String title, required String text}) async {
    try {
      await _channel.invokeMethod<void>('shareText', {'title': title, 'text': text});
    } on MissingPluginException {
      // No share sheet on this platform.
    }
  }
}

class ShareReceiver extends ChangeNotifier {
  ShareReceiver(this.source);
  final ShareSource source;
  final List<SharedItem> _queue = [];

  bool get hasItems => _queue.isNotEmpty;

  Future<void> init() async {
    source.onShared(_add);
    _add(await source.pending());
  }

  void _add(List<SharedItem> items) {
    if (items.isEmpty) return;
    _queue.addAll(items);
    notifyListeners();
  }

  /// Everything queued so far; the queue is emptied.
  List<SharedItem> take() {
    final out = List<SharedItem>.of(_queue);
    _queue.clear();
    return out;
  }
}
