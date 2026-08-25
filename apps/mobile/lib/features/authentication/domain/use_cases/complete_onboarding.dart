import 'package:inkstamp/features/authentication/domain/entities/app_user.dart';
import 'package:inkstamp/features/authentication/domain/repositories/authentication_repository.dart';

class CompleteOnboarding {
  const CompleteOnboarding(this._repository);

  final AuthenticationRepository _repository;

  Future<AppUser> call(AppUser user) {
    return _repository.completeOnboarding(user: user);
  }
}
