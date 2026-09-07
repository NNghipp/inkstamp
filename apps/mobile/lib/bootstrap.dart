import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkstamp/app/app.dart';
import 'package:inkstamp/features/authentication/presentation/controllers/session_controller.dart';
import 'package:inkstamp/firebase_options.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool firebaseReady = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseReady = true;
  } on Object catch (e) {
    // Firebase is not configured (e.g. missing google-services.json).
    // The app will run in demo mode.
    debugPrint('Firebase init skipped â€“ running in demo mode: $e');
  }

  runApp(
    ProviderScope(
      overrides: [firebaseInitializedProvider.overrideWithValue(firebaseReady)],
      child: const InkstampApp(),
    ),
  );
}
