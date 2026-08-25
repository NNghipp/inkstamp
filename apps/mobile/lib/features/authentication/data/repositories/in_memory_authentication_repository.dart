import 'dart:async';

import 'package:inkstamp/features/authentication/domain/entities/app_user.dart';
import 'package:inkstamp/features/authentication/domain/repositories/authentication_repository.dart';

class InMemoryAuthenticationRepository implements AuthenticationRepository {
  final Set<String> _reservedUsernames = <String>{'mai', 'linh', 'minh', 'an'};
  final StreamController<AppUser?> _sessionController =
      StreamController<AppUser?>.broadcast();
  AppUser? _currentUser;

  @override
  Future<AppUser> completeOnboarding({required AppUser user}) async {
    final AppUser completed = user.copyWith(onboardingComplete: true);
    _currentUser = completed;
    _sessionController.add(completed);
    return completed;
  }

  @override
  Future<void> deleteAccount() async {
    _currentUser = null;
    _sessionController.add(null);
  }

  @override
  Future<AppUser?> getCurrentUser() async => _currentUser;

  @override
  Future<bool> isUsernameAvailable(String username) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    return !_reservedUsernames.contains(username.toLowerCase());
  }

  @override
  Future<AppUser> signInWithApple() => _demoSignIn();

  @override
  Future<AppUser> signInWithGoogle() => _demoSignIn();

  @override
  Future<AppUser> updateProfile({
    required AppUser user,
    required String username,
    required String displayName,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 280));
    _reservedUsernames.add(username.toLowerCase());
    final AppUser updated = user.copyWith(
      username: username.toLowerCase(),
      displayName: displayName,
    );
    _currentUser = updated;
    _sessionController.add(updated);
    return updated;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _sessionController.add(null);
  }

  @override
  Stream<AppUser?> watchCurrentUser() async* {
    yield _currentUser;
    yield* _sessionController.stream;
  }

  Future<AppUser> _demoSignIn() async {
    await Future<void>.delayed(const Duration(milliseconds: 420));
    const AppUser user = AppUser(
      id: 'current-user',
      username: '',
      displayName: '',
      onboardingComplete: false,
    );
    _currentUser = user;
    _sessionController.add(user);
    return user;
  }
}
