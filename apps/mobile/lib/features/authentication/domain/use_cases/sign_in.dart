import 'package:inkstamp/features/authentication/domain/entities/app_user.dart';
import 'package:inkstamp/features/authentication/domain/repositories/authentication_repository.dart';

enum SignInProvider { apple, google }

class SignIn {
  const SignIn(this._repository);

  final AuthenticationRepository _repository;

  Future<AppUser> call(SignInProvider provider) {
    return switch (provider) {
      SignInProvider.apple => _repository.signInWithApple(),
      SignInProvider.google => _repository.signInWithGoogle(),
    };
  }
}
