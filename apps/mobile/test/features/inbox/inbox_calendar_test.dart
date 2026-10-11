import 'dart:async';

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
import 'package:inkstamp/features/authentication/domain/entities/app_user.dart';
import 'package:inkstamp/features/authentication/presentation/controllers/session_controller.dart';
import 'package:inkstamp/features/inbox/presentation/controllers/inbox_controller.dart';
import 'package:inkstamp/features/inbox/presentation/screens/inbox_screen.dart';
import 'package:inkstamp/features/inbox/presentation/screens/stamp_detail_screen.dart';
import 'package:inkstamp/features/stamps/data/repositories/in_memory_stamp_repository.dart';
import 'package:inkstamp/features/stamps/presentation/controllers/stamp_publication_controller.dart';
import 'package:inkstamp/features/stamps/presentation/controllers/stamp_timeline_controller.dart';

import '../stamps/post_capture_flow_test.dart';

Future<void> flush() => Future<void>.delayed(Duration.zero);

class TestSession extends SessionController {
  @override
  SessionState build() => const SessionState.signedOut();
  void account(String id) => state = SessionState(
    stage: SessionStage.ready,
    user: AppUser(
      id: id,
      username: id,
      displayName: id,
      onboardingComplete: true,
    ),
  );
}

void main() {
  setUpAll(() async {
    final loader = FontLoader('BeVietnamPro')
      ..addFont(rootBundle.load('assets/fonts/BeVietnamPro-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/BeVietnamPro-Medium.ttf'))
      ..addFont(rootBundle.load('assets/fonts/BeVietnamPro-SemiBold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/BeVietnamPro-Bold.ttf'));
    await loader.load();
  });
  test(
    'repository cursor handles equal timestamps without gaps or duplicates',
    () async {
      final repo = FlowStampRepository()
        ..received = List.generate(
          51,
          (i) => flowStamp(
            'id-${i.toString().padLeft(2, '0')}',
            DateTime(2026, 9, 26),
            own: false,
          ),
        );
      final a = await repo.fetchReceivedPage();
      final b = await repo.fetchReceivedPage(after: a.next);
      final c = await repo.fetchReceivedPage(after: b.next);
      expect(a.items.length, 25);
      expect(b.items.length, 25);
      expect(c.items.length, 1);
      expect(c.next, isNull);
      expect(
        [...a.items, ...b.items, ...c.items].map((s) => s.id).toSet().length,
        51,
      );
      expect(a.items.first.id, 'id-50');
    },
  );

  test(
    'in-memory repository persists reads and resolves IDs outside a page',
    () async {
      final repo = InMemoryStampRepository();
      final first = await repo.fetchReceivedPage(limit: 1);
      await repo.markDeliveryRead(first.items.single.id);
      expect((await repo.getById(first.items.single.id))!.isSeen, isTrue);
      final next = await repo.fetchReceivedPage(after: first.next, limit: 1);
      expect(await repo.getById(next.items.single.id), isNotNull);
      expect(await repo.getById('deleted'), isNull);
      final now = DateTime.now();
      final month = await repo.fetchMonth(
        DateTime(now.year, now.month),
        DateTime(now.year, now.month + 1),
      );
      expect(
        month.every((s) => s.createdAt.toLocal().month == now.month),
        isTrue,
      );
    },
  );

  test(
    'Inbox sorts, paginates and refreshes; read persistence and deduplication',
    () async {
      final repo = FlowStampRepository()
        ..received = List.generate(
          30,
          (i) => flowStamp('$i', DateTime(2026, 9, i + 1), own: false),
        );
      final container = flowContainer(repo, FlowUploads());
      addTearDown(container.dispose);
      final inbox = container.read(inboxControllerProvider.notifier);
      await flush();
      expect(container.read(inboxControllerProvider).items.length, 25);
      expect(container.read(inboxControllerProvider).items.first.id, '29');
      await inbox.loadMore();
      expect(container.read(inboxControllerProvider).items.length, 30);
      final stamp = container.read(inboxControllerProvider).items.first;
      await Future.wait([inbox.markRead(stamp), inbox.markRead(stamp)]);
      expect(repo.readCalls, 1);
      expect((await repo.getById(stamp.id))!.isSeen, isTrue);
      await inbox.refresh();
      expect(
        container.read(inboxControllerProvider).items.first.isSeen,
        isTrue,
      );
      await inbox.markRead(stamp);
      expect(repo.readCalls, 1);
    },
  );

  test(
    'Inbox retries failure and keeps loaded data offline; read failure stays unread',
    () async {
      final repo = FlowStampRepository()
        ..pageFailures = 1
        ..received = [flowStamp('inbox', DateTime(2026, 9, 26), own: false)]
        ..readFails = true;
      final container = flowContainer(repo, FlowUploads());
      addTearDown(container.dispose);
      final inbox = container.read(inboxControllerProvider.notifier);
      await flush();
      expect(container.read(inboxControllerProvider).error, isNotNull);
      await inbox.refresh();
      final stamp = container.read(inboxControllerProvider).items.single;
      await inbox.markRead(stamp);
      expect(
        container.read(inboxControllerProvider).items.single.isSeen,
        isFalse,
      );
      repo.pageFailures = 1;
      await inbox.refresh();
      expect(container.read(inboxControllerProvider).items.single.id, 'inbox');
      expect(container.read(inboxControllerProvider).error, isNotNull);
      repo.readFails = false;
      await inbox.markRead(stamp);
      expect(
        container.read(inboxControllerProvider).items.single.isSeen,
        isTrue,
      );
    },
  );

  test(
    'repository-enforced unavailable deliveries never surface in Inbox or Calendar',
    () async {
      final repo = FlowStampRepository()
        ..received = [flowStamp('blocked', DateTime(2026, 9, 26), own: false)]
        ..unavailable.add('blocked');
      expect((await repo.fetchReceivedPage()).items, isEmpty);
      expect(
        await repo.fetchMonth(DateTime(2026, 9), DateTime(2026, 10)),
        isEmpty,
      );
      expect(await repo.getById('blocked'), isNull);
      final container = flowContainer(repo, FlowUploads());
      addTearDown(container.dispose);
      container.read(inboxControllerProvider);
      await flush();
      expect(container.read(inboxControllerProvider).items, isEmpty);
    },
  );

  test(
    'Calendar queries exact half-open local month and reuses cached month on day changes',
    () async {
      final start = DateTime(2026, 9);
      final end = DateTime(2026, 10);
      final repo = FlowStampRepository()
        ..sent = [
          flowStamp('before', start.subtract(const Duration(microseconds: 1))),
          flowStamp('start', start),
          flowStamp('same-day', start.add(const Duration(hours: 2))),
          flowStamp('end', end),
        ];
      final container = flowContainer(repo, FlowUploads());
      addTearDown(container.dispose);
      expect(
        (await container.read(
          calendarMonthProvider(start).future,
        )).map((s) => s.id),
        ['same-day', 'start'],
      );
      final selection = container.read(calendarSelectionProvider.notifier);
      selection.select(start);
      expect(container.read(dayMemoriesProvider).length, 2);
      selection.select(DateTime(2026, 9, 2));
      expect(container.read(dayMemoriesProvider), isEmpty);
      selection.moveMonth(1);
      await container.read(calendarMonthProvider(end).future);
      selection.moveMonth(-1);
      await container.read(calendarMonthProvider(start).future);
      expect(repo.ranges, [(start, end), (end, DateTime(2026, 11))]);
      expect(repo.historyReads, 0);
    },
  );

  test(
    'new publication invalidates only matching cached month; refresh retries offline month',
    () async {
      final repo = FlowStampRepository();
      final container = flowContainer(repo, FlowUploads());
      addTearDown(container.dispose);
      final month = DateTime(2026, 9);
      final sub = container.listen(calendarMonthProvider(month), (_, _) {});
      addTearDown(sub.close);
      await container.read(calendarMonthProvider(month).future);
      container
          .read(stampPublicationProvider.notifier)
          .published(flowStamp('other', DateTime(2026, 8, 1)));
      await flush();
      expect(repo.ranges.length, 1);
      repo.sent.add(flowStamp('new', DateTime(2026, 9, 26)));
      container
          .read(stampPublicationProvider.notifier)
          .published(repo.sent.single);
      await container.read(calendarMonthProvider(month).future);
      expect(repo.ranges.length, 2);
      expect(
        container.read(calendarMonthProvider(month)).value!.single.id,
        'new',
      );
      repo.monthFailures = 1;
      container.invalidate(calendarMonthProvider(month));
      await expectLater(
        container.read(calendarMonthProvider(month).future),
        throwsStateError,
      );
      container.invalidate(calendarMonthProvider(month));
      expect(
        (await container.read(calendarMonthProvider(month).future)).single.id,
        'new',
      );
    },
  );

  test(
    'UTC instants use local calendar day, including local midnight boundary',
    () async {
      final local = DateTime(2026, 9, 26, 0, 30);
      final utc = local.toUtc();
      expect(utc.isUtc, isTrue);
      expect(sameDay(utc, DateTime(2026, 9, 26)), isTrue);
      expect(
        sameDay(
          DateTime(2026, 9, 26).toUtc().subtract(const Duration(seconds: 1)),
          local,
        ),
        isFalse,
      );
      final repo = FlowStampRepository()
        ..received = [flowStamp('utc', utc, own: false)];
      final container = flowContainer(repo, FlowUploads());
      addTearDown(container.dispose);
      container
          .read(calendarSelectionProvider.notifier)
          .select(DateTime(2026, 9, 26));
      await container.read(calendarMonthProvider(DateTime(2026, 9)).future);
      expect(container.read(dayMemoriesProvider).single.id, 'utc');
    },
  );

  test(
    'Inbox and Calendar cache is scoped to account, not carried to next session',
    () async {
      final repo = FlowStampRepository()
        ..received = [flowStamp('A', DateTime(2026, 9, 26), own: false)];
      final container = ProviderContainer(
        overrides: [
          stampRepositoryProvider.overrideWithValue(repo),
          sessionControllerProvider.overrideWith(TestSession.new),
        ],
      );
      addTearDown(container.dispose);
      final session =
          container.read(sessionControllerProvider.notifier) as TestSession;
      session.account('accountA');
      final sub = container.listen(inboxControllerProvider, (_, _) {});
      final monthSub = container.listen(
        calendarMonthProvider(DateTime(2026, 9)),
        (_, _) {},
      );
      addTearDown(sub.close);
      addTearDown(monthSub.close);
      await container.read(calendarMonthProvider(DateTime(2026, 9)).future);
      await flush();
      expect(container.read(inboxControllerProvider).items.single.id, 'A');
      repo.received = [flowStamp('B', DateTime(2026, 9, 26), own: false)];
      session.account('accountB');
      expect(container.read(inboxControllerProvider).items, isEmpty);
      await container.read(calendarMonthProvider(DateTime(2026, 9)).future);
      await flush();
      expect(container.read(inboxControllerProvider).items.single.id, 'B');
      expect(
        container
            .read(calendarMonthProvider(DateTime(2026, 9)))
            .value!
            .single
            .id,
        'B',
      );
      expect(repo.ranges.length, 2);
    },
  );

  test(
    'Calendar selects today only in current month; unrelated months have no forced day',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final today = DateTime.now();
      final controller = container.read(calendarSelectionProvider.notifier);
      expect(
        sameDay(container.read(calendarSelectionProvider).date!, today),
        isTrue,
      );
      controller.moveMonth(-1);
      expect(container.read(calendarSelectionProvider).date, isNull);
      controller.moveMonth(1);
      expect(
        sameDay(container.read(calendarSelectionProvider).date!, today),
        isTrue,
      );
      controller.select(DateTime(today.year, today.month, 1));
      expect(container.read(calendarSelectionProvider).date!.day, 1);
    },
  );

  Future<(ProviderContainer, GoRouter)> harness(
    WidgetTester tester,
    FlowStampRepository repo, {
    Widget screen = const InboxScreen(),
    String initial = '/inbox',
  }) async {
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
      initialLocation: initial,
      routes: [
        GoRoute(
          path: '/inbox',
          builder: (_, _) => Scaffold(body: screen),
        ),
        GoRoute(
          path: '/stamp/:stampId',
          builder: (_, s) =>
              StampDetailScreen(stampId: s.pathParameters['stampId']!),
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
    'Inbox unread semantics, thumbnail and shared Detail; read only after lookup',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final repo = FlowStampRepository()
        ..received = [
          flowStamp('received', DateTime(2026, 9, 26), own: false).copyWith(
            cloudinaryPublicId: 'full',
            cloudinaryThumbnailPublicId: 'thumbnail',
          ),
        ];
      final (_, router) = await harness(tester, repo);
      expect(find.bySemanticsLabel(RegExp('Lan, Chưa đọc')), findsOneWidget);
      expect(find.text('•'), findsOneWidget);
      expect(find.byType(MemoryPhoto), findsOneWidget);
      expect(
        tester.widget<MemoryPhoto>(find.byType(MemoryPhoto)).publicId,
        'thumbnail',
      );
      repo.detailGate = Completer<void>();
      await tester.tap(find.text('Lan'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(repo.readCalls, 0);
      repo.detailGate!.complete();
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<StampDetailScreen>(find.byType(StampDetailScreen))
            .stampId,
        'received',
      );
      expect(repo.readCalls, 1);
      expect(
        tester.widget<StampArtwork>(find.byType(StampArtwork)).publicId,
        'full',
      );
      router.pop();
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(RegExp('Lan, Đã đọc')), findsOneWidget);
      expect(find.text('•'), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets('Failed mark-read never blocks Detail and retries on next open', (
    tester,
  ) async {
    final repo = FlowStampRepository()
      ..readFails = true
      ..received = [flowStamp('retry', DateTime(2026, 9, 26), own: false)];
    final (_, router) = await harness(tester, repo);
    await tester.tap(find.text('Lan'));
    await tester.pumpAndSettle();
    expect(find.byType(StampDetailScreen), findsOneWidget);
    expect(repo.readCalls, 1);
    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('•'), findsOneWidget);
    repo.readFails = false;
    await tester.tap(find.text('Lan'));
    await tester.pumpAndSettle();
    expect(repo.readCalls, 2);
    expect((await repo.getById('retry'))!.isSeen, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Inbox empty and inline error retry states', (tester) async {
    final repo = FlowStampRepository()..pageFailures = 1;
    await harness(tester, repo);
    expect(find.text('Không thể tải hộp thư. Thử lại'), findsOneWidget);
    await tester.tap(find.text('Không thể tải hộp thư. Thử lại'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Chưa có stamp mới.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Inbox load-more action adds next page with no duplicates', (
    tester,
  ) async {
    final repo = FlowStampRepository()
      ..received = List.generate(
        30,
        (i) => flowStamp('page-$i', DateTime(2026, 9, i + 1), own: false),
      );
    final (container, _) = await harness(tester, repo);
    expect(container.read(inboxControllerProvider).items.length, 25);
    await tester.scrollUntilVisible(find.text('Tải thêm'), 500);
    await tester.tap(find.text('Tải thêm'));
    await tester.pumpAndSettle();
    expect(container.read(inboxControllerProvider).items.length, 30);
    expect(
      container
          .read(inboxControllerProvider)
          .items
          .map((s) => s.id)
          .toSet()
          .length,
      30,
    );
    expect(repo.pageCalls, 2);
    expect(find.text('Tải thêm'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Unavailable Detail does not mark read; lookup error can retry', (
    tester,
  ) async {
    final repo = FlowStampRepository()..detailFails = true;
    await harness(tester, repo, initial: '/stamp/missing');
    expect(find.text('Không thể tải stamp. Thử lại'), findsOneWidget);
    expect(repo.readCalls, 0);
    repo.detailFails = false;
    await tester.tap(find.text('Không thể tải stamp. Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Stamp không còn khả dụng.'), findsOneWidget);
    expect(repo.readCalls, 0);
  });

  testWidgets('Calendar error retry and thumbnail opens same Detail', (
    tester,
  ) async {
    final repo = FlowStampRepository()
      ..monthFailures = 1
      ..received = [
        flowStamp(
          'calendar',
          DateTime(2026, 9, 26),
          caption: 'Calendar memory',
          own: false,
        ),
      ];
    await harness(tester, repo, screen: const CalendarScreen());
    expect(find.text('Không thể tải lịch. Thử lại'), findsOneWidget);
    await tester.tap(find.text('Không thể tải lịch. Thử lại'));
    await tester.pumpAndSettle();
    // The faithful square image is taller; scroll to the existing caption target.
    await tester.ensureVisible(find.text('Calendar memory'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Calendar memory'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<StampDetailScreen>(find.byType(StampDetailScreen)).stampId,
      'calendar',
    );
    expect(repo.readCalls, 1);
    expect(tester.takeException(), isNull);
  });
}
