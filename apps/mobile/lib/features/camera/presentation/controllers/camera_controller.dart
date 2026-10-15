import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkstamp/core/async/serial_executor.dart';
import 'package:inkstamp/core/observability/safe_error_reporter.dart';
import 'package:inkstamp/features/camera/data/repositories/camera_plugin_repository.dart';
import 'package:inkstamp/features/camera/data/repositories/dev_asset_capture_source.dart';
import 'package:inkstamp/features/camera/data/repositories/local_image_processing_repository.dart';
import 'package:inkstamp/features/camera/domain/repositories/camera_repository.dart';
import 'package:inkstamp/features/camera/domain/repositories/image_processing_repository.dart';
import 'package:inkstamp/features/stamps/domain/entities/stamp_draft.dart';
import 'package:inkstamp/features/stamps/presentation/controllers/stamp_composer_controller.dart';

enum CameraPhase {
  initializing,
  ready,
  capturing,
  processing,
  permissionDenied,
  unavailable,
  error,
}

class CameraControllerState {
  const CameraControllerState({
    this.phase = CameraPhase.initializing,
    this.lens = CameraLens.back,
    this.flashEnabled = false,
    this.previewHandle,
    this.errorMessage,
  });

  final CameraPhase phase;
  final CameraLens lens;
  final bool flashEnabled;
  final Object? previewHandle;
  final String? errorMessage;

  bool get isBusy =>
      phase == CameraPhase.initializing ||
      phase == CameraPhase.capturing ||
      phase == CameraPhase.processing;

  CameraControllerState copyWith({
    CameraPhase? phase,
    CameraLens? lens,
    bool? flashEnabled,
    Object? previewHandle,
    bool clearPreview = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CameraControllerState(
      phase: phase ?? this.phase,
      lens: lens ?? this.lens,
      flashEnabled: flashEnabled ?? this.flashEnabled,
      previewHandle: clearPreview ? null : previewHandle ?? this.previewHandle,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

final Provider<CameraRepository> cameraRepositoryProvider =
    Provider<CameraRepository>((Ref ref) => CameraPluginRepository());

final Provider<ImageProcessingRepository> imageProcessingRepositoryProvider =
    Provider<ImageProcessingRepository>(
      (Ref ref) => LocalImageProcessingRepository(),
    );

final NotifierProvider<InkstampCameraController, CameraControllerState>
cameraControllerProvider =
    NotifierProvider<InkstampCameraController, CameraControllerState>(
      InkstampCameraController.new,
    );

class InkstampCameraController extends Notifier<CameraControllerState> {
  final _operations = SerialExecutor();
  int _generation = 0;
  int _owner = 0;
  bool _active = true;
  bool _foreground = true;
  Future<void>? _initialization;
  bool _changingFlash = false;
  CameraRepository get _camera => ref.read(cameraRepositoryProvider);
  ImageProcessingRepository get _processor =>
      ref.read(imageProcessingRepositoryProvider);

  @override
  CameraControllerState build() {
    final CameraRepository camera = _camera;
    final ImageProcessingRepository processor = _processor;
    ref.onDispose(() {
      _active = false;
      _generation++;
      _operations.run(camera.dispose).catchError((
        Object error,
        StackTrace stack,
      ) {
        SafeErrorReporter().report(ErrorEvent.cameraCleanup, error, stack);
      });
    });
    final generation = _generation;
    Future<void>.microtask(() async {
      try {
        await processor.cleanupExpiredDrafts();
      } on Object catch (error, stack) {
        // Cleanup must not prevent the user from opening the camera.
        SafeErrorReporter().report(ErrorEvent.draftCleanup, error, stack);
      }
      if (!_current(generation)) return;
      await initialize();
    });
    return const CameraControllerState();
  }

  // A route owns its lease. An old route's delayed unmount cannot suspend a new one.
  int acquireSession() {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    final owner = ++_owner;
    Future<void>.microtask(() async {
      if (ref.mounted && owner == _owner) await initialize();
    });
    return owner;
  }

  void releaseSession(int owner) {
    if (owner != _owner) return;
    _active = false;
    final generation = ++_generation;
    _initialization = null;
    Future<void>.microtask(() async {
      if (!ref.mounted || generation != _generation) return;
      await suspend();
    });
  }

  bool _current(int generation) =>
      ref.mounted && _active && _foreground && generation == _generation;

  Future<void> initialize() {
    if (!ref.mounted || !_foreground) return Future<void>.value();
    if (_active && _initialization != null) return _initialization!;
    if (_active && state.phase == CameraPhase.ready) {
      return Future<void>.value();
    }
    _active = true;
    final generation = ++_generation;
    state = state.copyWith(
      phase: CameraPhase.initializing,
      clearPreview: true,
      clearError: true,
    );
    final operation = _operations.run(() async {
      if (!_current(generation)) return;
      try {
        await _camera.initialize(preferredLens: state.lens);
        if (!_current(generation)) return;
        state = CameraControllerState(
          phase: CameraPhase.ready,
          lens: _camera.lens,
          flashEnabled: _camera.flashEnabled,
          previewHandle: _camera.previewHandle,
        );
      } on CameraRepositoryException catch (error) {
        if (_current(generation)) _setCameraError(error);
      } on Object {
        if (!_current(generation)) return;
        state = state.copyWith(
          phase: CameraPhase.error,
          clearPreview: true,
          errorMessage: 'Unable to start the camera. Please try again.',
        );
      } finally {
        if (generation == _generation) _initialization = null;
      }
    });
    _initialization = operation;
    return operation;
  }

  Future<void> onLifecycleChanged(AppLifecycleState lifecycle) async {
    if (lifecycle == AppLifecycleState.resumed) {
      _foreground = true;
      if (_active && state.phase != CameraPhase.ready) await initialize();
      return;
    }
    if (lifecycle == AppLifecycleState.inactive ||
        lifecycle == AppLifecycleState.paused ||
        lifecycle == AppLifecycleState.detached ||
        lifecycle == AppLifecycleState.hidden) {
      _foreground = false;
      await suspend(deactivate: false);
    }
  }

  Future<void> switchLens() async {
    if (state.isBusy || state.phase != CameraPhase.ready) return;
    state = state.copyWith(
      phase: CameraPhase.initializing,
      clearError: true,
      clearPreview: true,
    );
    final generation = _generation;
    await _operations.run(() async {
      if (!_current(generation)) return;
      try {
        await _camera.switchLens();
        if (!_current(generation)) return;
        state = CameraControllerState(
          phase: CameraPhase.ready,
          lens: _camera.lens,
          flashEnabled: _camera.flashEnabled,
          previewHandle: _camera.previewHandle,
        );
      } on CameraRepositoryException catch (error) {
        if (_current(generation)) _setCameraError(error);
      } on Object {
        if (_current(generation)) {
          _setCameraError(
            const CameraRepositoryException(
              'switch-failed',
              'Unable to switch camera. Please try again.',
            ),
          );
        }
      }
    });
  }

  Future<void> toggleFlash() async {
    if (_changingFlash || state.isBusy || state.phase != CameraPhase.ready) {
      return;
    }
    _changingFlash = true;
    final generation = _generation;
    try {
      await _operations.run(() async {
        if (_current(generation)) {
          await _camera.setFlashEnabled(!state.flashEnabled);
        }
      });
      if (!_current(generation)) return;
      state = state.copyWith(flashEnabled: _camera.flashEnabled);
    } on CameraRepositoryException {
      if (_current(generation)) {
        state = state.copyWith(
          errorMessage: 'Unable to change flash. Please try again.',
        );
      }
    } finally {
      _changingFlash = false;
    }
  }

  Future<bool> focusAt(Offset point) async {
    final camera = _camera;
    if (state.phase != CameraPhase.ready || camera is! FocusCameraRepository) {
      return false;
    }
    try {
      final generation = _generation;
      return await _operations.run(() async {
        if (!_current(generation)) return false;
        await (camera as FocusCameraRepository).focusAt(point);
        return _current(generation);
      });
    } on CameraRepositoryException {
      return false; // Hardware may not support a focus point (e.g. front lens).
    }
  }

  Future<bool> capture() async {
    if (state.isBusy || state.phase != CameraPhase.ready) return false;
    return _captureFrom(_camera.captureRawImage);
  }

  Future<bool> captureDevAsset(String asset) async {
    if (!devAssetCaptureEnabled || state.isBusy) return false;
    return _captureFrom(
      () => ref.read(devAssetCaptureSourceProvider).captureRawImage(asset),
      sampleAsset: asset,
    );
  }

  // Hardware and DEV assets share processing, lifecycle guards and draft handoff.
  Future<bool> _captureFrom(
    Future<String> Function() captureRawImage, {
    String? sampleAsset,
  }) async {
    final generation = _generation;
    state = state.copyWith(phase: CameraPhase.capturing, clearError: true);
    return _operations.run(() async {
      if (!_current(generation)) return false;
      String? rawPath;
      try {
        final capturedAt = DateTime.now();
        final metadata = sampleAsset == null
            ? null
            : await ref
                  .read(devAssetCaptureSourceProvider)
                  .metadata(sampleAsset);
        rawPath = await captureRawImage();
        if (!_current(generation)) {
          await _processor.deleteFiles([rawPath]);
          return false;
        }
        state = state.copyWith(phase: CameraPhase.processing);
        final ProcessedCameraImage processed = await _processor.process(
          rawPath,
        );
        if (!_current(generation)) {
          await _processor.deleteFiles(<String?>[
            processed.imagePath,
            processed.thumbnailPath,
          ]);
          return false;
        }
        final StampDraft previousDraft = ref.read(
          stampComposerControllerProvider,
        );
        await _processor.deleteFiles(<String?>[
          previousDraft.localImagePath,
          previousDraft.localThumbnailPath,
        ]);
        if (!_current(generation)) {
          await _processor.deleteFiles([
            processed.imagePath,
            processed.thumbnailPath,
          ]);
          return false;
        }
        ref
            .read(stampComposerControllerProvider.notifier)
            .capture(
              replyToStampId: previousDraft.replyToStampId,
              localImagePath: processed.imagePath,
              localThumbnailPath: processed.thumbnailPath,
              capturedAt: metadata?.capturedAt ?? capturedAt,
              title: metadata?.title,
              locationLabel: metadata?.locationLabel,
            );
        state = state.copyWith(phase: CameraPhase.ready);
        return true;
      } on CameraRepositoryException catch (error) {
        if (_current(generation)) _setCameraError(error);
        return false;
      } on ImageProcessingException catch (error) {
        if (!_current(generation)) return false;
        state = state.copyWith(
          phase: CameraPhase.error,
          errorMessage: error.message,
        );
        return false;
      } on Object {
        if (rawPath != null) await _processor.deleteFiles(<String?>[rawPath]);
        if (!_current(generation)) return false;
        state = state.copyWith(
          phase: CameraPhase.error,
          errorMessage: 'Unable to capture this photo. Please try again.',
        );
        return false;
      }
    });
  }

  Future<void> prepareCapture({String? replyToStampId}) async {
    final StampDraft draft = ref.read(stampComposerControllerProvider);
    await _processor.deleteFiles(<String?>[
      draft.localImagePath,
      draft.localThumbnailPath,
    ]);
    ref
        .read(stampComposerControllerProvider.notifier)
        .beginCapture(replyToStampId: replyToStampId);
  }

  Future<void> discardDraftFiles(StampDraft draft) async {
    await _processor.deleteFiles(<String?>[
      draft.localImagePath,
      draft.localThumbnailPath,
    ]);
    ref.read(stampComposerControllerProvider.notifier).clearCapturedFiles();
  }

  Future<void> finishDraft(StampDraft draft) async {
    await _processor.deleteFiles(<String?>[
      draft.localImagePath,
      draft.localThumbnailPath,
    ]);
    ref.read(stampComposerControllerProvider.notifier).reset();
  }

  Future<void> suspend({
    bool waitForPreviewFrame = false,
    bool deactivate = true,
  }) async {
    if (!ref.mounted) return;
    if (deactivate) _active = false;
    ++_generation;
    _initialization = null;
    state = state.copyWith(
      phase: CameraPhase.unavailable,
      clearPreview: true,
      clearError: true,
    );
    // Remove CameraPreview from the mounted tree before its native handle dies.
    // Route transitions can otherwise rebuild its queued ValueListenableBuilder.
    // Reserve the queue position before awaiting the frame: a later activation
    // must never initialize a handle that this suspension then disposes.
    final previewFrame = waitForPreviewFrame
        ? WidgetsBinding.instance.endOfFrame
        : Future<void>.value();
    await _operations.run(() async {
      await previewFrame;
      await _camera.dispose();
    });
  }

  void _setCameraError(CameraRepositoryException error) {
    if (!ref.mounted) return;
    const Set<String> permissionCodes = <String>{
      'CameraAccessDenied',
      'CameraAccessDeniedWithoutPrompt',
      'CameraAccessRestricted',
    };
    final bool permissionDenied = permissionCodes.contains(error.code);
    state = state.copyWith(
      phase: permissionDenied
          ? CameraPhase.permissionDenied
          : error.code == 'unavailable'
          ? CameraPhase.unavailable
          : CameraPhase.error,
      clearPreview: true,
      errorMessage: permissionDenied
          ? 'Camera permission is required to create a stamp.'
          : 'Unable to use the camera. Please try again.',
    );
  }
}
