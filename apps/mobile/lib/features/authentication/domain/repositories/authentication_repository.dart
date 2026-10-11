import 'package:inkstamp/features/authentication/domain/entities/app_user.dart';

abstract interface class AuthenticationRepository {
  Stream<AppUser?> authStateChanges();

  Future<AppUser> signInWithApple();

  Future<AppUser> signInWithGoogle();

  /// Real Firebase email/password sign-in, guarded at the repository boundary.
  Future<AppUser> signInForDevelopment({
    required String email,
    required String password,
  });

  Future<bool> isUsernameAvailable(String username);

  Future<AppUser> updateProfile({
    required AppUser user,
    required String username,
    required String displayName,
  });

  Future<AppUser> updateOnboardingStep({
    required AppUser user,
    required UserOnboardingStep step,
  });

  Future<void> signOut();

  Future<void> deleteAccount();
}
