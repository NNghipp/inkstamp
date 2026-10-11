import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:inkstamp/app/app.dart';
import 'package:inkstamp/app/router/app_router.dart';
import 'package:inkstamp/app/router/app_routes.dart';
import 'package:inkstamp/core/config/functions_backend.dart';
import 'package:inkstamp/core/widgets/memory_photo.dart';
import 'package:inkstamp/features/archive/presentation/controllers/memory_view_controller.dart';
import 'package:inkstamp/features/authentication/domain/dev_auth_policy.dart';
import 'package:inkstamp/features/authentication/presentation/controllers/session_controller.dart';
import 'package:inkstamp/features/camera/presentation/controllers/camera_controller.dart';
import 'package:inkstamp/features/camera/presentation/screens/camera_screen.dart';
import 'package:inkstamp/features/friends/data/repositories/firebase_friend_repository.dart';
import 'package:inkstamp/features/friends/presentation/controllers/friends_controller.dart';
import 'package:inkstamp/features/inbox/presentation/controllers/inbox_controller.dart';
import 'package:inkstamp/features/inbox/presentation/screens/stamp_detail_screen.dart';
import 'package:inkstamp/features/stamps/data/repositories/cloudinary_delivery_repository.dart';
import 'package:inkstamp/features/stamps/domain/entities/stamp.dart';
import 'package:inkstamp/features/stamps/domain/repositories/stamp_repository.dart';
import 'package:inkstamp/features/stamps/presentation/controllers/post_capture_controller.dart';
import 'package:inkstamp/features/stamps/presentation/controllers/stamp_composer_controller.dart';
import 'package:inkstamp/features/stamps/presentation/controllers/stamp_timeline_controller.dart';
import 'package:inkstamp/features/stamps/presentation/screens/stamp_preview_screen.dart';
import 'package:inkstamp/firebase_options.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('real DEV backend A B workflow', (tester) async {
    final semantics = tester.ensureSemantics();
    expect(FunctionsBackend.emulatorEnabled, isTrue);
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final file = File(
      '${(await getApplicationSupportDirectory()).path}/dev-test-auth.json',
    );
    for (var i = 0; i < 60 && !await file.exists(); i++) {
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    final config =
        jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    expect(config['projectId'], 'inkstamp-dev');
    final accounts = config['accounts'] as Map<String, dynamic>;
    final a = (accounts['a'] as Map)['uid'] as String;
    final b = (accounts['b'] as Map)['uid'] as String;
    final container = ProviderContainer(
      overrides: [firebaseInitializedProvider.overrideWithValue(true)],
    );
    final session = container.read(sessionControllerProvider.notifier);
    final friends = FirebaseFriendRepository();
    final stamps = container.read(stampRepositoryProvider);
    final functions = FunctionsBackend.create();
    await initializeDateFormatting('en');
    final created = <Stamp>[];
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const InkstampApp(),
      ),
    );
    final router = container.read(appRouterProvider);
    Future<void> waitFor(bool Function() done, String label) async {
      for (var i = 0; i < 300; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (done()) {
          return;
        }
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      fail('Timed out waiting for $label');
    }

    Future<void> screenshot(String name) async {
      await tester.pump(const Duration(milliseconds: 500));
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5002/__dev/screenshot'),
        headers: {
          'X-Dev-Control': config['faultControlSecret'] as String,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'name': name}),
      );
      expect(response.statusCode, 200);
    }

    Future<void> login(DevTestAccount account) async {
      debugPrint('BACKEND_STEP LOGIN_${account.name}');
      await session.signOut();
      debugPrint('BACKEND_STEP SIGNED_OUT_${account.name}');
      await tester.pump();
      final key = account == DevTestAccount.a ? 'a' : 'b';
      await session.signInForDevelopment(
        account,
        password: (accounts[key] as Map)['password'] as String,
      );
      debugPrint('BACKEND_STEP SIGNED_IN_${account.name}');
      await tester.pump();
      expect(
        container.read(sessionControllerProvider).stage,
        SessionStage.ready,
      );
      expect(
        FirebaseAuth.instance.currentUser?.uid,
        (accounts[key] as Map)['uid'],
      );
    }

    Future<Stamp> captureAndSend(
      AudienceMode audience, {
      bool loseResponse = false,
      bool leaveCamera = true,
    }) async {
      debugPrint('BACKEND_STEP CAPTURE_START');
      await container.read(friendsControllerProvider.notifier).load();
      router.go(AppRoutes.camera);
      await waitFor(
        () =>
            container.read(cameraControllerProvider).phase == CameraPhase.ready,
        'real camera ready',
      );
      final shutter = find.byWidgetPredicate(
        (w) => w.runtimeType.toString() == '_Shutter',
      );
      expect(shutter, findsOneWidget);
      await tester.tap(shutter);
      await waitFor(
        () =>
            find.byType(StampPreviewScreen).evaluate().isNotEmpty &&
            container.read(stampComposerControllerProvider).localImagePath !=
                null,
        'capture to real Preview',
      );
      debugPrint('BACKEND_STEP PREVIEW_VISIBLE');
      final photo = container.read(stampComposerControllerProvider);
      final full = img.decodePng(
        await File(photo.localImagePath!).readAsBytes(),
      )!;
      final thumb = img.decodePng(
        await File(photo.localThumbnailPath!).readAsBytes(),
      )!;
      expect((full.width, full.height), (1440, 1440));
      expect((thumb.width, thumb.height), (512, 512));
      expect(full.exif.isEmpty && thumb.exif.isEmpty, isTrue);
      debugPrint('BACKEND_STEP PROCESSED_1440_THUMB_512_EXIF_EMPTY');
      final recipient = audience == AudienceMode.selected
          ? 'InkStamp Test B'
          : 'Tất cả';
      debugPrint('BACKEND_STEP SELECT_AUDIENCE_${audience.name}');
      final recipientChip = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == recipient &&
            widget.properties.button == true,
      );
      expect(recipientChip, findsOneWidget);
      await tester.ensureVisible(recipientChip);
      await tester.tap(recipientChip);
      await tester.pump(const Duration(milliseconds: 300));
      final draft = container.read(stampComposerControllerProvider);
      expect(draft.audience, audience);
      if (audience == AudienceMode.selected) {
        expect(draft.selectedRecipientIds, {b});
      }
      if (loseResponse) {
        expect(
          (await http.post(
            Uri.parse('http://127.0.0.1:5002/__dev/fault'),
            headers: {'X-Dev-Control': config['faultControlSecret'] as String},
          )).statusCode,
          200,
        );
        await tester.tap(find.bySemanticsLabel('Gửi ảnh'));
        await waitFor(
          () =>
              container.read(postCaptureControllerProvider) ==
              PostCapturePhase.failed,
          'injected lost response',
        );
        expect(await File(photo.localImagePath!).exists(), isTrue);
        expect(await File(photo.localThumbnailPath!).exists(), isTrue);
        expect(
          container.read(stampComposerControllerProvider).seed,
          photo.seed,
        );
      }
      await tester.tap(find.bySemanticsLabel('Gửi ảnh'));
      await waitFor(
        () =>
            (find.byType(StampPreviewScreen).evaluate().isEmpty &&
                find.byType(CameraScreen).evaluate().isNotEmpty) ||
            container.read(postCaptureControllerProvider) ==
                PostCapturePhase.failed,
        'send completion',
      );
      expect(find.byType(StampPreviewScreen), findsNothing);
      expect(find.byType(CameraScreen), findsOneWidget);
      expect(
        router.routeInformationProvider.value.uri.path,
        AppRoutes.camera,
        reason: container.read(stampTimelineControllerProvider).errorMessage,
      );
      final stamp = container
          .read(stampTimelineControllerProvider)
          .sent
          .firstWhere((s) => s.seed == photo.seed);
      created.add(stamp);
      if (loseResponse) {
        final response = await http.get(
          Uri.parse('http://127.0.0.1:5002/__dev/fault'),
          headers: {'X-Dev-Control': config['faultControlSecret'] as String},
        );
        final fault = jsonDecode(response.body) as Map<String, dynamic>;
        expect(fault['faultsConsumed'], 1);
        expect(fault['committedStampId'], stamp.id);
        expect(
          (await stamps.getSent()).where((s) => s.id == stamp.id).length,
          1,
        );
      }
      expect(
        container.read(stampComposerControllerProvider).localImagePath,
        isNull,
      );
      expect(await File(photo.localImagePath!).exists(), isFalse);
      expect(await File(photo.localThumbnailPath!).exists(), isFalse);
      await waitFor(
        () =>
            container.read(cameraControllerProvider).phase == CameraPhase.ready,
        'camera ready after Preview return',
      );
      await screenshot(
        loseResponse
            ? 'retry-camera-return'
            : audience == AudienceMode.selected
            ? 'custom-camera-return'
            : 'all-camera-return',
      );
      if (leaveCamera) {
        router.go(AppRoutes.home);
        await tester.pump(const Duration(milliseconds: 300));
      }
      return stamp;
    }

    try {
      await login(DevTestAccount.a);
      debugPrint('BACKEND_STEP RESET_CONNECTION');
      // Idempotent reset of only this dedicated A/B relationship.
      await friends.unblockUser(b);
      await login(DevTestAccount.b);
      await friends.unblockUser(a);
      await friends.removeFriend(a);
      await login(DevTestAccount.a);
      expect(await friends.search('test_a'), isEmpty);
      final target = (await friends.search('test_b')).single;
      await friends.sendRequest(target);
      await friends.sendRequest(target);
      await login(DevTestAccount.b);
      expect((await friends.getRequests()).where((f) => f.id == a).length, 1);
      await friends.respondToRequest(a, accept: false);
      await login(DevTestAccount.a);
      await friends.sendRequest(target);
      await login(DevTestAccount.b);
      await friends.respondToRequest(a, accept: true);
      await friends.respondToRequest(a, accept: true);
      await login(DevTestAccount.a);
      expect((await friends.getFriends()).where((f) => f.id == b).length, 1);
      await friends.updateCloseFriend(b, enabled: true);
      expect(
        (await friends.getFriends())
            .singleWhere((f) => f.id == b)
            .isCloseFriend,
        isTrue,
      );
      await friends.updateCloseFriend(b, enabled: false);
      expect(
        (await friends.getFriends())
            .singleWhere((f) => f.id == b)
            .isCloseFriend,
        isFalse,
      );
      debugPrint('BACKEND_CASE FRIEND_GRAPH PASS');
      final custom = await captureAndSend(AudienceMode.selected);
      debugPrint('BACKEND_CASE CUSTOM_CAPTURE_UPLOAD_PUBLISH_CLEANUP PASS');
      await login(DevTestAccount.b);
      debugPrint('BACKEND_STEP PAGINATION_START');
      final allPages = <Stamp>[];
      StampCursor? cursor;
      do {
        final page = await stamps.fetchReceivedPage(after: cursor);
        expect(page.items.length, lessThanOrEqualTo(25));
        allPages.addAll(page.items);
        cursor = page.next;
      } while (cursor != null);
      final fixtureIds = allPages
          .where((s) => s.id.startsWith('zz_backend_page_20261007_'))
          .map((s) => s.id)
          .toList();
      debugPrint('BACKEND_STEP FIXTURE_COUNT=${fixtureIds.length}');
      expect(fixtureIds.length, 126);
      expect(fixtureIds.toSet().length, 126);
      expect(fixtureIds, List.of(fixtureIds)..sort((a, b) => b.compareTo(a)));
      await expectLater(
        stamps.fetchReceivedPage(after: StampCursor(DateTime.now(), 'bad/id')),
        throwsArgumentError,
      );
      final pageTokenMedia = 'inkstamp/$a/stamp/dev-pagination-125';
      final authorizedPage = await http.post(
        Uri.parse('http://127.0.0.1:8787/v1/media/delivery-urls'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer ${await FirebaseAuth.instance.currentUser!.getIdToken()}',
        },
        body: jsonEncode({
          'publicIds': [pageTokenMedia],
        }),
      );
      expect(authorizedPage.statusCode, 200);
      debugPrint(
        'BACKEND_CASE PAGINATION_126_TIES_GATEWAY_AFTER_100 PASS (trusted fixtures, not publishes)',
      );
      final delivery = (await stamps.fetchReceivedPage()).items.singleWhere(
        (s) => s.id == custom.id,
      );
      expect(delivery.senderId, a);
      expect(delivery.isSeen, isFalse);
      expect(await stamps.getById(custom.id), isNotNull);
      router.go(AppRoutes.inbox);
      await waitFor(
        () => container
            .read(inboxControllerProvider)
            .items
            .any((s) => s.id == custom.id),
        'real Inbox',
      );
      await screenshot('received-inbox');
      await tester.tap(find.text('InkStamp Test A').first);
      await waitFor(
        () => container.read(stampDetailProvider(custom.id)).hasValue,
        'real Detail lookup',
      );
      expect(
        tester
            .widget<StampDetailScreen>(find.byType(StampDetailScreen))
            .stampId,
        custom.id,
      );
      await waitFor(
        () => container
            .read(inboxControllerProvider)
            .items
            .any((s) => s.id == custom.id && s.isSeen),
        'persisted read',
      );
      await screenshot('received-detail');
      expect((await stamps.getById(custom.id))?.isSeen, isTrue);
      final urls = container.read(cloudinaryDeliveryRepositoryProvider);
      final url = await urls.resolve(custom.cloudinaryPublicId!);
      // Signed URLs/tokens must never appear in assertion failure output.
      final media = await http.get(Uri.parse(url));
      expect(media.statusCode, 200);
      expect(media.bodyBytes.length, greaterThan(0));
      final cloudName = Uri.parse(url).pathSegments[1];
      final unsigned = await http.get(
        Uri.parse(
          'https://res.cloudinary.com/$cloudName/image/authenticated/${custom.cloudinaryPublicId}.jpg',
        ),
      );
      expect(unsigned.statusCode, isNot(200));
      debugPrint('BACKEND_CASE INBOX_UNREAD_READ_DETAIL_MEDIA PASS');
      final now = DateTime.now();
      expect(now.timeZoneOffset.inMinutes, 420);
      final month = await stamps.fetchMonth(
        DateTime(now.year, now.month),
        DateTime(now.year, now.month + 1),
      );
      expect(month.where((s) => s.id == custom.id).length, 1);
      final local = month
          .singleWhere((s) => s.id == custom.id)
          .createdAt
          .toLocal();
      expect(
        (local.year, local.month, local.day),
        (now.year, now.month, now.day),
      );
      router.go(AppRoutes.calendar);
      await waitFor(
        () => container
            .read(calendarMonthProvider(DateTime(now.year, now.month)))
            .hasValue,
        'real Calendar',
      );
      final dayLabel =
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
      await tester.tap(find.bySemanticsLabel(RegExp('^$dayLabel,')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        container.read(dayMemoriesProvider).any((s) => s.id == custom.id),
        isTrue,
      );
      await screenshot('calendar-selected-day');
      final calendarPhoto = find
          .byWidgetPredicate(
            (widget) =>
                widget is MemoryPhoto &&
                widget.publicId == custom.cloudinaryThumbnailPublicId,
          )
          .last;
      await Scrollable.ensureVisible(
        tester.element(calendarPhoto),
        alignment: .3,
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(calendarPhoto);
      await waitFor(
        () => find.byType(StampDetailScreen).evaluate().isNotEmpty,
        'Calendar shared Detail',
      );
      expect(
        tester
            .widget<StampDetailScreen>(find.byType(StampDetailScreen))
            .stampId,
        custom.id,
      );
      router.go(AppRoutes.home);
      await tester.pump(const Duration(milliseconds: 300));
      debugPrint(
        'BACKEND_CASE CALENDAR_LOCAL_DATE_SELECTED_DAY_SHARED_DETAIL PASS',
      );
      await expectLater(
        functions.httpsCallable('deleteStampForEveryone').call<Object?>({
          'stampId': custom.id,
        }),
        throwsA(
          isA<FirebaseFunctionsException>().having(
            (error) => error.code,
            'code',
            'permission-denied',
          ),
        ),
      );
      await login(DevTestAccount.a);
      final all = await captureAndSend(
        AudienceMode.allFriends,
        leaveCamera: false,
      );
      final retry = await captureAndSend(
        AudienceMode.selected,
        loseResponse: true,
      );
      await login(DevTestAccount.b);
      expect(
        (await stamps.fetchReceivedPage()).items
            .where((s) => s.id == all.id)
            .length,
        1,
      );
      expect(
        (await stamps.fetchReceivedPage()).items
            .where((s) => s.id == retry.id)
            .length,
        1,
      );
      debugPrint('BACKEND_CASE ALL_ONE_DELIVERY PASS');
      debugPrint(
        'BACKEND_CASE RETRY_REAL_COMMIT_LOST_RESPONSE_ONE_STAMP_DELIVERY PASS',
      );
      await login(DevTestAccount.a);
      final revoke = await functions
          .httpsCallable('deleteStampForEveryone')
          .call<Map<String, dynamic>>({'stampId': custom.id});
      expect(revoke.data['mediaDeleted'], isTrue);
      final repeatRevoke = await functions
          .httpsCallable('deleteStampForEveryone')
          .call<Map<String, dynamic>>({'stampId': custom.id});
      expect(repeatRevoke.data['mediaDeleted'], isTrue);
      final ownerRevoked = await http.post(
        Uri.parse('http://127.0.0.1:8787/v1/media/delivery-urls'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer ${await FirebaseAuth.instance.currentUser!.getIdToken()}',
        },
        body: jsonEncode({
          'publicIds': [custom.cloudinaryPublicId],
        }),
      );
      expect(ownerRevoked.statusCode, 403);
      await login(DevTestAccount.b);
      expect(await stamps.getById(custom.id), isNull);
      expect(
        (await stamps.fetchReceivedPage()).items.where(
          (s) => s.id == custom.id,
        ),
        isEmpty,
      );
      expect(
        (await stamps.fetchMonth(
          DateTime(now.year, now.month),
          DateTime(now.year, now.month + 1),
        )).where((s) => s.id == custom.id),
        isEmpty,
      );
      // Fresh resolver avoids mistaking a cached signed URL for new authorization.
      container.invalidate(cloudinaryDeliveryRepositoryProvider);
      await expectLater(
        container
            .read(cloudinaryDeliveryRepositoryProvider)
            .resolve(custom.cloudinaryPublicId!),
        throwsA(anything),
      );
      final oldMedia = await http.get(Uri.parse(url));
      expect(oldMedia.statusCode, isNot(200));
      router.go(AppRoutes.stamp(custom.id));
      await waitFor(
        () => find.text('Stamp không còn khả dụng.').evaluate().isNotEmpty,
        'revoked Detail unavailable UI',
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        find.descendant(
          of: find.byType(StampDetailScreen),
          matching: find.text('InkStamp Test A'),
        ),
        findsNothing,
      );
      await screenshot('revoked-detail');
      expect(
        tester.takeException() == null,
        isTrue,
        reason: 'Revoked screen must not crash.',
      );
      router.go(AppRoutes.home);
      await tester.pump(const Duration(milliseconds: 300));
      debugPrint(
        'BACKEND_CASE REVOKE_MEDIA_DELETED_UNAVAILABLE_UI PASS; OLD_URL_HTTP=${oldMedia.statusCode}',
      );
      await login(DevTestAccount.a);
      await friends.blockUser(b);
      expect(await friends.search('test_b'), isEmpty);
      expect((await friends.getFriends()).where((f) => f.id == b), isEmpty);
      await login(DevTestAccount.b);
      await friends.unblockUser(a);
      await expectLater(
        friends.blockUser(a),
        throwsA(
          isA<FirebaseFunctionsException>().having(
            (error) => error.code,
            'code',
            'permission-denied',
          ),
        ),
      );
      expect(await stamps.getById(all.id), isNull);
      expect(
        (await stamps.fetchReceivedPage()).items.where((s) => s.id == all.id),
        isEmpty,
      );
      await expectLater(
        functions.httpsCallable('sendFriendRequest').call<Object?>({
          'username': 'test_a',
        }),
        throwsA(
          isA<FirebaseFunctionsException>().having(
            (error) => error.code,
            'code',
            'permission-denied',
          ),
        ),
      );
      await login(DevTestAccount.a);
      await friends.unblockUser(b);
      expect((await friends.getFriends()).where((f) => f.id == b), isEmpty);
      await login(DevTestAccount.b);
      expect(await stamps.getById(all.id), isNull);
      debugPrint('BACKEND_CASE BLOCK_UNBLOCK_NO_RESTORE PASS');
      // Verify the real delivery identity exists in recipient's own cloud DB.
      expect(
        (await FirebaseFirestore.instance
                .doc('users/$b/deliveries/${all.id}')
                .get())
            .get('status'),
        'revoked',
      );
    } on FirebaseException catch (error) {
      debugPrint('BACKEND_CASE FIREBASE_FAILURE ${error.plugin}/${error.code}');
      rethrow;
    } on Object catch (error) {
      debugPrint('BACKEND_CASE FAILURE_TYPE ${error.runtimeType}');
      if (error is FlutterError) {
        var message = error.toString();
        for (final account in accounts.values) {
          message = message.replaceAll(
            (account as Map)['password'] as String,
            '[removed]',
          );
        }
        message = message.replaceAll(
          RegExp(r'(?:https?|file)://\S+'),
          '[URL removed]',
        );
        for (final line in message.split('\n').take(8)) {
          if (!RegExp(
            'token|secret|password|Bearer',
            caseSensitive: false,
          ).hasMatch(line)) {
            debugPrint('BACKEND_CASE FAILURE_DETAIL $line');
          }
        }
      }
      rethrow;
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await session.signOut();
      container.dispose();
      semantics.dispose();
      if (await file.exists()) await file.delete();
    }
  }, timeout: const Timeout(Duration(minutes: 12)));
}
