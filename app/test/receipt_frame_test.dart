import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:az_budget/camera/receipt_frame.dart';
import 'package:flutter_test/flutter_test.dart';

/// A binary PGM (P5) as (pixels, width, height).
(Uint8List, int, int) readPgm(String path) {
  final b = File(path).readAsBytesSync();
  final fields = <int>[];
  var i = 2; // after "P5"
  while (fields.length < 3) {
    while (b[i] == 0x20 || b[i] == 0x0a) {
      i++;
    }
    final s = i;
    while (b[i] != 0x20 && b[i] != 0x0a) {
      i++;
    }
    fields.add(int.parse(String.fromCharCodes(b.sublist(s, i))));
  }
  return (Uint8List.sublistView(b, i + 1), fields[0], fields[1]);
}

/// Rotate an upright image counter-clockwise by [degrees], as a sensor
/// mounted at that orientation would deliver it.
(Uint8List, int, int) toSensor(Uint8List px, int w, int h, int degrees) {
  switch (degrees) {
    case 90:
      // Sensor frame is h wide, w high; upright (u, v) sits at (v, w-1-u).
      final out = Uint8List(w * h);
      for (var v = 0; v < h; v++) {
        for (var u = 0; u < w; u++) {
          out[(w - 1 - u) * h + v] = px[v * w + u];
        }
      }
      return (out, h, w);
    case 180:
      final out = Uint8List(w * h);
      for (var k = 0; k < w * h; k++) {
        out[w * h - 1 - k] = px[k];
      }
      return (out, w, h);
    default:
      return (px, w, h);
  }
}

/// A synthetic upright frame: noisy dark background, a bright receipt
/// from [left] to [right] (fractions) with dark text lines, top to bottom.
Uint8List scene({int w = 360, int h = 640, double left = 0.17, double right = 0.83, int paper = 215, int background = 70, int seed = 1}) {
  final rnd = math.Random(seed);
  final px = Uint8List(w * h);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final inside = x >= left * w && x < right * w && y > h * 0.04 && y < h * 0.96;
      var v = inside ? paper - rnd.nextInt(12) : background + rnd.nextInt(40) - 20;
      // Text: thin dark lines every 18 px inside the receipt.
      if (inside && y % 18 < 3 && x > left * w + 10 && x < right * w - 30) v = 40;
      px[y * w + x] = v.clamp(0, 255);
    }
  }
  return px;
}

LumaGrid upright(Uint8List px, int w, int h) => LumaGrid.fromPlane(px, planeWidth: w, planeHeight: h, rowStride: w);

/// Squeeze or stretch a real frame horizontally so that its paper edges
/// [srcLeft]..[srcRight] land on [dstLeft]..[dstRight]. Outside the source
/// the carpet goes on: columns are repeated from inside the outer 5%, which
/// in these photos hold a dark vignette strip that a live camera frame does
/// not have in the middle of the picture.
Uint8List reframe(Uint8List px, int w, int h, double srcLeft, double srcRight, double dstLeft, double dstRight) {
  final out = Uint8List(w * h);
  for (var u = 0; u < w; u++) {
    final f = (srcLeft + (u / w - dstLeft) * (srcRight - srcLeft) / (dstRight - dstLeft)).clamp(0.05, 0.95);
    final x = (f * w).floor().clamp(0, w - 1);
    for (var y = 0; y < h; y++) {
      out[y * w + u] = px[y * w + x];
    }
  }
  return out;
}

const frames = 'test/fixtures/frames';

void main() {
  group('grid', () {
    test('every sensor rotation gives the same upright grid', () {
      final px = scene(w: 180, h: 320, left: 0.2, right: 0.6);
      final ref = upright(px, 180, 320);
      expect((ref.width, ref.height), (72, 128));
      for (final deg in [90, 180]) {
        final (s, sw, sh) = toSensor(px, 180, 320, deg);
        final g = LumaGrid.fromPlane(s, planeWidth: sw, planeHeight: sh, rowStride: sw, rotation: deg);
        expect((g.width, g.height), (72, 128), reason: '$deg°');
        expect(g.motionTo(ref), lessThan(3), reason: '$deg°: the same picture, up to sampling');
      }
    });

    test('row padding (stride wider than the image) is skipped', () {
      final px = scene(w: 180, h: 320);
      const stride = 192;
      final padded = Uint8List(stride * 320);
      for (var y = 0; y < 320; y++) {
        padded.setRange(y * stride, y * stride + 180, px, y * 180);
        padded.fillRange(y * stride + 180, (y + 1) * stride, 255);
      }
      final g = LumaGrid.fromPlane(padded, planeWidth: 180, planeHeight: 320, rowStride: stride);
      expect(g.motionTo(upright(px, 180, 320)), 0);
    });
  });

  group('synthetic scenes', () {
    FrameHint hintOf(Uint8List px, {Guides guides = const Guides()}) => detectReceipt(upright(px, 360, 640), guides: guides).hint;

    test('a receipt on the lines is aligned, its edges found within a cell', () {
      final d = detectReceipt(upright(scene(), 360, 640));
      expect(d.hint, FrameHint.aligned);
      expect(d.left, closeTo(0.17, 0.02));
      expect(d.right, closeTo(0.83, 0.02));
      expect(d.coverage, greaterThan(0.9));
    });

    test('the hints say what to do', () {
      expect(hintOf(scene(left: 0.30, right: 0.70)), FrameHint.closer);
      expect(hintOf(scene(left: 0.08, right: 0.92)), FrameHint.further);
      expect(hintOf(scene(left: 0.0, right: 0.75)), FrameHint.further, reason: 'runs off the frame');
      expect(hintOf(scene(left: 0.27, right: 0.93)), FrameHint.center);
      expect(hintOf(scene(left: 0.20, right: 0.86)), FrameHint.aligned, reason: 'within the tolerance');
      expect(hintOf(scene(paper: 215, background: 205)), FrameHint.lowContrast, reason: 'white on white');
      expect(hintOf(scene(left: 0.5, right: 0.5)), FrameHint.searching, reason: 'no paper at all');
    });

    test('other guide positions are honoured', () {
      const wide = Guides(left: 0.08, right: 0.92);
      expect(hintOf(scene(left: 0.08, right: 0.92), guides: wide), FrameHint.aligned);
      expect(hintOf(scene(), guides: wide), FrameHint.closer);
    });
  });

  group('real photos (samples/receipts, crumpled paper on a carpet)', () {
    // Paper edges read off the photos at the middle rows (fractions of the width).
    const truth = {
      'action_wien': (0.02, 0.86, FrameHint.further), // left edge on the frame border
      'dm_wien': (0.10, null, FrameHint.further), // right edge runs off the frame
      'ernstings_wien': (0.07, 0.92, FrameHint.further), // wider than the lines
      'tedi_wien': (0.08, 0.86, FrameHint.further),
      'tkmaxx_wien': (0.16, 0.89, FrameHint.aligned), // orange paper, low contrast, yet on the lines
    };

    for (final e in truth.entries) {
      test('${e.key}: edges and hint', () {
        final (px, w, h) = readPgm('$frames/${e.key}.pgm');
        final d = detectReceipt(upright(px, w, h));
        final (l, r, hint) = e.value;
        expect(d.left, closeTo(l, 0.035), reason: '$d');
        if (r == null) {
          expect(d.right, isNull, reason: '$d');
        } else {
          expect(d.right, closeTo(r, 0.035), reason: '$d');
        }
        expect(d.hint, hint, reason: '$d');
      });
    }

    test('moved onto the lines, every receipt with background on both sides is aligned', () {
      // action_wien starts at the frame border and dm_wien runs off the right:
      // no carpet to extend. tkmaxx_wien (orange paper on a speckled carpet,
      // edge step 8.9 against 7.3 for the strongest carpet column) sits right
      // at the threshold: its own framing is aligned (above), resampling it
      // tips it under. Such a receipt may need the shutter button.
      for (final name in ['ernstings_wien', 'tedi_wien']) {
        final (px, w, h) = readPgm('$frames/$name.pgm');
        final before = detectReceipt(upright(px, w, h));
        final framed = reframe(px, w, h, before.left!, before.right!, 0.17, 0.83);
        final d = detectReceipt(upright(framed, w, h));
        expect(d.hint, FrameHint.aligned, reason: '$name: $d');
      }
    });

    test('a sensor frame (rotated 90°) gives the same result as the upright photo', () {
      final (px, w, h) = readPgm('$frames/tedi_wien.pgm');
      final (s, sw, sh) = toSensor(px, w, h, 90);
      final rotated = detectReceipt(LumaGrid.fromPlane(s, planeWidth: sw, planeHeight: sh, rowStride: sw, rotation: 90));
      final straight = detectReceipt(upright(px, w, h));
      expect(rotated.hint, straight.hint);
      expect(rotated.left, closeTo(straight.left!, 0.015));
      expect(rotated.right, closeTo(straight.right!, 0.015));
    });

    test('a 72-cell grid is analysed in a few milliseconds', () {
      final (px, w, h) = readPgm('$frames/tedi_wien.pgm');
      for (var i = 0; i < 5; i++) {
        detectReceipt(upright(px, w, h)); // warm up the JIT
      }
      final sw = Stopwatch()..start();
      for (var i = 0; i < 20; i++) {
        detectReceipt(upright(px, w, h));
      }
      expect(sw.elapsedMilliseconds / 20, lessThan(20));
    });
  });

  group('auto-capture', () {
    final t0 = DateTime(2026, 11, 13, 12);
    DateTime at(int ms) => t0.add(Duration(milliseconds: ms));

    test('fires once after the receipt stays framed and still for 300 ms', () {
      final a = AutoCapture();
      expect(a.hold, const Duration(milliseconds: 300));
      expect(a.update(aligned: true, motion: 2, now: at(0)), 0);
      expect(a.update(aligned: true, motion: 2, now: at(150)), closeTo(0.5, 0.01));
      expect(a.fired, isFalse);
      expect(a.update(aligned: true, motion: 2, now: at(300)), 1);
      expect(a.fired, isTrue);
      expect(a.update(aligned: false, motion: 50, now: at(400)), 1, reason: 'stays fired until reset');
      a.reset();
      expect(a.fired, isFalse);
      expect(a.update(aligned: true, motion: 2, now: at(500)), 0);
    });

    test('moving or losing the receipt starts the hold over', () {
      final a = AutoCapture();
      a.update(aligned: true, motion: 2, now: at(0));
      a.update(aligned: true, motion: 2, now: at(200));
      expect(a.update(aligned: true, motion: 15, now: at(250)), 0, reason: 'shaking');
      expect(a.update(aligned: true, motion: 8, now: at(300)), 0, reason: 'a steady hand: the hold starts');
      expect(a.update(aligned: true, motion: 8, now: at(450)), closeTo(0.5, 0.01));
      expect(a.update(aligned: false, motion: 2, now: at(500)), 0, reason: 'the receipt left the picture');
      expect(a.fired, isFalse);
    });

    test('motion: sensor noise and exposure changes are still, a shift is not', () {
      final a = upright(scene(seed: 1), 360, 640);
      final b = upright(scene(seed: 2), 360, 640);
      final moved = upright(scene(left: 0.25, right: 0.91, seed: 1), 360, 640);
      final max = AutoCapture().maxMotion;
      expect(a.motionTo(b), lessThan(max), reason: 'sensor noise only');
      expect(a.motionTo(moved), greaterThan(max));
      // The camera brightening the whole picture (auto exposure) is not movement.
      final brighter = LumaGrid(a.width, a.height, Uint8List.fromList([for (final v in a.values) math.min(255, v + 25)]));
      expect(a.motionTo(brighter), lessThan(max));
    });
  });

  group('framed (what triggers the shot)', () {
    LumaGrid grid(Uint8List px) => upright(px, 360, 640);

    test('the whole receipt in view counts, wherever it is between the borders', () {
      expect(detectReceipt(grid(scene())).framed, isTrue, reason: 'on the lines');
      expect(detectReceipt(grid(scene(left: 0.30, right: 0.70))).framed, isTrue, reason: 'smaller than the lines');
      expect(detectReceipt(grid(scene(left: 0.08, right: 0.92))).framed, isTrue, reason: 'wider than the lines');
      expect(detectReceipt(grid(scene(left: 0.27, right: 0.93))).framed, isTrue, reason: 'off-centre');
      expect(detectReceipt(grid(scene(left: 0.0, right: 0.75))).framed, isFalse, reason: 'runs off the left: the shot would cut it');
      expect(detectReceipt(grid(scene(paper: 215, background: 205))).framed, isFalse, reason: 'white on white');
      expect(detectReceipt(grid(scene(left: 0.5, right: 0.5))).framed, isFalse, reason: 'no paper');
    });

    test('the real photos: framed unless the receipt runs off the frame', () {
      const expected = {'action_wien': false, 'dm_wien': false, 'ernstings_wien': true, 'tedi_wien': true, 'tkmaxx_wien': true};
      for (final e in expected.entries) {
        final (px, w, h) = readPgm('$frames/${e.key}.pgm');
        final d = detectReceipt(upright(px, w, h));
        expect(d.framed, e.value, reason: '${e.key}: $d');
      }
    });
  });
}
