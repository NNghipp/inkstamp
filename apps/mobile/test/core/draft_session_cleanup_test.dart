import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkstamp/features/authentication/domain/entities/app_user.dart';
import 'package:inkstamp/features/authentication/presentation/controllers/session_controller.dart';
import 'package:inkstamp/features/stamps/presentation/controllers/stamp_composer_controller.dart';
import '../features/authentication/dev_auth_test.dart' show StreamAuth;

void main() {
  test(
    'account swap deletes only old draft files, not the new account draft',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'inkstamp-session-test-',
      );
      addTearDown(() async {
        // Account-scope disposal also cleans files asynchronously. Tolerate an
        // already-absent temporary directory, but propagate other I/O errors.
        try {
          if (await directory.exists()) await directory.delete(recursive: true);
        } on PathNotFoundException {
          // Cleanup is idempotent; all privacy assertions ran before teardown.
        }
      });
      final oldFull = File('${directory.path}/old-full.jpg');
      final oldThumb = File('${directory.path}/old-thumb.jpg');
      final newFull = File('${directory.path}/new-full.jpg');
      for (final file in [oldFull, oldThumb, newFull]) {
        await file.writeAsString('unit-only');
      }
      final auth = StreamAuth();
      final container = ProviderContainer(
        overrides: [authenticationRepositoryProvider.overrideWithValue(auth)],
      );
      addTearDown(container.dispose);
      addTearDown(auth.close);
      final composer = container.read(stampComposerControllerProvider.notifier);
      composer.capture(
        localImagePath: oldFull.path,
        localThumbnailPath: oldThumb.path,
      );
      auth.events.add(
        const AppUser(
          id: 'B',
          username: 'unit_b',
          displayName: 'B',
          onboardingComplete: true,
          onboardingStep: UserOnboardingStep.complete,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(stampComposerControllerProvider).localImagePath,
        isNull,
      );
      composer.capture(
        localImagePath: newFull.path,
        localThumbnailPath: newFull.path,
      );
      for (
        var i = 0;
        i < 40 && (await oldFull.exists() || await oldThumb.exists());
        i++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(await oldFull.exists(), isFalse);
      expect(await oldThumb.exists(), isFalse);
      expect(await newFull.exists(), isTrue);
    },
  );
}
