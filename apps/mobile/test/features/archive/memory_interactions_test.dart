import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstamp/app/theme/app_theme.dart';
import 'package:inkstamp/core/widgets/memory_photo.dart';
import 'package:inkstamp/core/widgets/stamp_artwork.dart';
import 'package:inkstamp/features/archive/presentation/controllers/memory_view_controller.dart';
import 'package:inkstamp/features/archive/presentation/screens/calendar_screen.dart';
import 'package:inkstamp/features/home/presentation/screens/home_screen.dart';
import 'package:inkstamp/features/inbox/presentation/screens/stamp_detail_screen.dart';
import 'package:inkstamp/features/settings/presentation/screens/settings_screen.dart';
import '../stamps/post_capture_flow_test.dart';

void main() {
  setUpAll(() async {
    final loader = FontLoader('BeVietnamPro')
      ..addFont(rootBundle.load('assets/fonts/BeVietnamPro-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/BeVietnamPro-Medium.ttf'))
      ..addFont(rootBundle.load('assets/fonts/BeVietnamPro-SemiBold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/BeVietnamPro-Bold.ttf'));
    await loader.load();
  });

  Future<(ProviderContainer, GoRouter)> harness(
    WidgetTester tester,
    String route,
    Widget screen,
    FlowStampRepository repo,
  ) async {
    tester.view.physicalSize = const Size(412, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = flowContainer(repo, FlowUploads());
    addTearDown(container.dispose);
    container
        .read(calendarSelectionProvider.notifier)
        .select(DateTime(2026, 9, 26));
    final router = GoRouter(
      initialLocation: route,
      routes: [
        GoRoute(
          path: route,
          builder: (_, _) => Scaffold(body: screen),
        ),
        GoRoute(
          path: '/stamp/:stampId',
          builder: (_, state) =>
              StampDetailScreen(stampId: state.pathParameters['stampId']!),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return (container, router);
  }

  testWidgets(
    'history renders overlays and truncated title, photo opens actual detail',
    (tester) async {
      final stamp = flowStamp(
        'history',
        DateTime(2026, 9, 26, 8, 30),
        caption: 'Một đoạn tiêu đề dài hơn hai mươi tám ký tự để kiểm tra',
        own: false,
      );
      final repo = FlowStampRepository()..received = [stamp];
      final (_, _) = await harness(tester, '/home', const HomeScreen(), repo);
      expect(find.text('08:30'), findsOneWidget);
      expect(find.text('Lan'), findsOneWidget);
      expect(find.text(stamp.shortTitle), findsOneWidget);
      expect(stamp.shortTitle.runes.length, 28);
      expect(stamp.shortTitle.endsWith('…'), isTrue);
      await tester.tap(find.text(stamp.shortTitle));
      await tester.pumpAndSettle();
      expect(find.byType(StampDetailScreen), findsOneWidget);
      expect(
        tester
            .widget<StampDetailScreen>(find.byType(StampDetailScreen))
            .stampId,
        'history',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'calendar date selection updates memories and month navigation is real',
    (tester) async {
      final repo = FlowStampRepository()
        ..sent = [
          flowStamp(
            'calendar',
            DateTime(2026, 9, 26),
            caption: 'Ngày thứ hai mươi sáu',
          ),
        ];
      final (container, _) = await harness(
        tester,
        '/calendar',
        const CalendarScreen(),
        repo,
      );
      expect(find.text('Ngày thứ hai mươi sáu'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel(RegExp('27/09/2026')));
      await tester.pumpAndSettle();
      expect(container.read(calendarSelectionProvider).date!.day, 27);
      expect(find.text('Ngày thứ hai mươi sáu'), findsNothing);
      expect(find.text('Chưa có khoảnh khắc trong ngày này.'), findsOneWidget);
      await tester.tap(find.byTooltip('Tháng sau'));
      await tester.pumpAndSettle();
      expect(
        container.read(calendarSelectionProvider).month,
        DateTime(2026, 10),
      );
      expect(find.text('Tháng 10, 2026'), findsOneWidget);
      await tester.tap(find.byTooltip('Tháng trước'));
      await tester.pumpAndSettle();
      expect(
        container.read(calendarSelectionProvider).month,
        DateTime(2026, 9),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'collection filters its real stamps and tile opens actual detail',
    (tester) async {
      final repo = FlowStampRepository()
        ..sent = [
          flowStamp('new', DateTime(2026, 9, 26), caption: 'Tem mới'),
          flowStamp('old', DateTime(2025, 8, 1), caption: 'Tem cũ'),
        ];
      final (container, _) = await harness(
        tester,
        '/profile',
        const SettingsScreen(),
        repo,
      );
      expect(find.text('Tem mới'), findsOneWidget);
      expect(find.text('Tem cũ'), findsOneWidget);
      await tester.tap(find.text('2025'));
      await tester.pumpAndSettle();
      expect(
        container.read(collectionFilterProvider),
        CollectionFilter.year2025,
      );
      expect(find.text('Tem mới'), findsNothing);
      await tester.tap(find.text('Tem cũ'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<StampDetailScreen>(find.byType(StampDetailScreen))
            .stampId,
        'old',
      );
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'calendar clears arbitrary day on month change and retains explicit selection',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final calendar = container.read(calendarSelectionProvider.notifier);
      calendar.select(DateTime(2026, 1, 31));
      calendar.moveMonth(1);
      expect(container.read(calendarSelectionProvider).date, isNull);
      calendar.select(DateTime(2026, 3, 8));
      expect(
        container.read(calendarSelectionProvider).month,
        DateTime(2026, 3),
      );
    },
  );

  testWidgets(
    'History uses full processed square and omits an empty title pill',
    (tester) async {
      final stamp = flowStamp('square-history', DateTime(2026, 9, 26)).copyWith(
        cloudinaryPublicId: 'processed-full',
        cloudinaryThumbnailPublicId: 'processed-thumb',
      );
      await harness(
        tester,
        '/home',
        const HomeScreen(),
        FlowStampRepository()..sent = [stamp],
      );
      final photo = find.byType(MemoryPhoto);
      expect(tester.widget<MemoryPhoto>(photo).publicId, 'processed-full');
      final size = tester.getSize(photo);
      expect(size.width, closeTo(size.height, .01));
      expect(
        find.byWidgetPredicate((w) => w.runtimeType.toString() == '_PhotoTag'),
        findsNWidgets(2),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Collection keeps three equal square thumbnail tiles and one-line titles',
    (tester) async {
      final stamps = List.generate(
        3,
        (index) =>
            flowStamp(
              'tile-$index',
              DateTime(2026, 9, 26),
              caption: 'Ảnh $index',
            ).copyWith(
              cloudinaryPublicId: 'full-$index',
              cloudinaryThumbnailPublicId: 'thumb-$index',
            ),
      );
      await harness(
        tester,
        '/profile',
        const SettingsScreen(),
        FlowStampRepository()..sent = stamps,
      );
      final photos = find.byType(MemoryPhoto);
      expect(photos, findsNWidgets(3));
      final sizes = [
        for (final e in photos.evaluate())
          tester.getSize(find.byWidget(e.widget)),
      ];
      for (var i = 0; i < 3; i++) {
        expect(tester.widget<MemoryPhoto>(photos.at(i)).publicId, 'thumb-$i');
        expect(sizes[i].width, closeTo(sizes[i].height, .01));
        expect(sizes[i], sizes.first);
        expect(tester.widget<Text>(find.text('Ảnh $i')).maxLines, 1);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Calendar cell and day entry use square optimized thumbnails', (
    tester,
  ) async {
    final stamp = flowStamp('square-calendar', DateTime(2026, 9, 26)).copyWith(
      cloudinaryPublicId: 'full-calendar',
      cloudinaryThumbnailPublicId: 'thumb-calendar',
    );
    await harness(
      tester,
      '/calendar',
      const CalendarScreen(),
      FlowStampRepository()..sent = [stamp],
    );
    final photos = find.byType(MemoryPhoto);
    expect(photos, findsNWidgets(2));
    for (final e in photos.evaluate()) {
      expect((e.widget as MemoryPhoto).publicId, 'thumb-calendar');
      final size = tester.getSize(find.byWidget(e.widget));
      expect(size.width, closeTo(size.height, .01));
    }
    expect(tester.getSize(photos.first), const Size(21, 21));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Memory Detail retains the full processed image in a square stamp',
    (tester) async {
      final stamp = flowStamp('full-detail', DateTime(2026, 9, 26)).copyWith(
        cloudinaryPublicId: 'detail-1440',
        cloudinaryThumbnailPublicId: 'detail-512',
      );
      await harness(
        tester,
        '/detail',
        const StampDetailScreen(stampId: 'full-detail'),
        FlowStampRepository()..sent = [stamp],
      );
      final artwork = find.byType(StampArtwork);
      expect(tester.widget<StampArtwork>(artwork).publicId, 'detail-1440');
      final size = tester.getSize(artwork);
      expect(size.width, closeTo(size.height, .01));
      expect(tester.takeException(), isNull);
    },
  );
}
