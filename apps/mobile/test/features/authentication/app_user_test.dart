import 'package:flutter_test/flutter_test.dart';
import 'package:inkstamp/features/authentication/domain/entities/app_user.dart';

void main() {
  test('copyWith updates profile without replacing identity', () {
    const AppUser user = AppUser(
      id: 'user-1',
      username: 'old.name',
      displayName: 'Old Name',
      onboardingComplete: false,
    );

    final AppUser updated = user.copyWith(
      displayName: 'Minh Anh',
      onboardingComplete: true,
    );

    expect(updated.id, user.id);
    expect(updated.username, user.username);
    expect(updated.displayName, 'Minh Anh');
    expect(updated.onboardingComplete, isTrue);
  });
}
