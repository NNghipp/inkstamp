import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:inkstamp/core/config/app_environment.dart';

/// Local transport is compile-time disabled outside debug DEV builds.
class FunctionsBackend {
  static const emulatorEnabled =
      kDebugMode &&
      String.fromEnvironment('APP_ENV', defaultValue: 'prod') == 'dev' &&
      String.fromEnvironment('BACKEND_MODE') == 'functions_emulator';

  static Future<String?> mediaAppCheckToken() async {
    if (emulatorEnabled) {
      if (Firebase.app().options.projectId != 'inkstamp-dev') {
        throw StateError(
          'Local attestation mode is restricted to inkstamp-dev.',
        );
      }
      return null;
    }
    return FirebaseAppCheck.instance.getToken();
  }

  static FirebaseFunctions create() {
    if (!emulatorEnabled) {
      const environment = AppEnvironment.current;
      return FirebaseFunctions.instanceFor(
        region: environment.isLocalDev
            ? 'asia-southeast1'
            : environment.functionsRegion,
      );
    }
    final app = Firebase.app();
    if (app.options.projectId != 'inkstamp-dev') {
      throw StateError('Local backend is restricted to inkstamp-dev.');
    }
    // adb reverse tcp:5001 tcp:5001; no public listener or tunnel required.
    final functions = FirebaseFunctions.instanceFor(
      app: app,
      region: 'asia-southeast1',
    );
    const port = int.fromEnvironment('DEV_FUNCTIONS_PORT', defaultValue: 5001);
    if (port != 5001 && port != 5002) {
      throw StateError('Unsupported local backend port.');
    }
    functions.useFunctionsEmulator(
      '127.0.0.1',
      port,
      automaticHostMapping: false,
    );
    return functions;
  }
}
