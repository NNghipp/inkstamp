import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkstamp/features/camera/domain/repositories/camera_repository.dart';
import 'package:inkstamp/features/camera/domain/repositories/image_processing_repository.dart';
import 'package:inkstamp/features/camera/presentation/controllers/camera_controller.dart';
import 'package:inkstamp/features/stamps/presentation/controllers/stamp_composer_controller.dart';

void main() {
  test('duplicate initialization joins one hardware operation', () async {
    final camera = PendingInitializeCamera();
    final container = _container(camera);
    addTearDown(container.dispose);
    final controller = container.read(cameraControllerProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    final first = controller.initialize();
    final second = controller.initialize();
    camera.initialized.complete();
    await Future.wait([first, second]);
    expect(camera.initializeCount, 1);
  });
  test(
    'twenty activation cycles and old route release cannot suspend new owner',
    () async {
      final camera = FakeCameraRepository();
      final container = _container(camera);
      addTearDown(container.dispose);
      final controller = container.read(cameraControllerProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      for (var i = 0; i < 20; i++) {
        final old = controller.acquireSession();
        controller.releaseSession(old);
        controller.acquireSession();
        controller.releaseSession(old);
        await Future<void>.delayed(Duration.zero);
        await controller.initialize();
        expect(
          container.read(cameraControllerProvider).phase,
          CameraPhase.ready,
        );
      }
    },
  );
  test('initialization waits for a pending native disposal', () async {
    final camera = PendingDisposeCamera();
    final container = _container(camera);
    addTearDown(container.dispose);
    final controller = container.read(cameraControllerProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    final suspended = controller.suspend();
    final activated = controller.initialize();
    await Future<void>.delayed(Duration.zero);
    expect(camera.initializeCount, 1);
    expect(await controller.capture(), isFalse);
    camera.disposed.complete();
    await Future.wait([suspended, activated]);
    expect(camera.initializeCount, 2);
    expect(container.read(cameraControllerProvider).phase, CameraPhase.ready);
  });
  test(
    'stale initialization cannot restore preview after suspension',
    () async {
      final camera = PendingInitializeCamera();
      final container = _container(camera);
      addTearDown(container.dispose);
      final controller = container.read(cameraControllerProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      final suspended = controller.suspend();
      camera.initialized.complete();
      await suspended;
      expect(
        container.read(cameraControllerProvider).phase,
        CameraPhase.unavailable,
      );
      expect(container.read(cameraControllerProvider).previewHandle, isNull);
    },
  );

  test(
    'resume requested during initialization waits for stale session disposal',
    () async {
      final camera = PendingInitializeCamera();
      final container = _container(camera);
      addTearDown(container.dispose);
      final controller = container.read(cameraControllerProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      final suspended = controller.onLifecycleChanged(AppLifecycleState.paused);
      final resumed = controller.onLifecycleChanged(AppLifecycleState.resumed);
      camera.initialized.complete();
      await Future.wait([suspended, resumed]);
      expect(camera.initializeCount, 2);
      expect(container.read(cameraControllerProvider).phase, CameraPhase.ready);
    },
  );

  test(
    'background during capture cancels draft and cleans its raw file',
    () async {
      final camera = PendingCaptureCamera();
      final processor = FakeImageProcessor();
      final container = _container(camera, processor);
      addTearDown(container.dispose);
      final controller = container.read(cameraControllerProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      final capture = controller.capture();
      await Future<void>.delayed(Duration.zero);
      final paused = controller.onLifecycleChanged(AppLifecycleState.paused);
      camera.result.complete('cancelled-raw.jpg');
      expect(await capture, isFalse);
      await paused;
      expect(
        container.read(stampComposerControllerProvider).localImagePath,
        isNull,
      );
      expect(processor.deletedPaths, contains('cancelled-raw.jpg'));
    },
  );

  testWidgets('suspend detaches preview before disposing native camera', (
    tester,
  ) async {
    final camera = FakeCameraRepository();
    final container = _container(camera);
    addTearDown(container.dispose);
    container.read(cameraControllerProvider);
    await tester.pump();
    expect(container.read(cameraControllerProvider).previewHandle, isNotNull);
    final suspension = container
        .read(cameraControllerProvider.notifier)
        .suspend(waitForPreviewFrame: true);
    expect(container.read(cameraControllerProvider).previewHandle, isNull);
    expect(camera.disposeCount, 0);
    await tester.pump();
    await suspension;
    expect(camera.disposeCount, 1);
  });
  test('duplicate capture is rejected while hardware is processing', () async {
    final camera = PendingCaptureCamera();
    final container = _container(camera);
    addTearDown(container.dispose);
    container.read(cameraControllerProvider);
    await Future<void>.delayed(Duration.zero);
    final controller = container.read(cameraControllerProvider.notifier);
    final capture = controller.capture();
    expect(await controller.capture(), isFalse);
    expect(camera.captureCount, 1);
    camera.result.complete('raw.jpg');
    expect(await capture, isTrue);
  });
  test('initializes, switches lens and toggles flash', () async {
    final FakeCameraRepository camera = FakeCameraRepository();
    final ProviderContainer container = _container(camera);
    addTearDown(container.dispose);

    container.read(cameraControllerProvider);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(cameraControllerProvider).phase, CameraPhase.ready);

    final InkstampCameraController controller = container.read(
      cameraControllerProvider.notifier,
    );
    await controller.toggleFlash();
    await controller.switchLens();

    expect(container.read(cameraControllerProvider).flashEnabled, isFalse);
    expect(container.read(cameraControllerProvider).lens, CameraLens.front);
  });

  test(
    'capture stores only processed image paths in the stamp draft',
    () async {
      final FakeCameraRepository camera = FakeCameraRepository();
      final FakeImageProcessor processor = FakeImageProcessor();
      final ProviderContainer container = _container(camera, processor);
      addTearDown(container.dispose);
      container.read(cameraControllerProvider);
      await Future<void>.delayed(Duration.zero);

      expect(
        await container.read(cameraControllerProvider.notifier).capture(),
        isTrue,
      );
      final draft = container.read(stampComposerControllerProvider);
      expect(draft.localImagePath, 'processed-1440.jpg');
      expect(draft.localThumbnailPath, 'processed-512.jpg');
      expect(processor.processedRawPath, 'raw-camera.jpg');
    },
  );

  test('permission denial has a retryable explicit state', () async {
    final ProviderContainer container = _container(
      FakeCameraRepository(
        initializeError: const CameraRepositoryException(
          'CameraAccessDenied',
          'denied',
        ),
      ),
    );
    addTearDown(container.dispose);
    container.read(cameraControllerProvider);
    await Future<void>.delayed(Duration.zero);

    final CameraControllerState state = container.read(
      cameraControllerProvider,
    );
    expect(state.phase, CameraPhase.permissionDenied);
    expect(state.errorMessage, contains('permission'));
  });

  test('pause disposes and resume initializes the camera again', () async {
    final FakeCameraRepository camera = FakeCameraRepository();
    final ProviderContainer container = _container(camera);
    addTearDown(container.dispose);
    container.read(cameraControllerProvider);
    await Future<void>.delayed(Duration.zero);
    final InkstampCameraController controller = container.read(
      cameraControllerProvider.notifier,
    );

    await controller.onLifecycleChanged(AppLifecycleState.paused);
    await controller.onLifecycleChanged(AppLifecycleState.resumed);

    expect(camera.disposeCount, 1);
    expect(camera.initializeCount, 2);
    expect(container.read(cameraControllerProvider).phase, CameraPhase.ready);
  });

  test('retake deletes both processed files and clears the draft', () async {
    final FakeCameraRepository camera = FakeCameraRepository();
    final FakeImageProcessor processor = FakeImageProcessor();
    final ProviderContainer container = _container(camera, processor);
    addTearDown(container.dispose);
    container
        .read(stampComposerControllerProvider.notifier)
        .capture(
          localImagePath: 'old-1440.jpg',
          localThumbnailPath: 'old-512.jpg',
        );

    await container
        .read(cameraControllerProvider.notifier)
        .discardDraftFiles(container.read(stampComposerControllerProvider));

    expect(
      processor.deletedPaths,
      containsAll(<String>['old-1440.jpg', 'old-512.jpg']),
    );
    expect(
      container.read(stampComposerControllerProvider).localImagePath,
      isNull,
    );
    expect(
      container.read(stampComposerControllerProvider).localThumbnailPath,
      isNull,
    );
  });
}

class PendingCaptureCamera extends FakeCameraRepository {
  final result = Completer<String>();
  int captureCount = 0;
  @override
  Future<String> captureRawImage() {
    captureCount++;
    return result.future;
  }
}

class PendingInitializeCamera extends FakeCameraRepository {
  final initialized = Completer<void>();
  @override
  Future<void> initialize({CameraLens preferredLens = CameraLens.back}) async {
    initializeCount++;
    await initialized.future;
  }
}

class PendingDisposeCamera extends FakeCameraRepository {
  final disposed = Completer<void>();
  @override
  Future<void> dispose() async {
    disposeCount++;
    await disposed.future;
  }
}

ProviderContainer _container(
  FakeCameraRepository camera, [
  FakeImageProcessor? processor,
]) {
  return ProviderContainer(
    overrides: [
      cameraRepositoryProvider.overrideWithValue(camera),
      imageProcessingRepositoryProvider.overrideWithValue(
        processor ?? FakeImageProcessor(),
      ),
    ],
  );
}

class FakeCameraRepository implements CameraRepository {
  FakeCameraRepository({this.initializeError});

  final CameraRepositoryException? initializeError;
  int initializeCount = 0;
  int disposeCount = 0;
  @override
  CameraLens lens = CameraLens.back;
  @override
  bool flashEnabled = false;

  @override
  Object? get previewHandle => 'preview';

  @override
  Future<void> initialize({CameraLens preferredLens = CameraLens.back}) async {
    initializeCount += 1;
    if (initializeError != null) throw initializeError!;
    lens = preferredLens;
    flashEnabled = false;
  }

  @override
  Future<void> switchLens() async {
    lens = lens == CameraLens.back ? CameraLens.front : CameraLens.back;
    flashEnabled = false;
  }

  @override
  Future<void> setFlashEnabled(bool enabled) async {
    flashEnabled = enabled;
  }

  @override
  Future<String> captureRawImage() async => 'raw-camera.jpg';

  @override
  Future<void> dispose() async {
    disposeCount += 1;
  }
}

class FakeImageProcessor implements ImageProcessingRepository {
  String? processedRawPath;
  final List<String> deletedPaths = <String>[];

  @override
  Future<ProcessedCameraImage> process(String rawImagePath) async {
    processedRawPath = rawImagePath;
    return const ProcessedCameraImage(
      imagePath: 'processed-1440.jpg',
      thumbnailPath: 'processed-512.jpg',
    );
  }

  @override
  Future<void> deleteFiles(Iterable<String?> paths) async {
    deletedPaths.addAll(paths.whereType<String>());
  }

  @override
  Future<int> cleanupExpiredDrafts({
    Duration maximumAge = const Duration(hours: 24),
  }) async => 0;
}
