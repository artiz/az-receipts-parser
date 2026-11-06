import 'package:az_budget/storage/share_receiver.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeShareSource implements ShareSource {
  FakeShareSource(this.initial);
  List<SharedItem> initial;
  void Function(List<SharedItem>)? handler;
  final discarded = <String>[];

  @override
  Future<List<SharedItem>> pending() async {
    final out = initial;
    initial = const [];
    return out;
  }

  @override
  void onShared(void Function(List<SharedItem>) h) => handler = h;

  @override
  Future<void> discard(SharedItem item) async => discarded.add(item.name);
}

void main() {
  test('items shared before and after start are queued, taken once, classified', () async {
    final source = FakeShareSource([const SharedItem(name: 'bon.pdf', mime: 'application/pdf', path: '/c/bon.pdf')]);
    final receiver = ShareReceiver(source);
    var notified = 0;
    receiver.addListener(() => notified++);
    await receiver.init();
    expect(receiver.hasItems, isTrue);
    expect(notified, 1);
    source.handler!([
      SharedItem.fromMap({'name': 'shot.jpg', 'mime': 'image/jpeg', 'path': '/c/shot.jpg'}),
      SharedItem.fromMap({'name': 'text', 'mime': 'text/plain', 'text': 'Spar 12,30'}),
      SharedItem.fromMap({'name': 'content://x', 'error': 'no stream'}),
    ]);
    expect(notified, 2);
    final items = receiver.take();
    expect(items.map((i) => i.name), ['bon.pdf', 'shot.jpg', 'text', 'content://x']);
    expect(items[0].isPdf, isTrue);
    expect(items[1].isImage, isTrue);
    expect(items[2].isText, isTrue);
    expect(items[3].error, 'no stream');
    expect(receiver.hasItems, isFalse);
    expect(receiver.take(), isEmpty);
    expect(const SharedItem(name: 'x.PDF', mime: 'application/octet-stream').isPdf, isTrue);
    source.handler!(const []);
    expect(notified, 2, reason: 'an empty delivery is not an event');
  });
}
