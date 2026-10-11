import 'dart:ui';
import 'package:camera/camera.dart' as camera;
import 'package:inkstamp/core/async/serial_executor.dart';
import 'package:inkstamp/features/camera/domain/repositories/camera_repository.dart';

class CameraPluginRepository
    implements CameraRepository, FocusCameraRepository {
  camera.CameraController? _controller;
  List<camera.CameraDescription>? _cameras;
  CameraLens _lens = CameraLens.back;
  bool _flashEnabled = false;
  final _operations = SerialExecutor();

  @override
  Object? get previewHandle => _controller;

  @override
  CameraLens get lens => _lens;

  @override
  bool get flashEnabled => _flashEnabled;

  @override
  Future<void> initialize({CameraLens preferredLens = CameraLens.back}) =>
      _operations.run(() => _initialize(preferredLens));

  Future<void> _initialize(CameraLens preferredLens) async {
    try {
      _cameras ??= await camera.availableCameras();
      if (_cameras!.isEmpty) {
        throw const CameraRepositoryException(
          'unavailable',
          'No camera is available on this device.',
        );
      }
      final camera.CameraDescription description = _descriptionFor(
        preferredLens,
      );
      await _dispose();
      final camera.CameraController controller = camera.CameraController(
        description,
        camera.ResolutionPreset.max,
        enableAudio: false,
        imageFormatGroup: camera.ImageFormatGroup.jpeg,
      );
      _controller = controller;
      try {
        await controller.initialize();
        await controller.setFlashMode(camera.FlashMode.off);
      } on Object {
        await controller.dispose();
        _controller = null;
        rethrow;
      }
      _lens = description.lensDirection == camera.CameraLensDirection.front
          ? CameraLens.front
          : CameraLens.back;
      _flashEnabled = false;
    } on camera.CameraException catch (error) {
      throw CameraRepositoryException(
        error.code,
        error.description ?? error.code,
      );
    }
  }

  @override
  Future<void> switchLens() => _operations.run(() async {
    final CameraLens next = _lens == CameraLens.back
        ? CameraLens.front
        : CameraLens.back;
    await _initialize(next);
  });

  @override
  Future<void> setFlashEnabled(bool enabled) =>
      _operations.run(() => _setFlashEnabled(enabled));

  Future<void> _setFlashEnabled(bool enabled) async {
    final camera.CameraController? controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      throw const CameraRepositoryException(
        'not-initialized',
        'The camera is not ready.',
      );
    }
    try {
      await controller.setFlashMode(
        enabled ? camera.FlashMode.auto : camera.FlashMode.off,
      );
      _flashEnabled = enabled;
    } on camera.CameraException catch (error) {
      throw CameraRepositoryException(
        error.code,
        error.description ?? error.code,
      );
    }
  }

  @override
  Future<String> captureRawImage() => _operations.run(_captureRawImage);

  Future<String> _captureRawImage() async {
    final camera.CameraController? controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      throw const CameraRepositoryException(
        'not-initialized',
        'The camera is not ready.',
      );
    }
    if (controller.value.isTakingPicture) {
      throw const CameraRepositoryException(
        'capture-in-progress',
        'A photo is already being captured.',
      );
    }
    try {
      return (await controller.takePicture()).path;
    } on camera.CameraException catch (error) {
      throw CameraRepositoryException(
        error.code,
        error.description ?? error.code,
      );
    }
  }

  @override
  Future<void> dispose() => _operations.run(_dispose);

  Future<void> _dispose() async {
    final controller = _controller;
    _controller = null;
    await controller?.dispose();
  }

  @override
  Future<void> focusAt(Offset normalizedPoint) =>
      _operations.run(() => _focusAt(normalizedPoint));

  Future<void> _focusAt(Offset normalizedPoint) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    try {
      await controller.setFocusPoint(normalizedPoint);
    } on camera.CameraException catch (error) {
      throw CameraRepositoryException(
        error.code,
        error.description ?? error.code,
      );
    }
  }

  camera.CameraDescription _descriptionFor(CameraLens requested) {
    final camera.CameraLensDirection direction = requested == CameraLens.front
        ? camera.CameraLensDirection.front
        : camera.CameraLensDirection.back;
    return _cameras!
            .where((item) => item.lensDirection == direction)
            .firstOrNull ??
        _cameras!.first;
  }
}
