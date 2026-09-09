import 'package:inkstamp/features/authentication/domain/entities/app_user.dart';

abstract interface class AuthenticationRepository {
  Stream<AppUser?> authStateChanges();

  Future<AppUser> signInWithApple();

  Future<AppUser> signInWithGoogle();

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
