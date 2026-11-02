/// The JSON contract of `rust/receipt_ocr` (see `OcrResult` there).
library;

class OcrLine {
  OcrLine({
    required this.text,
    required this.confidence,
    required this.detScore,
    required this.x0,
    required this.y0,
    required this.x1,
    required this.y1,
  });

  factory OcrLine.fromJson(Map<String, dynamic> j) => OcrLine(
        text: j['text'] as String,
        confidence: (j['confidence'] as num).toDouble(),
        detScore: (j['det_score'] as num? ?? 0).toDouble(),
        x0: (j['x0'] as num).toDouble(),
        y0: (j['y0'] as num).toDouble(),
        x1: (j['x1'] as num).toDouble(),
        y1: (j['y1'] as num).toDouble(),
      );

  final String text;
  final double confidence;
  final double detScore;
  final double x0, y0, x1, y1;

  double get cx => (x0 + x1) / 2;
  double get cy => (y0 + y1) / 2;
  double get height => y1 - y0;
  double get width => x1 - x0;

  Map<String, dynamic> toJson() => {
        'text': text,
        'confidence': confidence,
        'det_score': detScore,
        'x0': x0,
        'y0': y0,
        'x1': x1,
        'y1': y1,
      };
}

class OcrQr {
  OcrQr({required this.text, required this.x0, required this.y0, required this.x1, required this.y1});

  factory OcrQr.fromJson(Map<String, dynamic> j) => OcrQr(
        text: j['text'] as String,
        x0: (j['x0'] as num).toDouble(),
        y0: (j['y0'] as num).toDouble(),
        x1: (j['x1'] as num).toDouble(),
        y1: (j['y1'] as num).toDouble(),
      );

  final String text;
  final double x0, y0, x1, y1;
}

class OcrResult {
  OcrResult({
    required this.width,
    required this.height,
    required this.lines,
    required this.qrCodes,
    this.elapsedMs = 0,
    this.engine = '',
  });

  factory OcrResult.fromJson(Map<String, dynamic> j) => OcrResult(
        width: (j['width'] as num).toInt(),
        height: (j['height'] as num).toInt(),
        lines: (j['lines'] as List<dynamic>)
            .map((e) => OcrLine.fromJson(e as Map<String, dynamic>))
            .toList(),
        qrCodes: (j['qr_codes'] as List<dynamic>? ?? const [])
            .map((e) => OcrQr.fromJson(e as Map<String, dynamic>))
            .toList(),
        elapsedMs: (j['elapsed_ms'] as num? ?? 0).toInt(),
        engine: j['engine'] as String? ?? '',
      );

  final int width;
  final int height;
  final List<OcrLine> lines;
  final List<OcrQr> qrCodes;
  final int elapsedMs;
  final String engine;
}
