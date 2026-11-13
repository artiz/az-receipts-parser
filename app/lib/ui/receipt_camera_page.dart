/// The app's own camera for receipts: a full-screen preview with two
/// vertical guide lines. Every few frames the luminance is checked for the
/// receipt's edges (camera/receipt_frame.dart); once they sit on the lines
/// and the phone holds still, the photo is taken by itself. The shutter
/// button works at any time.
library;

import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app.dart';
import '../camera/receipt_frame.dart';
import '../l10n/app_localizations.dart';

/// What the camera page ended with (null: closed without a photo).
sealed class CameraOutcome {
  const CameraOutcome();
}

/// A photo was taken; [path] is a JPEG in the app's cache.
class CameraShot extends CameraOutcome {
  const CameraShot(this.path);
  final String path;
}

/// The camera could not be used (no permission, none present, failed to
/// start): the caller falls back to the phone's camera app.
class CameraUnavailable extends CameraOutcome {
  const CameraUnavailable(this.reason);
  final String reason;
}

Future<CameraOutcome?> openReceiptCamera(BuildContext context, {ReceiptCameraPage page = const ReceiptCameraPage()}) =>
    Navigator.of(context).push<CameraOutcome>(MaterialPageRoute(fullscreenDialog: true, builder: (_) => page));

class ReceiptCameraPage extends StatefulWidget {
  const ReceiptCameraPage({super.key, this.guides = const Guides(), this.clock = DateTime.now});
  final Guides guides;

  /// Time source for the frame throttle and the hold (tests drive it).
  @visibleForTesting
  final DateTime Function() clock;

  @override
  State<ReceiptCameraPage> createState() => _ReceiptCameraPageState();
}

class _ReceiptCameraPageState extends State<ReceiptCameraPage> with WidgetsBindingObserver {
  /// Frames are analysed at most this often; the rest are dropped.
  static const Duration frameInterval = Duration(milliseconds: 100);

  CameraController? _controller;
  bool _starting = false;
  bool _capturing = false;
  bool _streaming = false;
  bool _torch = false;
  bool _processing = false;
  DateTime _lastFrame = DateTime.fromMillisecondsSinceEpoch(0);
  LumaGrid? _previous;
  ReceiptDetection _detection = const ReceiptDetection(hint: FrameHint.searching);
  double _progress = 0;
  final AutoCapture _auto = AutoCapture();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // The guides and the analysis assume a portrait preview.
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setPreferredOrientations(const []);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The camera is released while the app is in the background.
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      final c = _controller;
      _controller = null;
      _streaming = false;
      if (mounted) setState(() {});
      c?.dispose();
    } else if (state == AppLifecycleState.resumed && _controller == null) {
      _start();
    }
  }

  bool get _autoOn => AppScope.of(context).settings.autoCapture;

  Future<void> _start() async {
    if (_starting || !mounted) return;
    _starting = true;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return _leave(const CameraUnavailable('no camera'));
      final back = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back, orElse: () => cameras.first);
      // ~4K: the photo is what the OCR reads; CameraX falls back to what the device offers.
      final controller = CameraController(back, ResolutionPreset.ultraHigh, enableAudio: false, imageFormatGroup: ImageFormatGroup.yuv420);
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
      await controller.setFlashMode(_torch ? FlashMode.torch : FlashMode.off);
      setState(() => _controller = controller);
      if (_autoOn) await _startStream();
    } on CameraException catch (e) {
      _leave(CameraUnavailable(e.code));
    } catch (e) {
      _leave(CameraUnavailable(e.toString()));
    } finally {
      _starting = false;
    }
  }

  void _leave(CameraOutcome outcome) {
    if (mounted) Navigator.of(context).pop(outcome);
  }

  Future<void> _startStream() async {
    final c = _controller;
    if (c == null || _streaming || !c.value.isInitialized) return;
    _previous = null;
    _auto.reset();
    try {
      await c.startImageStream(_onFrame);
      _streaming = true;
    } on CameraException {
      _streaming = false; // auto-capture unavailable on this device; the shutter still works
    }
  }

  Future<void> _stopStream() async {
    final c = _controller;
    if (c == null || !_streaming) return;
    _streaming = false;
    try {
      await c.stopImageStream();
    } on CameraException {
      // already stopped
    }
  }

  void _onFrame(CameraImage image) {
    final now = widget.clock();
    if (_processing || _capturing || now.difference(_lastFrame) < frameInterval) return;
    _processing = true;
    _lastFrame = now;
    try {
      final c = _controller;
      if (c == null) return;
      final y = image.planes.first;
      // Frames come in sensor orientation; the preview is portrait.
      final rotation = image.width > image.height ? c.description.sensorOrientation : 0;
      final grid = LumaGrid.fromPlane(y.bytes, planeWidth: image.width, planeHeight: image.height, rowStride: y.bytesPerRow, rotation: rotation);
      final detection = detectReceipt(grid, guides: widget.guides);
      final motion = _previous == null ? 255.0 : grid.motionTo(_previous!);
      _previous = grid;
      final progress = _auto.update(aligned: detection.aligned, motion: motion, now: now);
      if (mounted) {
        setState(() {
          _detection = detection;
          _progress = progress;
        });
      }
      if (_auto.fired) unawaited(_capture());
    } finally {
      _processing = false;
    }
  }

  Future<void> _capture() async {
    final c = _controller;
    if (c == null || _capturing || !c.value.isInitialized) return;
    setState(() => _capturing = true);
    try {
      await _stopStream();
      final file = await c.takePicture();
      HapticFeedback.mediumImpact();
      _leave(CameraShot(file.path));
    } on CameraException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.description ?? e.code)));
      setState(() {
        _capturing = false;
        _progress = 0;
      });
      if (_autoOn) await _startStream();
    }
  }

  Future<void> _toggleTorch() async {
    final c = _controller;
    if (c == null) return;
    final on = !_torch;
    try {
      await c.setFlashMode(on ? FlashMode.torch : FlashMode.off);
      setState(() => _torch = on);
    } on CameraException {
      // no torch on this camera
    }
  }

  Future<void> _toggleAuto() async {
    final settings = AppScope.of(context).settings;
    final on = !settings.autoCapture;
    await settings.setAutoCapture(on);
    if (on) {
      await _startStream();
    } else {
      await _stopStream();
      _detection = const ReceiptDetection(hint: FrameHint.searching);
      _progress = 0;
    }
    if (mounted) setState(() {});
  }

  void _focusAt(TapUpDetails d, Size size) {
    final c = _controller;
    if (c == null) return;
    final p = Offset((d.localPosition.dx / size.width).clamp(0.0, 1.0), (d.localPosition.dy / size.height).clamp(0.0, 1.0));
    c.setFocusPoint(p).catchError((_) {});
    c.setExposurePoint(p).catchError((_) {});
  }

  String _hint(AppLocalizations l) {
    if (!_autoOn) return l.cameraHintManual;
    if (_progress > 0) return l.cameraHintHold;
    return switch (_detection.hint) {
      FrameHint.searching => l.cameraHintSearching,
      FrameHint.lowContrast => l.cameraHintLowContrast,
      FrameHint.closer => l.cameraHintCloser,
      FrameHint.further => l.cameraHintFurther,
      FrameHint.center => l.cameraHintCenter,
      FrameHint.aligned => l.cameraHintHold,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = _controller;
    final auto = _autoOn;
    final aligned = auto && _detection.aligned;
    final seen = auto && (_detection.left != null || _detection.right != null);
    final lineColor = aligned ? Colors.greenAccent : (seen ? Colors.amberAccent : Colors.white);
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: c == null || !c.value.isInitialized
                  ? const CircularProgressIndicator(color: Colors.white)
                  : CameraPreview(
                      c,
                      child: LayoutBuilder(
                        builder: (context, box) => GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapUp: (d) => _focusAt(d, box.biggest),
                          child: CustomPaint(
                            size: box.biggest,
                            painter: _GuidesPainter(guides: widget.guides, color: lineColor, detection: auto ? _detection : null),
                          ),
                        ),
                      ),
                    ),
            ),
            Positioned(
              top: 4,
              left: 4,
              right: 4,
              child: Row(
                children: [
                  IconButton(
                    tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: l.cameraAutoCapture,
                    icon: Icon(auto ? Icons.motion_photos_auto_outlined : Icons.motion_photos_off_outlined, color: Colors.white),
                    onPressed: _toggleAuto,
                  ),
                  IconButton(
                    tooltip: l.cameraTorch,
                    icon: Icon(_torch ? Icons.flash_on : Icons.flash_off, color: Colors.white),
                    onPressed: _toggleTorch,
                  ),
                ],
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 20,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(18)),
                    child: Text(_hint(l), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 15)),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 84,
                    height: 84,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox.expand(
                          child: CircularProgressIndicator(
                            value: _capturing ? null : _progress,
                            strokeWidth: 5,
                            color: Colors.greenAccent,
                            backgroundColor: Colors.white24,
                          ),
                        ),
                        Material(
                          color: Colors.white,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: c == null || _capturing ? null : _capture,
                            child: SizedBox(
                              width: 66,
                              height: 66,
                              child: Icon(Icons.receipt_long, color: Colors.black.withValues(alpha: _capturing ? 0.3 : 0.8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The two guide lines; the paper edges found, faint, when the receipt is
/// in view but not yet on them.
class _GuidesPainter extends CustomPainter {
  _GuidesPainter({required this.guides, required this.color, this.detection});
  final Guides guides;
  final Color color;
  final ReceiptDetection? detection;

  @override
  void paint(Canvas canvas, Size size) {
    final top = size.height * 0.04;
    final bottom = size.height * 0.96;
    final line = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final f in [guides.left, guides.right]) {
      canvas.drawLine(Offset(size.width * f, top), Offset(size.width * f, bottom), line);
    }
    final d = detection;
    if (d == null || d.aligned) return;
    final edge = Paint()
      ..color = Colors.amberAccent.withValues(alpha: 0.5)
      ..strokeWidth = 2;
    for (final f in [d.left, d.right]) {
      if (f != null) canvas.drawLine(Offset(size.width * f, size.height * 0.1), Offset(size.width * f, size.height * 0.9), edge);
    }
  }

  @override
  bool shouldRepaint(_GuidesPainter old) => old.color != color || old.detection != detection || old.guides != guides;
}
