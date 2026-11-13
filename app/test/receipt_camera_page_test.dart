import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:az_budget/app.dart';
import 'package:az_budget/budget/budget_service.dart';
import 'package:az_budget/l10n/app_localizations.dart';
import 'package:az_budget/ocr/engine_controller.dart';
import 'package:az_budget/storage/app_settings.dart';
import 'package:az_budget/ui/receipt_camera_page.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'budget_service_test.dart' show FakeFolder;

/// A camera that serves the frames a test pushes, in sensor orientation.
class FakeCamera extends CameraPlatform with MockPlatformInterfaceMixin {
  FakeCamera({this.cameras = const [CameraDescription(name: 'back', lensDirection: CameraLensDirection.back, sensorOrientation: 90)], this.denied = false});

  final List<CameraDescription> cameras;
  final bool denied;
  final frames = StreamController<CameraImageData>.broadcast();
  int pictures = 0;
  final focus = <math.Point<double>?>[];

  @override
  Future<List<CameraDescription>> availableCameras() async => cameras;
  @override
  Future<int> createCameraWithSettings(CameraDescription cameraDescription, MediaSettings mediaSettings) async {
    if (denied) throw CameraException('CameraAccessDenied', 'Camera access permission was denied.');
    return 1;
  }

  @override
  Future<void> initializeCamera(int cameraId, {ImageFormatGroup imageFormatGroup = ImageFormatGroup.unknown}) async {}
  @override
  Stream<CameraInitializedEvent> onCameraInitialized(int cameraId) => Stream.value(CameraInitializedEvent(cameraId, 1920, 1080, ExposureMode.auto, true, FocusMode.auto, true));
  // Silent streams (an empty one would make the controller's `.first` throw).
  @override
  Stream<CameraErrorEvent> onCameraError(int cameraId) => StreamController<CameraErrorEvent>().stream;
  @override
  Stream<DeviceOrientationChangedEvent> onDeviceOrientationChanged() => StreamController<DeviceOrientationChangedEvent>().stream;
  @override
  Future<void> lockCaptureOrientation(int cameraId, DeviceOrientation orientation) async {}
  @override
  Future<void> setFlashMode(int cameraId, FlashMode mode) async {}
  @override
  Future<void> setFocusPoint(int cameraId, math.Point<double>? point) async => focus.add(point);
  @override
  Future<void> setExposurePoint(int cameraId, math.Point<double>? point) async {}
  @override
  Widget buildPreview(int cameraId) => const ColoredBox(color: Colors.black);
  @override
  bool supportsImageStreaming() => true;
  @override
  Stream<CameraImageData> onStreamedFrameAvailable(int cameraId, {CameraImageStreamOptions? options}) => frames.stream;
  @override
  Future<XFile> takePicture(int cameraId) async {
    pictures++;
    return XFile('/cache/receipt_$pictures.jpg');
  }

  @override
  Future<void> dispose(int cameraId) async {}
}

/// A sensor frame (landscape, rotated 90° counter-clockwise from the
/// portrait the user sees): dark noisy table, receipt from [left] to [right].
CameraImageData frame({double left = 0.17, double right = 0.83, int seed = 1}) {
  const uw = 180, uh = 320; // upright
  final rnd = math.Random(seed);
  final px = Uint8List(uw * uh);
  for (var v = 0; v < uh; v++) {
    for (var u = 0; u < uw; u++) {
      final inside = u >= left * uw && u < right * uw && v > uh * 0.04 && v < uh * 0.96;
      final value = inside ? 215 - rnd.nextInt(10) : 70 + rnd.nextInt(30) - 15;
      // Sensor (x, y) of upright (u, v) for a 90° sensor: x = v, y = uw-1-u.
      px[(uw - 1 - u) * uh + v] = value;
    }
  }
  return CameraImageData(
    format: const CameraImageFormat(ImageFormatGroup.yuv420, raw: 35),
    width: uh,
    height: uw,
    planes: [CameraImagePlane(bytes: px, bytesPerRow: uh)],
  );
}

/// Let route transitions and pending futures finish. Not pumpAndSettle:
/// the page shows an endless spinner while the camera starts or saves.
/// The real event loop gets a turn in between: cancelling the frame stream
/// completes in the root zone, which the test's fake clock does not drive.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 300));
  }
}

void main() {
  late FakeCamera camera;
  late AppSettings settings;
  late BudgetService budget;
  late Directory tmp;
  var now = DateTime(2026, 11, 13, 12);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tmp = Directory.systemTemp.createTempSync('azcam');
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  /// Opens the camera from a button and returns how it ended.
  Future<CameraOutcome?> Function() open(WidgetTester tester) {
    CameraOutcome? outcome;
    var done = false;
    return () async {
      await tester.pumpWidget(
        AppScope(
          budget: budget,
          settings: settings,
          engine: EngineController(),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  outcome = await openReceiptCamera(context, page: ReceiptCameraPage(clock: () => now));
                  done = true;
                },
                child: const Text('scan'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('scan'));
      await tester.pump();
      await tester.pump();
      await tester.pump();
      return done ? outcome : null;
    };
  }

  Future<void> boot(WidgetTester tester, FakeCamera fake) async {
    camera = fake;
    CameraPlatform.instance = camera;
    settings = (await tester.runAsync(AppSettings.load))!;
    budget = BudgetService(folder: FakeFolder(File('test/fixtures/budget_small.xlsx').readAsBytesSync()), settings: settings, queueDir: tmp);
  }

  /// Push [n] frames, [stepMs] apart.
  Future<void> feed(WidgetTester tester, CameraImageData f, {int n = 1, int stepMs = 150}) async {
    for (var i = 0; i < n; i++) {
      now = now.add(Duration(milliseconds: stepMs));
      camera.frames.add(f);
      await tester.pump();
      await tester.pump();
    }
  }

  testWidgets('a receipt fully in view is photographed after 300 ms of holding still', (tester) async {
    await boot(tester, FakeCamera());
    final run = open(tester);
    await run();
    expect(find.byType(ReceiptCameraPage), findsOneWidget);
    expect(find.text('Put the receipt between the lines'), findsOneWidget);

    // Running off the left side: one edge only, no shot, the hint says what to do.
    await feed(tester, frame(left: 0.0, right: 0.75), n: 8);
    expect(camera.pictures, 0);
    expect(find.text('Move back a little'), findsOneWidget);

    // Whole receipt in view, smaller than the lines: framed, so it shoots.
    final framed = frame(left: 0.32, right: 0.68);
    // Frames 150 ms apart: the first after the change counts as motion, the
    // second starts the hold, the shot comes 300 ms (two frames) later.
    await feed(tester, framed, n: 3);
    expect(camera.pictures, 0, reason: 'still holding');
    expect(find.text('Hold still…'), findsOneWidget);
    await feed(tester, framed, n: 1);
    await settle(tester);
    expect(camera.pictures, 1);
    expect(find.byType(ReceiptCameraPage), findsNothing, reason: 'the page closed with the photo');
  });

  testWidgets('the outcome is the photo; the shutter works without the lines', (tester) async {
    await boot(tester, FakeCamera());
    CameraOutcome? outcome;
    await tester.pumpWidget(
      AppScope(
        budget: budget,
        settings: settings,
        engine: EngineController(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async => outcome = await openReceiptCamera(context, page: ReceiptCameraPage(clock: () => now)),
              child: const Text('scan'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('scan'));
    await settle(tester);
    // No receipt on the table: tap the shutter.
    await feed(tester, frame(left: 0.5, right: 0.5), n: 3);
    await tester.tap(find.byIcon(Icons.receipt_long));
    await settle(tester);
    expect(camera.pictures, 1);
    expect(outcome, isA<CameraShot>().having((s) => s.path, 'path', '/cache/receipt_1.jpg'));
  });

  testWidgets('auto-capture off: frames are ignored, the hint asks for the shutter', (tester) async {
    await boot(tester, FakeCamera());
    await tester.runAsync(() => settings.setAutoCapture(false));
    final run = open(tester);
    await run();
    await settle(tester);
    expect(find.text('Tap the shutter to take the photo'), findsOneWidget);
    expect(camera.frames.hasListener, isFalse, reason: 'no stream without auto-capture');
    // The toggle turns it on for this and later sessions.
    await tester.tap(find.byIcon(Icons.motion_photos_off_outlined));
    await settle(tester);
    expect(settings.autoCapture, isTrue);
    expect(camera.frames.hasListener, isTrue);
    await feed(tester, frame(), n: 8);
    await settle(tester);
    expect(camera.pictures, 1);
  });

  testWidgets('no camera or no permission: the page gives up so the camera app can be used', (tester) async {
    for (final fake in [FakeCamera(cameras: const []), FakeCamera(denied: true)]) {
      await boot(tester, fake);
      CameraOutcome? outcome;
      await tester.pumpWidget(
        AppScope(
          budget: budget,
          settings: settings,
          engine: EngineController(),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () async => outcome = await openReceiptCamera(context, page: ReceiptCameraPage(clock: () => now)),
                child: const Text('scan'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('scan'));
      await settle(tester);
      expect(outcome, isA<CameraUnavailable>(), reason: fake.denied ? 'denied' : 'no camera');
      if (fake.denied) expect((outcome as CameraUnavailable).reason, 'CameraAccessDenied');
      expect(find.byType(ReceiptCameraPage), findsNothing);
    }
  });

  testWidgets('a tap on the preview focuses there', (tester) async {
    await boot(tester, FakeCamera());
    final run = open(tester);
    await run();
    await settle(tester);
    await tester.tapAt(tester.getCenter(find.byType(CustomPaint).first));
    await tester.pump();
    expect(camera.focus, isNotEmpty);
  });
}
