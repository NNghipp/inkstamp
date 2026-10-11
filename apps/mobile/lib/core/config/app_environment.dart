import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Public configuration only. Signing keys and Cloudinary secrets never belong here.
class AppEnvironment {
  const AppEnvironment({
    required this.name,
    required this.debug,
    required this.gateway,
    required this.projectId,
    required this.functionsRegion,
  });

  static const current = AppEnvironment(
    name: String.fromEnvironment('APP_ENV', defaultValue: 'prod'),
    debug: kDebugMode,
    gateway: String.fromEnvironment('MEDIA_GATEWAY_BASE_URL'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
    functionsRegion: String.fromEnvironment('FUNCTIONS_REGION'),
  );
  final String name;
  final bool debug;
  final String gateway;
  final String projectId;
  final String functionsRegion;
  bool get isLocalDev => debug && name == 'dev';
  String get gatewayBaseUrl =>
      gateway.isEmpty && isLocalDev ? 'http://127.0.0.1:8787' : gateway;

  void validate() {
    if (!['dev', 'staging', 'prod'].contains(name) ||
        (!debug && name != 'prod')) {
      throw StateError('Unsupported build environment.');
    }
    final uri = Uri.tryParse(gatewayBaseUrl);
    final loopback = uri?.host == '127.0.0.1' || uri?.host == 'localhost';
    if (uri == null ||
        !uri.hasAuthority ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.scheme != 'https' &&
            !(isLocalDev && loopback && uri.scheme == 'http')) ||
        (!isLocalDev && loopback)) {
      throw StateError('A secure media gateway must be configured.');
    }
    if (!isLocalDev &&
        (projectId.isEmpty ||
            projectId == 'inkstamp-dev' ||
            functionsRegion.isEmpty)) {
      throw StateError(
        'Isolated Firebase project and Functions region required.',
      );
    }
  }

  FirebaseOptions remoteFirebaseOptions() {
    validate();
    const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
    const appId = String.fromEnvironment('FIREBASE_APP_ID');
    const senderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
    if ([apiKey, appId, senderId].any((v) => v.isEmpty)) {
      throw StateError('Firebase app registration must be configured.');
    }
    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: senderId,
      projectId: projectId,
    );
  }
}
