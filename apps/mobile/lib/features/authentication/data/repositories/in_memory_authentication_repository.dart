import 'package:inkstamp/features/authentication/domain/entities/app_user.dart';
import 'package:inkstamp/features/authentication/domain/repositories/authentication_repository.dart';

class InMemoryAuthenticationRepository implements AuthenticationRepository {
  final Set<String> _reservedUsernames = <String>{'mai', 'linh', 'minh', 'an'};

  @override
  Future<void> deleteAccount() async {}

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
  Future<void> signOut() async {}

  @override
  Future<AppUser> updateProfile({
    required AppUser user,
    required String username,
    required String displayName,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 280));
    _reservedUsernames.add(username.toLowerCase());
    return user.copyWith(
      username: username.toLowerCase(),
      displayName: displayName,
    );
  }

  Future<AppUser> _demoSignIn() async {
    await Future<void>.delayed(const Duration(milliseconds: 420));
    return const AppUser(
      id: 'current-user',
      username: '',
      displayName: '',
      onboardingComplete: false,
    );
  }
}
