import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstamp/app/router/main_shell.dart';
import 'package:inkstamp/app/theme/app_theme.dart';
import 'package:inkstamp/features/archive/presentation/screens/calendar_screen.dart';
import 'package:inkstamp/features/camera/presentation/controllers/camera_controller.dart';
import 'package:inkstamp/features/camera/presentation/screens/camera_screen.dart';
import 'package:inkstamp/features/home/presentation/screens/home_screen.dart';
import 'package:inkstamp/features/settings/presentation/screens/settings_screen.dart';
import 'package:inkstamp/features/stamps/presentation/controllers/stamp_composer_controller.dart';
import 'package:inkstamp/features/stamps/presentation/screens/stamp_preview_screen.dart';
import 'package:integration_test/integration_test.dart';

// Real CameraX hardware, real CameraScreen/Preview and real local processor.
// No auth/backend coverage is claimed: other tabs use existing demo repositories.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('camera rapid tabs and Android background stress', (
    tester,
  ) async {
    final container = ProviderContainer();
    final router = GoRouter(
      initialLocation: '/camera',
      routes: [
        ShellRoute(
          builder: (_, _, child) => MainShell(child: child),
          routes: [
            GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
            GoRoute(
              path: '/calendar',
              builder: (_, _) => const CalendarScreen(),
            ),
            GoRoute(
              path: '/profile',
              builder: (_, _) => const SettingsScreen(),
            ),
            GoRoute(path: '/camera', builder: (_, _) => const CameraScreen()),
          ],
        ),
        GoRoute(
          path: '/camera/preview',
          builder: (_, _) => const StampPreviewScreen(),
        ),
      ],
    );
    Future<void> ready() async {
      for (var i = 0; i < 240; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (container.read(cameraControllerProvider).phase ==
            CameraPhase.ready) {
          return;
        }
      }
      fail('Camera failed to reach ready within 24 seconds.');
    }

    try {
      final opening = Stopwatch()..start();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await ready();
      debugPrint('HARDENING camera_open_ms=${opening.elapsedMilliseconds}');
      for (var i = 0; i < 20; i++) {
        await tester.tap(find.text(['Khoảnh khắc', 'Lịch', 'Cá nhân'][i % 3]));
        await tester.pump(const Duration(milliseconds: 30));
        await tester.tap(find.text('Máy ảnh'));
        await tester.pump(const Duration(milliseconds: 30));
      }
      await ready();
      expect(tester.takeException(), isNull);
      debugPrint('HARDENING rapid_switches=20 PASS');
      // Stop after init begins, not after ready.
      router.go('/home');
      await tester.pump(const Duration(milliseconds: 100));
      router.go('/camera');
      await tester.pump(const Duration(milliseconds: 30));
      debugPrint('HARDENING ANDROID_BACKGROUND_REQUEST');
      // Secure host runner performs actual HOME + activity resume here.
      await Future<void>.delayed(const Duration(seconds: 5));
      await ready();
      expect(tester.takeException(), isNull);
      debugPrint('HARDENING background_resume PASS');
      final shutter = find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.constraints?.maxWidth == 82 &&
            w.constraints?.maxHeight == 82,
      );
      await tester.tap(shutter);
      for (
        var i = 0;
        i < 240 && find.byType(StampPreviewScreen).evaluate().isEmpty;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(StampPreviewScreen), findsOneWidget);
      final draft = container.read(stampComposerControllerProvider);
      expect(await File(draft.localImagePath!).exists(), isTrue);
      debugPrint('HARDENING PREVIEW_BACKGROUND_REQUEST');
      await Future<void>.delayed(const Duration(seconds: 5));
      expect(
        container.read(stampComposerControllerProvider).localImagePath,
        draft.localImagePath,
      );
      expect(container.read(cameraControllerProvider).previewHandle, isNull);
      await tester.tap(find.byIcon(Icons.close));
      await ready();
      expect(await File(draft.localImagePath!).exists(), isFalse);
      router.go('/home');
      await tester.pump(const Duration(milliseconds: 30));
      router.go('/camera');
      await tester.pump(const Duration(milliseconds: 30));
      await ready();
      expect(tester.takeException(), isNull);
      debugPrint('HARDENING preview_return_retake_cleanup PASS');
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      router.dispose();
      container.dispose();
    }
  });
}
