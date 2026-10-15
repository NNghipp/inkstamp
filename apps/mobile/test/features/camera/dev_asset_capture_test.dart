import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as image;
import 'package:inkstamp/features/camera/data/repositories/dev_asset_capture_source.dart';
import 'package:inkstamp/features/camera/data/repositories/local_image_processing_repository.dart';
import 'package:inkstamp/features/camera/presentation/controllers/camera_controller.dart';
import 'package:inkstamp/features/camera/presentation/screens/camera_screen.dart';
import 'package:inkstamp/features/stamps/presentation/controllers/stamp_composer_controller.dart';

import 'camera_controller_test.dart'
    show FakeCameraRepository, FakeImageProcessor;
import 'camera_screen_test.dart' show NoopImageProcessor;

class MemoryAssetBundle extends CachingAssetBundle {
  MemoryAssetBundle(this.images);
  final Map<String, Uint8List> images;
  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.bin') {
      return const StandardMessageCodec().encodeMessage({
        for (final key in images.keys)
          key: [
            {'asset': key},
          ],
      })!;
    }
    final bytes = images[key];
    if (bytes == null) throw StateError('Missing test asset');
    return ByteData.sublistView(bytes);
  }
}

// Widget navigation uses synchronous fixtures; filesystem + real processing
// are exercised independently below without the widget fake-async clock.
class WidgetCaptureSource extends DevAssetCaptureSource {
  WidgetCaptureSource()
    : super(
        bundle: MemoryAssetBundle({
          'assets/image_test/personal.jpg': Uint8List.fromList([1]),
        }),
      );
  @override
  Future<String> captureRawImage(String asset) async => 'sample-raw.jpg';
}

class PendingCaptureSource extends WidgetCaptureSource {
  final result = Completer<String>();
  int captures = 0;
  @override
  Future<String> captureRawImage(String asset) {
    captures++;
    return result.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'optional sample metadata uses today and never blocks unknown photos',
    () async {
      final source = DevAssetCaptureSource(
        bundle: MemoryAssetBundle({
          '${DevAssetCaptureSource.prefix}demo_metadata.json':
              Uint8List.fromList(
                utf8.encode(
                  jsonEncode({
                    'known.jpg': {
                      'title': '  Buổi sáng  ',
                      'locationLabel': 'Kyoto',
                      'time': '09:05',
                    },
                    'invalid.jpg': {
                      'title': '',
                      'locationLabel': 123,
                      'time': '25:80',
                    },
                  }),
                ),
              ),
        }),
      );
      final before = DateTime.now();
      final known = await source.metadata(
        '${DevAssetCaptureSource.prefix}known.jpg',
      );
      expect(known.title, devAssetCaptureEnabled ? 'Buổi sáng' : null);
      expect(known.locationLabel, devAssetCaptureEnabled ? 'Kyoto' : null);
      if (devAssetCaptureEnabled) {
        expect(
          known.capturedAt,
          DateTime(before.year, before.month, before.day, 9, 5),
        );
      }
      for (final asset in ['unknown.jpg', 'invalid.jpg']) {
        final result = await source.metadata(
          '${DevAssetCaptureSource.prefix}$asset',
        );
        expect(result.title, isNull);
        expect(result.locationLabel, isNull);
        expect(result.capturedAt.isBefore(before), isFalse);
      }
      final missing = await DevAssetCaptureSource(
        bundle: MemoryAssetBundle({}),
      ).metadata('${DevAssetCaptureSource.prefix}new.jpg');
      expect(missing.title, isNull);
      expect(await source.listImages(), isEmpty);
    },
  );
  test('supported formats come from the existing image decoder', () {
    expect(
      DevAssetCaptureSource.supportedAssets([
        'assets/image_test/b.PNG',
        'assets/image_test/a.jpeg',
        'assets/image_test/c.webp',
        'assets/image_test/d.gif',
        'assets/image_test/e.bmp',
        'assets/image_test/f.tiff',
        'assets/image_test/README.md',
        'assets/image_test/no.heic',
        'assets/design/photo.jpg',
        'assets/image_test/nested/photo.jpg',
      ]),
      [
        'assets/image_test/a.jpeg',
        'assets/image_test/b.PNG',
        'assets/image_test/c.webp',
        'assets/image_test/d.gif',
        'assets/image_test/e.bmp',
        'assets/image_test/f.tiff',
      ],
    );
  });

  test('empty folder and disabled configuration return no images', () async {
    final source = DevAssetCaptureSource(bundle: MemoryAssetBundle({}));
    expect(await source.listImages(), isEmpty);
    await expectLater(
      source.captureRawImage('assets/image_test/missing.jpg'),
      throwsA(isA<Exception>()),
    );
  });

  testWidgets('sample control respects build guard and design-only renders', (
    tester,
  ) async {
    Future<void> pump(bool initialize) => tester.pumpWidget(
      ProviderScope(
        overrides: [
          cameraRepositoryProvider.overrideWithValue(FakeCameraRepository()),
          imageProcessingRepositoryProvider.overrideWithValue(
            NoopImageProcessor(),
          ),
          devAssetCaptureSourceProvider.overrideWithValue(
            DevAssetCaptureSource(bundle: MemoryAssetBundle({})),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(body: CameraScreen(initializeCamera: initialize)),
        ),
      ),
    );
    await pump(true);
    await tester.pumpAndSettle();
    expect(
      find.byTooltip('DEV sample capture'),
      devAssetCaptureEnabled ? findsOneWidget : findsNothing,
    );
    if (devAssetCaptureEnabled) {
      await tester.tap(find.byTooltip('DEV sample capture'));
      await tester.pumpAndSettle();
      expect(
        find.text('No supported images in assets/image_test/.'),
        findsOneWidget,
      );
    }
    await tester.pumpWidget(const SizedBox());
    await pump(false);
    await tester.pumpAndSettle();
    expect(find.byTooltip('DEV sample capture'), findsNothing);
  });

  test(
    'asset capture is rejected outside debug DEV even with source override',
    () async {
      final container = ProviderContainer(
        overrides: [
          cameraRepositoryProvider.overrideWithValue(FakeCameraRepository()),
          imageProcessingRepositoryProvider.overrideWithValue(
            NoopImageProcessor(),
          ),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(cameraControllerProvider.notifier);
      await controller.initialize();
      expect(
        await controller.captureDevAsset('assets/image_test/photo.jpg'),
        isFalse,
      );
      expect(container.read(cameraControllerProvider).phase, CameraPhase.ready);
    },
    skip: devAssetCaptureEnabled,
  );

  if (devAssetCaptureEnabled) {
    test(
      'duplicate sample capture and stale completion after suspension are guarded',
      () async {
        final source = PendingCaptureSource();
        final processor = FakeImageProcessor();
        final container = ProviderContainer(
          overrides: [
            cameraRepositoryProvider.overrideWithValue(FakeCameraRepository()),
            imageProcessingRepositoryProvider.overrideWithValue(processor),
            devAssetCaptureSourceProvider.overrideWithValue(source),
          ],
        );
        addTearDown(container.dispose);
        final controller = container.read(cameraControllerProvider.notifier);
        await controller.initialize();
        final first = controller.captureDevAsset(
          'assets/image_test/personal.jpg',
        );
        expect(
          await controller.captureDevAsset('assets/image_test/personal.jpg'),
          isFalse,
        );
        final suspension = controller.suspend();
        source.result.complete('stale-sample.jpg');
        expect(await first, isFalse);
        await suspension;
        expect(source.captures, 1);
        expect(processor.deletedPaths, contains('stale-sample.jpg'));
        expect(processor.processedRawPath, isNull);
        expect(
          container.read(stampComposerControllerProvider).localImagePath,
          isNull,
        );
        await controller.initialize();
        expect(
          container.read(cameraControllerProvider).phase,
          CameraPhase.ready,
        );
      },
    );

    test(
      'registered manifest discovers folder files without a filename list',
      () async {
        final expected = DevAssetCaptureSource.supportedAssets(
          Directory('assets/image_test').listSync().whereType<File>().map(
            (file) => 'assets/image_test/${file.uri.pathSegments.last}',
          ),
        );
        expect(await DevAssetCaptureSource().listImages(), expected);
      },
    );

    testWidgets(
      'picker selects static preview; only shutter captures; real camera returns',
      (tester) async {
        final camera = FakeCameraRepository();
        final processor = FakeImageProcessor();
        final container = ProviderContainer(
          overrides: [
            cameraRepositoryProvider.overrideWithValue(camera),
            imageProcessingRepositoryProvider.overrideWithValue(processor),
            devAssetCaptureSourceProvider.overrideWithValue(
              WidgetCaptureSource(),
            ),
          ],
        );
        final router = GoRouter(
          initialLocation: '/camera',
          routes: [
            GoRoute(
              path: '/camera',
              builder: (_, _) => const Scaffold(body: CameraScreen()),
              routes: [
                GoRoute(
                  path: 'preview',
                  builder: (_, _) =>
                      const Scaffold(body: Text('Preview route')),
                ),
              ],
            ),
          ],
        );
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('DEV sample capture'));
        await tester.pumpAndSettle();
        expect(find.text('personal.jpg'), findsOneWidget);
        Navigator.of(tester.element(find.text('personal.jpg'))).pop();
        await tester.pumpAndSettle();
        expect(
          container.read(stampComposerControllerProvider).localImagePath,
          isNull,
        );
        await tester.tap(find.byTooltip('DEV sample capture'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('personal.jpg'));
        await tester.pump();
        await tester.pumpAndSettle();
        expect(find.text('Preview route'), findsNothing);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        await tester.pumpAndSettle();
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('dev-camera-static-preview')),
          findsOneWidget,
        );
        expect(
          container.read(stampComposerControllerProvider).localImagePath,
          isNull,
        );
        await tester.tap(find.byTooltip('DEV sample capture'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Camera thật'));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('dev-camera-static-preview')),
          findsNothing,
        );
        await tester.tap(find.byTooltip('DEV sample capture'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('personal.jpg'));
        await tester.pumpAndSettle();
        await tester.tap(find.bySemanticsLabel('Chụp ảnh'));
        await tester.pumpAndSettle();
        expect(find.text('Preview route'), findsOneWidget);
        expect(
          container.read(stampComposerControllerProvider).localImagePath,
          'processed-1440.jpg',
        );
        router.pop();
        await tester.pumpAndSettle();
        expect(
          container.read(cameraControllerProvider).phase,
          CameraPhase.ready,
        );
        expect(container.read(cameraRepositoryProvider), same(camera));
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
        router.dispose();
        container.dispose();
      },
    );

    for (final format in ['jpg', 'png']) {
      test(
        '$format asset follows real processing and shared draft handoff',
        () async {
          final directory = await Directory.systemTemp.createTemp(
            'inkstamp_dev_asset_test_',
          );
          addTearDown(() => directory.delete(recursive: true));
          final original = image.Image(width: 80, height: 120)
            ..exif.imageIfd.orientation = 6
            ..exif.imageIfd.make = 'Private model'
            ..textData = {'private': 'metadata'};
          image.fill(original, color: image.ColorRgb8(240, 60, 40));
          final bytes = format == 'jpg'
              ? image.encodeJpg(original)
              : image.encodePng(original);
          final key = 'assets/image_test/photo.$format';
          final source = DevAssetCaptureSource(
            bundle: MemoryAssetBundle({key: bytes}),
            temporaryDirectoryProvider: () async => directory,
          );
          final camera = FakeCameraRepository();
          final container = ProviderContainer(
            overrides: [
              cameraRepositoryProvider.overrideWithValue(camera),
              imageProcessingRepositoryProvider.overrideWithValue(
                LocalImageProcessingRepository(
                  temporaryDirectoryProvider: () async => directory,
                ),
              ),
              devAssetCaptureSourceProvider.overrideWithValue(source),
            ],
          );
          final controller = container.read(cameraControllerProvider.notifier);
          await controller.initialize();
          container
              .read(stampComposerControllerProvider.notifier)
              .beginCapture(replyToStampId: 'reply');
          expect(await source.listImages(), [key]);
          expect(await controller.captureDevAsset(key), isTrue);
          final draft = container.read(stampComposerControllerProvider);
          final full = image.decodePng(
            await File(draft.localImagePath!).readAsBytes(),
          )!;
          final thumb = image.decodePng(
            await File(draft.localThumbnailPath!).readAsBytes(),
          )!;
          expect((full.width, full.height), (1440, 1440));
          expect((thumb.width, thumb.height), (512, 512));
          expect(full.getPixel(0, 0).a, 0);
          expect(thumb.getPixel(0, 0).a, 0);
          expect(full.getPixel(720, 720).a, 255);
          expect(thumb.getPixel(256, 256).a, 255);
          expect(full.exif.isEmpty, isTrue);
          expect(thumb.exif.isEmpty, isTrue);
          expect(full.textData, isNull);
          expect(draft.replyToStampId, 'reply');
          expect(directory.listSync().length, 2); // Raw copy removed.
          expect(container.read(cameraRepositoryProvider), same(camera));
          expect(
            container.read(cameraControllerProvider).phase,
            CameraPhase.ready,
          );
          await controller.discardDraftFiles(draft);
          expect(directory.listSync(), isEmpty);
          expect(await source.listImages(), [key]); // Asset never deleted.
          await expectLater(
            source.captureRawImage('assets/design/photo.jpg'),
            throwsA(isA<Exception>()),
          );
          container.dispose();
        },
      );
    }

    test('corrupt sample is rejected and its raw copy is cleaned', () async {
      final directory = await Directory.systemTemp.createTemp(
        'inkstamp_dev_bad_test_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final source = DevAssetCaptureSource(
        bundle: MemoryAssetBundle({
          'assets/image_test/bad.jpg': Uint8List.fromList([1, 2, 3]),
        }),
        temporaryDirectoryProvider: () async => directory,
      );
      final container = ProviderContainer(
        overrides: [
          cameraRepositoryProvider.overrideWithValue(FakeCameraRepository()),
          imageProcessingRepositoryProvider.overrideWithValue(
            LocalImageProcessingRepository(
              temporaryDirectoryProvider: () async => directory,
            ),
          ),
          devAssetCaptureSourceProvider.overrideWithValue(source),
        ],
      );
      final controller = container.read(cameraControllerProvider.notifier);
      await controller.initialize();
      expect(
        await controller.captureDevAsset('assets/image_test/bad.jpg'),
        isFalse,
      );
      expect(directory.listSync(), isEmpty);
      expect(
        container.read(stampComposerControllerProvider).localImagePath,
        isNull,
      );
      await controller.initialize();
      expect(container.read(cameraControllerProvider).phase, CameraPhase.ready);
      container.dispose();
    });
  }
}
