import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as image;
import 'package:inkstamp/app/app.dart';
import 'package:inkstamp/app/router/app_router.dart';
import 'package:inkstamp/app/router/app_routes.dart';
import 'package:inkstamp/core/config/functions_backend.dart';
import 'package:inkstamp/core/images/stamp_image_format.dart';
import 'package:inkstamp/core/widgets/memory_photo.dart';
import 'package:inkstamp/features/archive/presentation/controllers/memory_view_controller.dart';
import 'package:inkstamp/features/archive/presentation/screens/calendar_screen.dart';
import 'package:inkstamp/features/authentication/domain/dev_auth_policy.dart';
import 'package:inkstamp/features/authentication/presentation/controllers/session_controller.dart';
import 'package:inkstamp/features/camera/data/repositories/dev_asset_capture_source.dart';
import 'package:inkstamp/features/camera/presentation/controllers/camera_controller.dart';
import 'package:inkstamp/features/friends/data/repositories/firebase_friend_repository.dart';
import 'package:inkstamp/features/friends/presentation/controllers/friends_controller.dart';
import 'package:inkstamp/features/home/presentation/screens/home_screen.dart';
import 'package:inkstamp/features/inbox/presentation/controllers/inbox_controller.dart';
import 'package:inkstamp/features/inbox/presentation/screens/inbox_screen.dart';
import 'package:inkstamp/features/inbox/presentation/screens/stamp_detail_screen.dart';
import 'package:inkstamp/features/settings/presentation/screens/settings_screen.dart';
import 'package:inkstamp/features/stamps/data/repositories/cloudinary_delivery_repository.dart';
import 'package:inkstamp/features/stamps/domain/entities/stamp.dart';
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
  testWidgets('real DEV backend photo presentation', (tester) async {
    final semantics = tester.ensureSemantics();
    expect(FunctionsBackend.emulatorEnabled && devAssetCaptureEnabled, isTrue);
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
    final accounts = config['accounts'] as Map;
    final a = (accounts['a'] as Map)['uid'] as String;
    final b = (accounts['b'] as Map)['uid'] as String;
    final container = ProviderContainer(
      overrides: [firebaseInitializedProvider.overrideWithValue(true)],
    );
    final session = container.read(sessionControllerProvider.notifier);
    final friends = FirebaseFriendRepository();
    await initializeDateFormatting('en');
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const InkstampApp(),
      ),
    );
    final router = container.read(appRouterProvider);
    Future<void> waitFor(bool Function() done, String label) async {
      for (var i = 0; i < 600; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (done()) return;
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      fail('Timed out waiting for $label');
    }

    Future<void> login(DevTestAccount account) async {
      await session.signOut();
      await tester.pump();
      await session.signInForDevelopment(
        account,
        password: (accounts[account.name] as Map)['password'] as String,
      );
      await tester.pump();
      expect(
        container.read(sessionControllerProvider).stage,
        SessionStage.ready,
      );
      await container.read(stampTimelineControllerProvider.notifier).load();
    }

    final created = <Stamp>[];
    const stampEdges = bool.fromEnvironment('STAMP_EDGES_REVIEW');
    Future<void> decodedPhotos(String name) async {
      final screen = name.startsWith('detail')
          ? find.byType(StampDetailScreen)
          : name == 'history'
          ? find.byType(HomeScreen)
          : name == 'profile'
          ? find.byType(SettingsScreen)
          : name == 'calendar'
          ? find.byType(CalendarScreen)
          : find.byType(InboxScreen);
      await waitFor(
        () => screen.evaluate().length == 1,
        'current $name screen',
      );
      final sampleIds = {
        for (final stamp in created) stamp.cloudinaryPublicId,
        for (final stamp in created) stamp.cloudinaryThumbnailPublicId,
      };
      final photoWidgets = find.descendant(
        of: screen,
        matching: find.byType(MemoryPhoto),
      );
      await waitFor(
        () => photoWidgets
            .evaluate()
            .where(
              (e) => sampleIds.contains((e.widget as MemoryPhoto).publicId),
            )
            .every(
              (e) => container
                  .read(
                    mediaDeliveryUrlProvider(
                      (e.widget as MemoryPhoto).publicId!,
                    ),
                  )
                  .hasValue,
            ),
        'sample URL resolution',
      );
      final images = find.descendant(of: screen, matching: find.byType(Image));
      await waitFor(
        () => images.evaluate().any(
          (e) => (e.widget as Image).image is NetworkImage,
        ),
        'network image widgets',
      );
      final listeners = <(ImageStream, ImageStreamListener)>[];
      var loaded = 0;
      var failed = false;
      for (final element in images.evaluate()) {
        final widget = element.widget as Image;
        if (widget.image is! NetworkImage) continue;
        final stream = widget.image.resolve(
          createLocalImageConfiguration(element),
        );
        final listener = ImageStreamListener(
          (_, _) => loaded++,
          onError: (_, _) => failed = true,
        );
        listeners.add((stream, listener));
        stream.addListener(listener);
      }
      try {
        await waitFor(
          () => failed || loaded >= listeners.length,
          'fully decoded photos',
        );
        expect(
          failed,
          isFalse,
          reason:
              'Do not capture loading or failed images as completed evidence.',
        );
      } finally {
        for (final pair in listeners) {
          pair.$1.removeListener(pair.$2);
        }
      }
      await tester.pump(const Duration(milliseconds: 500));
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 100));
    }

    Future<void> screenshot(String name, {bool networkPhotos = true}) async {
      if (networkPhotos) await decodedPhotos(name);
      if (!networkPhotos) {
        await tester.pump(const Duration(seconds: 1));
        await Future<void>.delayed(const Duration(seconds: 1));
        await tester.pump();
      }
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5002/__dev/screenshot'),
        headers: {
          'X-Dev-Control': config['faultControlSecret'] as String,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'name': name}),
      );
      expect(response.statusCode, 200);
      debugPrint('BACKEND_STEP PHOTO_SCREEN_$name');
    }

    try {
      await login(DevTestAccount.a);
      // Normal friendship API only if missing; no database fixtures/reset/block/revoke.
      if (!(await friends.getFriends()).any((f) => f.id == b)) {
        await friends.sendRequest((await friends.search('test_b')).single);
        await login(DevTestAccount.b);
        await friends.respondToRequest(a, accept: true);
        await login(DevTestAccount.a);
      }
      await container.read(friendsControllerProvider.notifier).load();
      if (!const bool.fromEnvironment('PHOTO_REVIEW_REUSE')) {
        final assets = await container
            .read(devAssetCaptureSourceProvider)
            .listImages();
        expect(assets, isNotEmpty);
        for (final asset in assets) {
          router.go(AppRoutes.camera);
          await waitFor(
            () =>
                container.read(cameraControllerProvider).phase ==
                CameraPhase.ready,
            'native camera ready',
          );
          await tester.tap(find.byTooltip('DEV sample capture'));
          await tester.pump(const Duration(milliseconds: 500));
          await tester.tap(find.text(asset.split('/').last));
          await waitFor(
            () => find.byType(StampPreviewScreen).evaluate().isNotEmpty,
            'sample Preview',
          );
          final draft = container.read(stampComposerControllerProvider);
          final full = image.decodePng(
            await File(draft.localImagePath!).readAsBytes(),
          )!;
          final thumb = image.decodePng(
            await File(draft.localThumbnailPath!).readAsBytes(),
          )!;
          expect((full.width, full.height), (1440, 1440));
          expect((thumb.width, thumb.height), (512, 512));
          expect(full.exif.isEmpty && thumb.exif.isEmpty, isTrue);
          expect(full.getPixel(0, 0).a, 0);
          expect(thumb.getPixel(0, 0).a, 0);
          await screenshot(
            'preview-${asset.split('/').last.split('.').first}',
            networkPhotos: false,
          );
          final chip = find.byWidgetPredicate(
            (w) =>
                w is Semantics &&
                w.properties.label == 'InkStamp Test B' &&
                w.properties.button == true,
          );
          await tester.ensureVisible(chip);
          await tester.tap(chip);
          await tester.pump();
          expect(
            container
                .read(stampComposerControllerProvider)
                .selectedRecipientIds,
            {b},
          );
          await tester.tap(find.bySemanticsLabel('Gửi ảnh'));
          await waitFor(
            () =>
                find.byType(StampPreviewScreen).evaluate().isEmpty ||
                container.read(postCaptureControllerProvider) ==
                    PostCapturePhase.failed,
            'real publish',
          );
          expect(find.byType(StampPreviewScreen), findsNothing);
          final stamp = container
              .read(stampTimelineControllerProvider)
              .sent
              .singleWhere((s) => s.seed == draft.seed);
          created.add(stamp);
          debugPrint(
            'BACKEND_STEP PHOTO_PUBLISHED_${asset.split('/').last}_${stamp.id}',
          );
        }
        // Native shutter uses the same processor. Stamp-edge review also publishes it.
        await waitFor(
          () =>
              container.read(cameraControllerProvider).phase ==
              CameraPhase.ready,
          'native camera return',
        );
        await tester.tap(find.bySemanticsLabel('Chụp ảnh'));
        await waitFor(
          () => find.byType(StampPreviewScreen).evaluate().isNotEmpty,
          'native capture Preview',
        );
        await screenshot('native-camera-preview', networkPhotos: false);
        if (stampEdges) {
          final draft = container.read(stampComposerControllerProvider);
          final full = image.decodePng(
            await File(draft.localImagePath!).readAsBytes(),
          )!;
          final thumb = image.decodePng(
            await File(draft.localThumbnailPath!).readAsBytes(),
          )!;
          expect((full.width, full.height), (1440, 1440));
          expect((thumb.width, thumb.height), (512, 512));
          expect(full.getPixel(0, 0).a, 0);
          expect(thumb.getPixel(0, 0).a, 0);
          final chip = find.byWidgetPredicate(
            (w) =>
                w is Semantics &&
                w.properties.label == 'InkStamp Test B' &&
                w.properties.button == true,
          );
          await tester.ensureVisible(chip);
          await tester.pump();
          await tester.tap(chip);
          await tester.pump();
          await tester.tap(find.bySemanticsLabel('Gửi ảnh'));
          await waitFor(
            () =>
                find.byType(StampPreviewScreen).evaluate().isEmpty ||
                container.read(postCaptureControllerProvider) ==
                    PostCapturePhase.failed,
            'native stamp publish',
          );
          expect(find.byType(StampPreviewScreen), findsNothing);
          final stamp = container
              .read(stampTimelineControllerProvider)
              .sent
              .singleWhere((s) => s.seed == draft.seed);
          created.add(stamp);
          debugPrint('BACKEND_STEP NATIVE_STAMP_PUBLISHED_${stamp.id}');
        } else {
          await tester.tap(find.bySemanticsLabel('Hủy ảnh'));
        }
        await waitFor(
          () => find.byType(StampPreviewScreen).evaluate().isEmpty,
          'discard native capture',
        );
      } else {
        created.addAll(
          container
              .read(stampTimelineControllerProvider)
              .sent
              .take(stampEdges ? 5 : 4),
        );
        expect(created.length, stampEdges ? 5 : 4);
        for (final stamp in created) {
          debugPrint('BACKEND_STEP PHOTO_REUSED_${stamp.id}');
        }
        if (stampEdges) {
          // Verify the current build's Preview without publishing duplicate memories.
          router.go(AppRoutes.camera);
          await waitFor(
            () =>
                container.read(cameraControllerProvider).phase ==
                CameraPhase.ready,
            'reuse native camera ready',
          );
          final assets = await container
              .read(devAssetCaptureSourceProvider)
              .listImages();
          await tester.tap(find.byTooltip('DEV sample capture'));
          await tester.pump(const Duration(milliseconds: 500));
          await tester.tap(find.text(assets.first.split('/').last));
          await waitFor(
            () => find.byType(StampPreviewScreen).evaluate().isNotEmpty,
            'current stamp Preview',
          );
          await screenshot('preview-current', networkPhotos: false);
          await tester.tap(find.bySemanticsLabel('Hủy ảnh'));
          await waitFor(
            () => find.byType(StampPreviewScreen).evaluate().isEmpty,
            'current draft discard',
          );
        }
      }
      if (stampEdges) {
        for (final stamp in created) {
          final delivery = container.read(cloudinaryDeliveryRepositoryProvider);
          for (final pair in [
            (stamp.cloudinaryPublicId!, 1440),
            (stamp.cloudinaryThumbnailPublicId!, 512),
          ]) {
            expect(isProcessedStampImage(pair.$1), isTrue);
            final url = await delivery.resolve(pair.$1);
            final response = await http
                .get(Uri.parse(url))
                .timeout(const Duration(seconds: 60));
            expect(response.statusCode, 200);
            expect(response.bodyBytes.take(8), [
              137,
              80,
              78,
              71,
              13,
              10,
              26,
              10,
            ]);
            // Native decoder is the same renderer used by Image; avoid costly
            // repeated pure-Dart full-image decode in a debug emulator harness.
            final codec = await ui.instantiateImageCodec(response.bodyBytes);
            final frame = await codec.getNextFrame();
            try {
              final png = frame.image;
              expect((png.width, png.height), (pair.$2, pair.$2));
              final pixels = (await png.toByteData(
                format: ui.ImageByteFormat.rawRgba,
              ))!;
              int alpha(int x, int y) =>
                  pixels.getUint8((y * png.width + x) * 4 + 3);
              final n = pair.$2;
              final notch = (n / 24).floor();
              expect(alpha(0, 0), 0);
              expect(alpha(notch, 0), 0);
              expect(alpha(notch, n - 1), 0);
              expect(alpha(0, notch), 0);
              expect(alpha(n - 1, notch), 0);
              expect(alpha(n ~/ 2, n ~/ 2), 255);
            } finally {
              frame.image.dispose();
              codec.dispose();
            }
          }
          debugPrint('BACKEND_STEP DELIVERED_STAMP_ALPHA_${stamp.id}');
        }
        debugPrint('BACKEND_CASE DELIVERED_PNG_ALPHA_PASS_${created.length}');
        final legacy = container
            .read(stampTimelineControllerProvider)
            .sent
            .firstWhere((s) => !isProcessedStampImage(s.cloudinaryPublicId));
        router.go(AppRoutes.stamp(legacy.id));
        await tester.pump(const Duration(seconds: 1));
        await screenshot('detail-legacy');
      }
      router.go(AppRoutes.home);
      await tester.pump(const Duration(seconds: 1));
      await screenshot('history');
      router.go(AppRoutes.profile);
      await tester.pump(const Duration(seconds: 1));
      await screenshot('profile');
      for (var i = 0; i < created.length; i++) {
        router.go(AppRoutes.stamp(created[i].id));
        await tester.pump(const Duration(seconds: 1));
        await screenshot('detail-$i');
      }
      router.go(AppRoutes.calendar);
      container
          .read(calendarSelectionProvider.notifier)
          .select(created.last.createdAt.toLocal());
      await waitFor(
        () => container
            .read(dayMemoriesProvider)
            .any((s) => s.id == created.last.id),
        'Calendar actual memory',
      );
      await screenshot('calendar');
      await login(DevTestAccount.b);
      router.go(AppRoutes.inbox);
      await container.read(inboxControllerProvider.notifier).refresh();
      await waitFor(
        () => created.every(
          (s) => container
              .read(inboxControllerProvider)
              .items
              .any((r) => r.id == s.id),
        ),
        'B actual deliveries',
      );
      await screenshot('inbox-b');
      router.go(AppRoutes.stamp(created.last.id));
      await tester.pump(const Duration(seconds: 1));
      await screenshot('detail-b');
      debugPrint('BACKEND_CASE PHOTO_PRESENTATION_PASS_${created.length}');
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      container.dispose();
      semantics.dispose();
    }
  });
}
