import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:inkstamp/features/authentication/domain/entities/app_user.dart';
import 'package:inkstamp/features/authentication/domain/repositories/authentication_repository.dart';
import 'package:inkstamp/features/authentication/domain/use_cases/complete_onboarding.dart';
import 'package:inkstamp/features/authentication/domain/use_cases/update_profile.dart';
import 'package:inkstamp/features/authentication/domain/use_cases/watch_authentication_state.dart';

void main() {
  test(
    'profile updates preserve identity and normalize through repository',
    () async {
      final _FakeAuthenticationRepository repository =
          _FakeAuthenticationRepository();
      const AppUser user = AppUser(
        id: 'user-1',
        username: '',
        displayName: '',
        onboardingComplete: false,
      );

      final AppUser updated = await UpdateProfile(repository)(
        user: user,
        username: 'minh.anh',
        displayName: 'Minh Anh',
      );

      expect(updated.id, 'user-1');
      expect(updated.username, 'minh.anh');
      expect(updated.needsProfileSetup, isFalse);
    },
  );

  test('profile input is normalized before reaching the repository', () async {
    final _FakeAuthenticationRepository repository =
        _FakeAuthenticationRepository();
    const AppUser user = AppUser(
      id: 'user-1',
      username: '',
      displayName: '',
      onboardingComplete: false,
    );

    final AppUser updated = await UpdateProfile(repository)(
      user: user,
      username: '  Minh.Anh  ',
      displayName: '  Minh Anh  ',
    );

    expect(updated.username, 'minh.anh');
    expect(updated.displayName, 'Minh Anh');
  });

  test('invalid profile input never reaches the repository', () {
    final _FakeAuthenticationRepository repository =
        _FakeAuthenticationRepository();
    const AppUser user = AppUser(
      id: 'user-1',
      username: '',
      displayName: '',
      onboardingComplete: false,
    );

    expect(
      () => UpdateProfile(repository)(
        user: user,
        username: 'not valid!',
        displayName: 'Minh Anh',
      ),
      throwsA(isA<InvalidProfileInput>()),
    );
  });

  test('completing onboarding updates the session state', () async {
    final _FakeAuthenticationRepository repository =
        _FakeAuthenticationRepository();
    const AppUser user = AppUser(
      id: 'user-1',
      username: 'minh.anh',
      displayName: 'Minh Anh',
      onboardingComplete: false,
    );
    final List<AppUser?> states = <AppUser?>[];
    final StreamSubscription<AppUser?> subscription = WatchAuthenticationState(
      repository,
    )().listen(states.add);

    final AppUser completed = await CompleteOnboarding(repository)(user);
    await Future<void>.delayed(Duration.zero);

    expect(completed.onboardingComplete, isTrue);
    expect(states, <AppUser?>[completed]);
    await subscription.cancel();
  });
}

class _FakeAuthenticationRepository implements AuthenticationRepository {
  final StreamController<AppUser?> _controller = StreamController<AppUser?>();

  @override
  Future<AppUser> completeOnboarding({required AppUser user}) async {
    final AppUser completed = user.copyWith(onboardingComplete: true);
    _controller.add(completed);
    return completed;
  }

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<AppUser?> getCurrentUser() async => null;

  @override
  Future<bool> isUsernameAvailable(String username) async => true;

  @override
  Future<AppUser> signInWithApple() => throw UnimplementedError();

  @override
  Future<AppUser> signInWithGoogle() => throw UnimplementedError();

  @override
  Future<void> signOut() async {}

  @override
  Future<AppUser> updateProfile({
    required AppUser user,
    required String username,
    required String displayName,
  }) async {
    return user.copyWith(
      username: username.toLowerCase(),
      displayName: displayName,
    );
  }

  @override
  Stream<AppUser?> watchCurrentUser() => _controller.stream;
}
