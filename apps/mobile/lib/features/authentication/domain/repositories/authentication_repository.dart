import 'package:inkstamp/features/authentication/domain/entities/app_user.dart';

abstract interface class AuthenticationRepository {
  Future<AppUser> signInWithApple();

  Future<AppUser> signInWithGoogle();

  Future<bool> isUsernameAvailable(String username);

  Future<AppUser> updateProfile({
    required AppUser user,
    required String username,
    required String displayName,
  });

  Future<void> signOut();

  Future<void> deleteAccount();
}
