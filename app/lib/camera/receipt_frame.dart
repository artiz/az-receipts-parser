/// Finds a receipt between two vertical guide lines in a camera frame, for
/// the auto-capture of the in-app camera.
///
/// Works on the luminance (Y) plane only, downsampled to a small upright
/// grid (block averages, so receipt text blurs into the paper). A paper
/// edge is a long, nearly vertical line where the brightness steps the same
/// way in every row: summed over the middle rows, the signed horizontal
/// step peaks there, while carpet texture and text cancel out. The
/// strongest rising step left of the centre and the strongest falling step
/// right of it are the receipt's edges; they are compared with the guides.
/// About a millisecond per frame in plain Dart; no model.
library;

import 'dart:math' as math;
import 'dart:typed_data';

/// A small upright luminance image: row-major, [width] × [height] bytes.
class LumaGrid {
  LumaGrid(this.width, this.height, this.values) : assert(values.length == width * height);

  final int width;
  final int height;
  final Uint8List values;

  int at(int x, int y) => values[y * width + x];

  /// Downsample a Y plane ([planeWidth] × [planeHeight] pixels, [rowStride]
  /// bytes per row) to a grid [gridWidth] cells wide, rotated clockwise by
  /// [rotation] degrees (0, 90, 180, 270) so that the grid is upright as the
  /// user sees the preview. Each cell is the mean of 3 × 3 samples inside
  /// it.
  factory LumaGrid.fromPlane(
    Uint8List plane, {
    required int planeWidth,
    required int planeHeight,
    required int rowStride,
    int rotation = 0,
    int gridWidth = 72,
  }) {
    final rot = ((rotation % 360) + 360) % 360;
    final swap = rot == 90 || rot == 270;
    // Upright size of the frame.
    final uw = swap ? planeHeight : planeWidth;
    final uh = swap ? planeWidth : planeHeight;
    final gw = gridWidth;
    final gh = math.max(1, (gridWidth * uh / uw).round());
    final out = Uint8List(gw * gh);
    final cellW = uw / gw;
    final cellH = uh / gh;
    const k = 3;
    for (var gy = 0; gy < gh; gy++) {
      for (var gx = 0; gx < gw; gx++) {
        var sum = 0;
        for (var j = 0; j < k; j++) {
          final v = ((gy + (j + 0.5) / k) * cellH).floor().clamp(0, uh - 1);
          for (var i = 0; i < k; i++) {
            final u = ((gx + (i + 0.5) / k) * cellW).floor().clamp(0, uw - 1);
            // Upright (u, v) → source (x, y) for a clockwise rotation.
            final int x, y;
            switch (rot) {
              case 90:
                x = v;
                y = planeHeight - 1 - u;
              case 180:
                x = planeWidth - 1 - u;
                y = planeHeight - 1 - v;
              case 270:
                x = planeWidth - 1 - v;
                y = u;
              default:
                x = u;
                y = v;
            }
            sum += plane[y * rowStride + x];
          }
        }
        out[gy * gw + gx] = (sum / (k * k)).round();
      }
    }
    return LumaGrid(gw, gh, out);
  }

  /// How much the picture moved between two frames (same size): the mean
  /// absolute difference, 0..255, after removing the overall brightness
  /// change, so the camera adjusting its exposure does not count as motion.
  double motionTo(LumaGrid other) {
    if (other.width != width || other.height != height) return 255;
    var shift = 0;
    for (var i = 0; i < values.length; i++) {
      shift += values[i] - other.values[i];
    }
    final mean = shift / values.length;
    var sum = 0.0;
    for (var i = 0; i < values.length; i++) {
      sum += (values[i] - other.values[i] - mean).abs();
    }
    return sum / values.length;
  }
}

/// Where the two guide lines are, as fractions of the frame width.
class Guides {
  const Guides({this.left = 0.17, this.right = 0.83, this.tolerance = 0.06});
  final double left;
  final double right;

  /// How far (fraction of the width) a paper edge may be from its line.
  final double tolerance;

  double get width => right - left;
}

/// What the camera page tells the user.
enum FrameHint {
  /// No paper-like area through the middle of the frame.
  searching,

  /// Paper and background too alike (white receipt on a white table).
  lowContrast,

  /// The receipt is narrower than the lines: bring the phone closer.
  closer,

  /// The receipt is wider than the lines or runs off the frame.
  further,

  /// The right width, but off to one side.
  center,

  /// Both edges on their lines.
  aligned,
}

class ReceiptDetection {
  const ReceiptDetection({required this.hint, this.left, this.right, this.coverage = 0, this.contrast = 0});

  final FrameHint hint;

  /// Paper edges as fractions of the frame width (null when not found).
  final double? left;
  final double? right;

  /// Share of the middle rows in which the paper was found.
  final double coverage;

  /// Mean brightness of the paper minus that of the background.
  final double contrast;

  bool get aligned => hint == FrameHint.aligned;

  /// The whole receipt is in the picture: both edges found, neither at the
  /// frame border. Enough for a shot; the guides only help to get there.
  bool get framed => left != null && right != null && left! > borderZone && right! < 1 - borderZone;

  @override
  String toString() => 'ReceiptDetection($hint, left: ${left?.toStringAsFixed(3)}, right: ${right?.toStringAsFixed(3)}, '
      'coverage: ${coverage.toStringAsFixed(2)}, contrast: ${contrast.toStringAsFixed(0)})';
}

/// Find the receipt in [grid] and compare it with [guides].
ReceiptDetection detectReceipt(LumaGrid grid, {Guides guides = const Guides()}) {
  final w = grid.width;
  final h = grid.height;
  final y0 = (h * 0.1).floor();
  final y1 = (h * 0.9).ceil();
  final rows = y1 - y0;
  // Signed horizontal step per cell, and its mean per column.
  final step = List<Float64List>.generate(rows, (_) => Float64List(w));
  final mean = Float64List(w);
  var sum = 0;
  for (var r = 0; r < rows; r++) {
    final y = y0 + r;
    for (var x = 1; x < w - 1; x++) {
      final d = (grid.at(x + 1, y) - grid.at(x - 1, y)) / 2;
      step[r][x] = d;
      mean[x] += d / rows;
    }
    for (var x = 0; x < w; x++) {
      sum += grid.at(x, y);
    }
  }
  final brightness = sum / (rows * w);
  // The outermost columns often hold lens vignetting, not an edge.
  final margin = math.max(1, (w * 0.03).round());
  final c = w ~/ 2;
  var l = margin;
  for (var x = margin; x < c; x++) {
    if (mean[x] > mean[l]) l = x;
  }
  var r = c;
  for (var x = c; x < w - margin; x++) {
    if (mean[x] < mean[r]) r = x;
  }
  // Share of the rows in which the edge shows (best of the three columns around it).
  double coverageAt(int x, int sign) {
    var n = 0;
    for (final row in step) {
      var best = 0.0;
      for (var i = math.max(1, x - 1); i <= math.min(w - 2, x + 1); i++) {
        if (row[i] * sign > best) best = row[i] * sign;
      }
      if (best >= minRowStep) n++;
    }
    return n / step.length;
  }

  final covL = coverageAt(l, 1);
  final covR = coverageAt(r, -1);
  final strongL = mean[l] >= minStep && covL >= minCoverage;
  final strongR = -mean[r] >= minStep && covR >= minCoverage;
  final left = l / w;
  final right = (r + 1) / w;
  final contrast = (math.max(0.0, mean[l]) + math.max(0.0, -mean[r])) / 2;
  final coverage = math.min(covL, covR);
  if (!strongL && !strongR) {
    // Nothing that looks like paper edges: a bright, even picture is most
    // likely a white receipt on a white surface.
    return ReceiptDetection(hint: brightness >= 150 ? FrameHint.lowContrast : FrameHint.searching, coverage: coverage, contrast: contrast);
  }
  ReceiptDetection result(FrameHint hint) =>
      ReceiptDetection(hint: hint, left: strongL ? left : null, right: strongR ? right : null, coverage: coverage, contrast: contrast);
  // One edge missing, or one at the frame's border: the receipt runs off.
  if (!strongL || !strongR || left <= borderZone || right >= 1 - borderZone) return result(FrameHint.further);
  final tol = guides.tolerance;
  final width = right - left;
  if (width < 0.2) return result(FrameHint.searching);
  if ((left - guides.left).abs() <= tol && (right - guides.right).abs() <= tol) return result(FrameHint.aligned);
  if (width < guides.width - tol) return result(FrameHint.closer);
  if (width > guides.width + tol) return result(FrameHint.further);
  return result(FrameHint.center);
}

/// Mean step (0..255 per cell) a column needs to count as a paper edge.
const double minStep = 8;

/// A row counts for an edge when its step there is at least this large.
const double minRowStep = 6;

/// The edge must show in at least this share of the middle rows.
const double minCoverage = 0.6;

/// An edge this close to the frame border means the receipt runs off it.
const double borderZone = 0.05;

/// Steadiness and hold time before an automatic shot.
class AutoCapture {
  AutoCapture({this.hold = const Duration(milliseconds: 300), this.maxMotion = 10});

  /// How long the receipt must stay framed.
  final Duration hold;

  /// Largest frame-to-frame change (mean absolute difference) still
  /// counted as holding still.
  final double maxMotion;

  DateTime? _since;
  bool _fired = false;

  bool get fired => _fired;

  /// Feed one analysed frame ([aligned]: the receipt is framed). Returns the
  /// progress towards the shot (0..1);
  /// [fired] turns true once, when it reaches 1.
  double update({required bool aligned, required double motion, required DateTime now}) {
    if (_fired) return 1;
    if (!aligned || motion > maxMotion) {
      _since = null;
      return 0;
    }
    final since = _since ??= now;
    final p = hold.inMicroseconds == 0 ? 1.0 : (now.difference(since).inMicroseconds / hold.inMicroseconds).clamp(0.0, 1.0);
    if (p >= 1) _fired = true;
    return p;
  }

  /// Start over (after a manual shot failed, or the user turned auto back on).
  void reset() {
    _since = null;
    _fired = false;
  }
}
