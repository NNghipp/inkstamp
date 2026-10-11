import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkstamp/features/camera/domain/repositories/camera_repository.dart';
import 'package:inkstamp/features/camera/domain/repositories/image_processing_repository.dart';
import 'package:inkstamp/features/camera/presentation/controllers/camera_controller.dart';
import 'package:inkstamp/features/camera/presentation/screens/camera_screen.dart';

void main() {
  testWidgets(
    'camera unmount does not mutate provider during widget disposal',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          cameraRepositoryProvider.overrideWithValue(DeniedCameraRepository()),
          imageProcessingRepositoryProvider.overrideWithValue(
            NoopImageProcessor(),
          ),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: CameraScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(
        container.read(cameraControllerProvider).phase,
        CameraPhase.unavailable,
      );
    },
  );
  testWidgets('shows a retry action when camera permission is denied', (
    WidgetTester tester,
  ) async {
    final DeniedCameraRepository camera = DeniedCameraRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cameraRepositoryProvider.overrideWithValue(camera),
          imageProcessingRepositoryProvider.overrideWithValue(
            NoopImageProcessor(),
          ),
        ],
        child: const MaterialApp(home: CameraScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('permission'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(camera.initializeCount, 2);
  });

  testWidgets('shows initialization progress before a preview is ready', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cameraRepositoryProvider.overrideWithValue(PendingCameraRepository()),
          imageProcessingRepositoryProvider.overrideWithValue(
            NoopImageProcessor(),
          ),
        ],
        child: const MaterialApp(home: CameraScreen()),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}

class DeniedCameraRepository implements CameraRepository {
  int initializeCount = 0;
  @override
  bool get flashEnabled => false;
  @override
  CameraLens get lens => CameraLens.back;
  @override
  Object? get previewHandle => null;

  @override
  Future<void> initialize({CameraLens preferredLens = CameraLens.back}) async {
    initializeCount += 1;
    throw const CameraRepositoryException('CameraAccessDenied', 'denied');
  }

  @override
  Future<String> captureRawImage() => throw UnimplementedError();
  @override
  Future<void> dispose() async {}
  @override
  Future<void> setFlashEnabled(bool enabled) => throw UnimplementedError();
  @override
  Future<void> switchLens() => throw UnimplementedError();
}

class PendingCameraRepository extends DeniedCameraRepository {
  final Completer<void> _completer = Completer<void>();

  @override
  Future<void> initialize({CameraLens preferredLens = CameraLens.back}) {
    return _completer.future;
  }
}

class NoopImageProcessor implements ImageProcessingRepository {
  @override
  Future<int> cleanupExpiredDrafts({
    Duration maximumAge = const Duration(hours: 24),
  }) async => 0;
  @override
  Future<void> deleteFiles(Iterable<String?> paths) async {}
  @override
  Future<ProcessedCameraImage> process(String rawImagePath) =>
      throw UnimplementedError();
}
