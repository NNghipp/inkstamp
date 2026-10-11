import 'package:flutter/foundation.dart';

/// Fail-closed build configuration. Credentials never enter dart-defines.
class DevAuthPolicy {
  const DevAuthPolicy({
    required this.debug,
    required this.environment,
    required this.explicitlyEnabled,
  });

  static const compiledEnabled =
      kDebugMode &&
      String.fromEnvironment('APP_ENV', defaultValue: 'prod') == 'dev' &&
      bool.fromEnvironment('ENABLE_DEV_TEST_AUTH');

  static const current = DevAuthPolicy(
    debug: kDebugMode,
    environment: String.fromEnvironment('APP_ENV', defaultValue: 'prod'),
    explicitlyEnabled: bool.fromEnvironment('ENABLE_DEV_TEST_AUTH'),
  );

  final bool debug;
  final String environment;
  final bool explicitlyEnabled;

  bool get enabled => debug && environment == 'dev' && explicitlyEnabled;

  void requireAllowed({required String projectId, required String email}) {
    if (!enabled ||
        projectId != 'inkstamp-dev' ||
        !DevTestAccount.values.any((account) => account.email == email)) {
      throw StateError('DEV test authentication is unavailable.');
    }
  }
}

enum DevTestAccount {
  a('test-a@inkstamp.dev', 'Test A'),
  b('test-b@inkstamp.dev', 'Test B');

  const DevTestAccount(this.email, this.label);
  final String email;
  final String label;
}
