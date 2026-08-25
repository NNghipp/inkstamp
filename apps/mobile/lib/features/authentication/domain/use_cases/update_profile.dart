import 'package:inkstamp/features/authentication/domain/entities/app_user.dart';
import 'package:inkstamp/features/authentication/domain/repositories/authentication_repository.dart';

class UpdateProfile {
  const UpdateProfile(this._repository);

  final AuthenticationRepository _repository;

  Future<AppUser> call({
    required AppUser user,
    required String username,
    required String displayName,
  }) {
    final String normalizedUsername = username.trim().toLowerCase();
    final String normalizedDisplayName = displayName.trim();
    if (!_usernamePattern.hasMatch(normalizedUsername)) {
      throw const InvalidProfileInput(
        'Use 3–20 lowercase letters, numbers, dots or underscores.',
      );
    }
    if (normalizedDisplayName.isEmpty || normalizedDisplayName.length > 50) {
      throw const InvalidProfileInput(
        'Display name must contain 1–50 characters.',
      );
    }

    return _repository.updateProfile(
      user: user,
      username: normalizedUsername,
      displayName: normalizedDisplayName,
    );
  }
}

final RegExp _usernamePattern = RegExp(r'^[a-z0-9._]{3,20}$');

class InvalidProfileInput implements Exception {
  const InvalidProfileInput(this.message);

  final String message;
}
