import 'package:flutter_test/flutter_test.dart';
import 'package:inkstamp/core/config/functions_backend.dart';

void main() {
  test('emulator transport is opt-in debug DEV only', () {
    const requested =
        String.fromEnvironment('APP_ENV') == 'dev' &&
        String.fromEnvironment('BACKEND_MODE') == 'functions_emulator';
    expect(FunctionsBackend.emulatorEnabled, requested);
  });
}
