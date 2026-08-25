import 'package:inkstamp/features/authentication/domain/entities/app_user.dart';

abstract interface class AuthenticationRepository {
  /// Emits the signed-in user and emits null after sign-out or deletion.
  Stream<AppUser?> watchCurrentUser();

  Future<AppUser?> getCurrentUser();

  Future<AppUser> signInWithApple();

  Future<AppUser> signInWithGoogle();

  Future<bool> isUsernameAvailable(String username);

  Future<AppUser> updateProfile({
    required AppUser user,
    required String username,
    required String displayName,
  });

  Future<AppUser> completeOnboarding({required AppUser user});

  Future<void> signOut();

  Future<void> deleteAccount();
}
