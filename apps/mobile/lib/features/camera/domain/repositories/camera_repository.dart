import 'dart:ui';

enum CameraLens { back, front }

/// Optional hardware capability; unsupported repositories need not implement it.
abstract interface class FocusCameraRepository {
  Future<void> focusAt(Offset normalizedPoint);
}

abstract interface class CameraRepository {
  Object? get previewHandle;

  CameraLens get lens;

  bool get flashEnabled;

  Future<void> initialize({CameraLens preferredLens = CameraLens.back});

  Future<void> switchLens();

  Future<void> setFlashEnabled(bool enabled);

  Future<String> captureRawImage();

  Future<void> dispose();
}

class CameraRepositoryException implements Exception {
  const CameraRepositoryException(this.code, this.message);

  final String code;
  final String message;
}
