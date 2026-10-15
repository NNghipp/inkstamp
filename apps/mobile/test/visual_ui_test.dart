import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstamp/app/router/main_shell.dart';
import 'package:inkstamp/app/theme/app_theme.dart';
import 'package:inkstamp/features/archive/presentation/screens/calendar_screen.dart';
import 'package:inkstamp/features/camera/domain/repositories/image_processing_repository.dart';
import 'package:inkstamp/features/camera/presentation/controllers/camera_controller.dart';
import 'package:inkstamp/features/camera/presentation/screens/camera_screen.dart';
import 'package:inkstamp/features/home/presentation/screens/home_screen.dart';
import 'package:inkstamp/features/settings/presentation/screens/settings_screen.dart';
import 'package:inkstamp/features/stamps/presentation/screens/stamp_preview_screen.dart';

const List<String> _visualAssets = <String>[
  'assets/design/camera.jpg',
  'assets/design/friends.jpg',
  'assets/design/cafe_friends.jpg',
  'assets/design/portrait.jpg',
  'assets/design/tea.jpg',
  'assets/design/preview_stamp.jpg',
];

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final FontLoader iconLoader = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    final FontLoader loader = FontLoader('BeVietnamPro')
      ..addFont(rootBundle.load('assets/fonts/BeVietnamPro-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/BeVietnamPro-Medium.ttf'))
      ..addFont(rootBundle.load('assets/fonts/BeVietnamPro-SemiBold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/BeVietnamPro-Bold.ttf'));
    await Future.wait(<Future<void>>[iconLoader.load(), loader.load()]);
  });

  Future<void> prepare(
    WidgetTester tester,
    Size size, {
    double devicePixelRatio = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = devicePixelRatio;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> pumpShell(
    WidgetTester tester, {
    required String path,
    required Widget screen,
  }) async {
    final GoRouter router = GoRouter(
      initialLocation: path,
      routes: <RouteBase>[
        ShellRoute(
          builder: (BuildContext context, GoRouterState state, Widget child) =>
              MainShell(child: child),
          routes: <RouteBase>[GoRoute(path: path, builder: (_, _) => screen)],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          imageProcessingRepositoryProvider.overrideWithValue(
            _NoopImageProcessor(),
          ),
        ],
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          routerConfig: router,
        ),
      ),
    );
    await tester.runAsync(() async {
      final BuildContext context = tester.element(find.byType(MaterialApp));
      for (final String asset in _visualAssets) {
        await precacheImage(AssetImage(asset), context);
        await precacheImage(
          ResizeImage(AssetImage(asset), width: 512),
          context,
        );
        await precacheImage(
          ResizeImage(AssetImage(asset), width: 1440),
          context,
        );
      }
    });
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('render feed', (WidgetTester tester) async {
    await prepare(tester, const Size(390, 1580));
    await pumpShell(
      tester,
      path: '/home',
      screen: const HomeScreen(initializeCamera: false),
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/feed.png'),
    );
  });

  testWidgets('render calendar', (WidgetTester tester) async {
    await prepare(tester, const Size(390, 1608));
    await pumpShell(
      tester,
      path: '/calendar',
      screen: const CalendarScreen(designPreview: true),
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/calendar.png'),
    );
  });

  testWidgets('render camera', (WidgetTester tester) async {
    await prepare(tester, const Size(706, 1600), devicePixelRatio: 2);
    await pumpShell(
      tester,
      path: '/camera',
      screen: const CameraScreen(initializeCamera: false),
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/camera.png'),
    );
  });

  testWidgets('render profile', (WidgetTester tester) async {
    await prepare(tester, const Size(390, 1163));
    await pumpShell(
      tester,
      path: '/profile',
      screen: const SettingsScreen(designPreview: true),
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/profile.png'),
    );
  });

  testWidgets('render preview', (WidgetTester tester) async {
    await prepare(tester, const Size(390, 884));
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          home: const StampPreviewScreen(designPreview: true),
        ),
      ),
    );
    await tester.runAsync(() async {
      final BuildContext context = tester.element(find.byType(MaterialApp));
      for (final String asset in _visualAssets) {
        await precacheImage(AssetImage(asset), context);
      }
    });
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/preview.png'),
    );
  });
}

class _NoopImageProcessor implements ImageProcessingRepository {
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
