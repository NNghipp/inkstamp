import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:inkstamp/features/authentication/domain/dev_auth_policy.dart';
import 'package:inkstamp/features/authentication/presentation/controllers/session_controller.dart';
import 'package:inkstamp/features/camera/data/repositories/camera_plugin_repository.dart';
import 'package:inkstamp/features/camera/data/repositories/local_image_processing_repository.dart';
import 'package:inkstamp/firebase_options.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('real DEV Firebase A logout B profile/session smoke', (
    tester,
  ) async {
    expect(DevAuthPolicy.current.enabled, isTrue);
    final app = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    expect(app.options.projectId, 'inkstamp-dev');
    final support = await getApplicationSupportDirectory();
    final file = File('${support.path}/dev-test-auth.json');
    for (var attempt = 0; attempt < 60 && !await file.exists(); attempt++) {
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    expect(
      await file.exists(),
      isTrue,
      reason: 'Use the secure local smoke runner.',
    );
    final config =
        jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    expect(config['projectId'], 'inkstamp-dev');
    final accounts = config['accounts'] as Map<String, dynamic>;
    final container = ProviderContainer(
      overrides: [firebaseInitializedProvider.overrideWithValue(true)],
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Text('DEV Firebase authentication smoke')),
      ),
    );
    final controller = container.read(sessionControllerProvider.notifier);
    try {
      for (final account in DevTestAccount.values) {
        final key = account == DevTestAccount.a ? 'a' : 'b';
        final credentials = accounts[key] as Map<String, dynamic>;
        // Never assert/print a password or token, even on failure.
        await controller.signInForDevelopment(
          account,
          password: credentials['password'] as String,
        );
        final session = container.read(sessionControllerProvider);
        expect(session.stage, SessionStage.ready);
        expect(session.user?.id, credentials['uid']);
        expect(session.user?.username, 'test_$key');
        expect(session.user?.displayName, 'InkStamp Test ${key.toUpperCase()}');
        expect(FirebaseAuth.instance.currentUser?.uid, credentials['uid']);
        if (account == DevTestAccount.a) {
          final camera = CameraPluginRepository();
          final processor = LocalImageProcessingRepository();
          try {
            await camera.initialize();
            for (var lens = 0; lens < 2; lens++) {
              final raw = await camera.captureRawImage();
              final processed = await processor.process(raw);
              try {
                final full = img.decodePng(
                  await File(processed.imagePath).readAsBytes(),
                )!;
                final thumb = img.decodePng(
                  await File(processed.thumbnailPath).readAsBytes(),
                )!;
                expect((full.width, full.height), (1440, 1440));
                expect((thumb.width, thumb.height), (512, 512));
                expect(full.exif.isEmpty && thumb.exif.isEmpty, isTrue);
                expect(await File(raw).exists(), isFalse);
              } finally {
                await processor.deleteFiles([
                  processed.imagePath,
                  processed.thumbnailPath,
                ]);
              }
              if (lens == 0) await camera.switchLens();
            }
          } finally {
            await camera.dispose();
          }
        }
        await controller.signOut();
        expect(container.read(sessionControllerProvider).user, isNull);
        expect(FirebaseAuth.instance.currentUser, isNull);
      }
    } finally {
      await FirebaseAuth.instance.signOut();
      container.dispose();
      if (await file.exists()) await file.delete();
    }
  });
}
