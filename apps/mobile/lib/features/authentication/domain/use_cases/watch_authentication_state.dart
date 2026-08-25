import 'package:inkstamp/features/authentication/domain/entities/app_user.dart';
import 'package:inkstamp/features/authentication/domain/repositories/authentication_repository.dart';

class WatchAuthenticationState {
  const WatchAuthenticationState(this._repository);

  final AuthenticationRepository _repository;

  Stream<AppUser?> call() => _repository.watchCurrentUser();
}
