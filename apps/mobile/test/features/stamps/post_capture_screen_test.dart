import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstamp/app/theme/app_theme.dart';
import 'package:inkstamp/features/camera/domain/repositories/image_processing_repository.dart';
import 'package:inkstamp/features/camera/presentation/controllers/camera_controller.dart';
import 'package:inkstamp/features/camera/presentation/screens/camera_screen.dart';
import 'package:inkstamp/features/stamps/domain/entities/stamp.dart';
import 'package:inkstamp/features/stamps/presentation/controllers/stamp_composer_controller.dart';
import 'package:inkstamp/features/stamps/presentation/screens/stamp_preview_screen.dart';
import '../camera/camera_controller_test.dart'
    show FakeCameraRepository, FakeImageProcessor;
import 'post_capture_flow_test.dart';

class FileImageProcessor extends FakeImageProcessor {
  FileImageProcessor(this.path);
  final String path;
  @override
  Future<ProcessedCameraImage> process(String rawImagePath) async =>
      ProcessedCameraImage(imagePath: path, thumbnailPath: path);
}

void main() {
  late String path;
  setUpAll(() async {
    final loader = FontLoader('BeVietnamPro')
      ..addFont(rootBundle.load('assets/fonts/BeVietnamPro-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/BeVietnamPro-Medium.ttf'))
      ..addFont(rootBundle.load('assets/fonts/BeVietnamPro-SemiBold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/BeVietnamPro-Bold.ttf'));
    await loader.load();
    final directory = await Directory.systemTemp.createTemp('inkstamp-widget-');
    path = '${directory.path}/capture.jpg';
    await File('assets/design/camera.jpg').copy(path);
    addTearDown(() => directory.delete(recursive: true));
  });

  Future<(ProviderContainer, GoRouter)> harness(
    WidgetTester tester, {
    FlowStampRepository? repository,
    bool fromCamera = false,
    bool reducedMotion = false,
  }) async {
    tester.view.physicalSize = const Size(390, 884);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final camera = FakeCameraRepository();
    final processor = FileImageProcessor(path);
    final scope = flowContainer(
      repository ?? FlowStampRepository(),
      FlowUploads(),
      processor: processor,
      camera: camera,
    );
    addTearDown(scope.dispose);
    if (!fromCamera) {
      scope
          .read(stampComposerControllerProvider.notifier)
          .capture(localImagePath: path, localThumbnailPath: path);
    }
    final router = GoRouter(
      initialLocation: fromCamera ? '/camera' : '/camera/preview',
      routes: [
        GoRoute(
          path: '/camera',
          builder: (_, _) => fromCamera
              ? const Scaffold(body: CameraScreen())
              : const Scaffold(body: Text('Camera ready')),
        ),
        GoRoute(
          path: '/camera/preview',
          builder: (_, _) => const StampPreviewScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: scope,
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(disableAnimations: reducedMotion),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (scope, router);
  }

  testWidgets(
    'capture opens preview with the processed file, discard returns to camera',
    (tester) async {
      final (container, router) = await harness(tester, fromCamera: true);
      // Shutter's central dot is the only GestureDetector with an 82dp container.
      final shutter = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.constraints?.maxWidth == 82 &&
            widget.constraints?.maxHeight == 82,
      );
      await tester.tap(shutter);
      await tester.pumpAndSettle();
      expect(find.byType(StampPreviewScreen), findsOneWidget);
      expect(
        container.read(stampComposerControllerProvider).localImagePath,
        path,
      );
      final camera =
          container.read(cameraRepositoryProvider) as FakeCameraRepository;
      final initializeCount = camera.initializeCount;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(
        camera.initializeCount,
        initializeCount,
        reason:
            'Resuming while Preview is open must not reactivate hidden camera hardware',
      );
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.path, '/camera');
      expect(
        container.read(stampComposerControllerProvider).localImagePath,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'audience supports multiple friends, ALL reset, empty custom disables send',
    (tester) async {
      final (container, _) = await harness(tester);
      await tester.tap(find.text('Lan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Minh'));
      await tester.pumpAndSettle();
      expect(
        container.read(stampComposerControllerProvider).selectedRecipientIds,
        {'lan', 'minh'},
      );
      await tester.tap(find.text('Tất cả'));
      await tester.pumpAndSettle();
      expect(
        container.read(stampComposerControllerProvider).audience,
        AudienceMode.allFriends,
      );
      await tester.tap(find.text('Lan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lan'));
      await tester.pumpAndSettle();
      final send = tester.widget<Semantics>(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == 'Gửi ảnh',
        ),
      );
      expect(send.properties.enabled, isFalse);
      expect(
        container.read(stampComposerControllerProvider).audience,
        AudienceMode.selected,
      );
    },
  );

  testWidgets(
    'Check sends once, shows progress and returns automatically with reduced motion',
    (tester) async {
      final repo = FlowStampRepository()..gate = Completer<void>();
      final (_, router) = await harness(
        tester,
        repository: repo,
        reducedMotion: true,
      );
      await tester.tap(find.bySemanticsLabel('Gửi ảnh'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Đang gửi'));
      await tester.pump();
      expect(repo.calls, 1);
      repo.gate!.complete();
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.path, '/camera');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'failed send retains photo and retry succeeds without recapture',
    (tester) async {
      final repo = FlowStampRepository()..failures = 1;
      final (container, router) = await harness(tester, repository: repo);
      await tester.tap(find.bySemanticsLabel('Gửi ảnh'));
      await tester.pumpAndSettle();
      expect(find.text('Không thể gửi ảnh.'), findsOneWidget);
      expect(
        container.read(stampComposerControllerProvider).localImagePath,
        path,
      );
      await tester.ensureVisible(find.text('Thử lại'));
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(repo.calls, 2);
      expect(router.routerDelegate.currentConfiguration.uri.path, '/camera');
    },
  );
}
