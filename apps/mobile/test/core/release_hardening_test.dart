import 'package:flutter_test/flutter_test.dart';
import 'package:inkstamp/core/config/app_environment.dart';
import 'package:inkstamp/core/observability/safe_error_reporter.dart';
import 'package:inkstamp/features/authentication/domain/dev_auth_policy.dart';

void main() {
  AppEnvironment env({
    bool debug = false,
    String name = 'prod',
    String gateway = 'https://media.example.com',
    String project = 'portfolio-prod',
  }) => AppEnvironment(
    name: name,
    debug: debug,
    gateway: gateway,
    projectId: project,
    functionsRegion: 'asia-southeast1',
  );
  test('release and profile cannot activate DEV auth even with flags', () {
    for (final name in ['dev', 'prod', 'staging']) {
      expect(
        DevAuthPolicy(
          debug: false,
          environment: name,
          explicitlyEnabled: true,
        ).enabled,
        isFalse,
      );
    }
  });
  test('production rejects absent, cleartext and loopback endpoints', () {
    for (final gateway in [
      '',
      'http://media.example.com',
      'https://localhost',
      'http://127.0.0.1:8787',
      'https://media.example.com?token=private',
      'https://user:password@media.example.com',
    ]) {
      expect(() => env(gateway: gateway).validate(), throwsStateError);
    }
  });
  test('production rejects DEV project and non-debug DEV builds', () {
    expect(() => env(project: 'inkstamp-dev').validate(), throwsStateError);
    expect(() => env(name: 'dev').validate(), throwsStateError);
    expect(() => env().validate(), returnsNormally);
  });
  test('only debug DEV permits localhost transport', () {
    final dev = env(
      debug: true,
      name: 'dev',
      gateway: '',
      project: 'inkstamp-dev',
    );
    expect(dev.gatewayBaseUrl, 'http://127.0.0.1:8787');
    expect(dev.validate, returnsNormally);
    expect(
      () => env(debug: true, name: 'staging', gateway: '').validate(),
      throwsStateError,
    );
  });
  test('error reporting never serializes sensitive exception content', () {
    final records = <String>[];
    SafeErrorReporter(sink: records.add).report(
      ErrorEvent.uncaughtAsync,
      StateError('Bearer private-token password=private https://private/image'),
      StackTrace.fromString('private user record'),
    );
    expect(records.single, '{"event":"uncaughtAsync","severity":"error"}');
  });
}
