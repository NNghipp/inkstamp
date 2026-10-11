import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkstamp/app/app.dart';
import 'package:inkstamp/core/config/app_environment.dart';
import 'package:inkstamp/core/observability/safe_error_reporter.dart';
import 'package:inkstamp/features/authentication/presentation/controllers/session_controller.dart';
import 'package:inkstamp/features/camera/data/repositories/local_image_processing_repository.dart';
import 'package:inkstamp/firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  final errors = SafeErrorReporter()..install();
  const environment = AppEnvironment.current;
  environment.validate();
  await initializeDateFormatting('en');
  try {
    await LocalImageProcessingRepository().cleanupExpiredDrafts();
  } on Object catch (error, stack) {
    errors.report(ErrorEvent.draftCleanup, error, stack);
  }

  const bool demoMode = kDebugMode && bool.fromEnvironment('DEMO_MODE');
  bool firebaseReady = false;
  if (!demoMode) {
    try {
      await Firebase.initializeApp(
        options: environment.isLocalDev
            ? DefaultFirebaseOptions.currentPlatform
            : environment.remoteFirebaseOptions(),
      );
      firebaseReady = true;
      if (Firebase.app().options.projectId !=
          (environment.isLocalDev ? 'inkstamp-dev' : environment.projectId)) {
        throw StateError('Firebase registration does not match environment.');
      }
    } on Object catch (error, stack) {
      errors.report(ErrorEvent.firebaseInit, error, stack);
      rethrow; // Never silently start fake repositories in a real build.
    }
  } else {
    // Explicit debug preview only.
  }
  if (firebaseReady) {
    try {
      await FirebaseAppCheck.instance.activate(
        providerAndroid: kDebugMode
            ? const AndroidDebugProvider()
            : const AndroidPlayIntegrityProvider(),
        providerApple: kDebugMode
            ? const AppleDebugProvider()
            : const AppleDeviceCheckProvider(),
      );
    } on Object catch (error, stack) {
      errors.report(ErrorEvent.appCheckInit, error, stack);
      if (!environment.isLocalDev) rethrow;
    }
  }

  runApp(
    ProviderScope(
      overrides: [firebaseInitializedProvider.overrideWithValue(firebaseReady)],
      child: const InkstampApp(),
    ),
  );
}
