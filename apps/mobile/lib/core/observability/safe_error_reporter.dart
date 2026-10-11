import 'dart:convert';

import 'package:flutter/foundation.dart';

enum ErrorEvent {
  draftCleanup,
  firebaseInit,
  appCheckInit,
  flutterFramework,
  uncaughtAsync,
  cameraCleanup,
}

/// Allowlist telemetry, not redaction by regex. Never serialize an exception,
/// stack, URL, user ID, request, or arbitrary message into platform logs.
class SafeErrorReporter {
  SafeErrorReporter({void Function(String)? sink}) : _sink = sink ?? debugPrint;
  final void Function(String) _sink;
  void report(ErrorEvent event, Object error, StackTrace stack) {
    _sink(encode(event));
  }

  static String encode(ErrorEvent event) =>
      jsonEncode({'event': event.name, 'severity': 'error'});
  void install() {
    FlutterError.onError = (details) => report(
      ErrorEvent.flutterFramework,
      details.exception,
      details.stack ?? StackTrace.empty,
    );
    PlatformDispatcher.instance.onError = (error, stack) {
      report(ErrorEvent.uncaughtAsync, error, stack);
      return true;
    };
  }
}
