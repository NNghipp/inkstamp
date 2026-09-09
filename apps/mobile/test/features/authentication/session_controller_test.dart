import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkstamp/features/authentication/data/repositories/firebase_authentication_repository.dart';
import 'package:inkstamp/features/authentication/domain/entities/app_user.dart';
import 'package:inkstamp/features/authentication/domain/repositories/authentication_repository.dart';
import 'package:inkstamp/features/authentication/domain/use_cases/sign_in.dart';
import 'package:inkstamp/features/authentication/presentation/controllers/session_controller.dart';

void main() {
  test('sign-in success routes a new user to profile setup', () async {
    final container = _container(FakeAuthenticationRepository());
    await container
        .read(sessionControllerProvider.notifier)
        .signIn(SignInProvider.google);
    expect(
      container.read(sessionControllerProvider).stage,
      SessionStage.profileSetup,
    );
    container.dispose();
  });

  test('cancelled sign-in exposes a specific message', () async {
    final container = _container(
      FakeAuthenticationRepository(
        signInError: const AuthenticationException(
          AuthenticationFailure.cancelled,
        ),
      ),
    );
    await container
        .read(sessionControllerProvider.notifier)
        .signIn(SignInProvider.google);
    expect(
      container.read(sessionControllerProvider).errorMessage,
      'Sign-in was cancelled.',
    );
    container.dispose();
  });

  test('onboarding stages are persisted through the repository', () async {
    final repository = FakeAuthenticationRepository();
    final container = _container(repository);
    final controller = container.read(sessionControllerProvider.notifier);
    await controller.signIn(SignInProvider.google);
    await controller.completeProfile(
      username: 'New.User',
      displayName: 'New User',
    );
    expect(
      container.read(sessionControllerProvider).stage,
      SessionStage.permissions,
    );
    await controller.completePermissions();
    expect(
      container.read(sessionControllerProvider).stage,
      SessionStage.widgetIntro,
    );
    await controller.completeOnboarding();
    expect(container.read(sessionControllerProvider).stage, SessionStage.ready);
    expect(repository.savedSteps, [
      UserOnboardingStep.widgetIntro,
      UserOnboardingStep.complete,
    ]);
    container.dispose();
  });
}

ProviderContainer _container(AuthenticationRepository repository) =>
    ProviderContainer(
      overrides: [
        authenticationRepositoryProvider.overrideWithValue(repository),
        firebaseInitializedProvider.overrideWithValue(false),
      ],
    );

class FakeAuthenticationRepository implements AuthenticationRepository {
  FakeAuthenticationRepository({this.signInError});
  final Exception? signInError;
  final List<UserOnboardingStep> savedSteps = [];
  AppUser user = const AppUser(
    id: 'user-1',
    username: '',
    displayName: '',
    onboardingComplete: false,
  );

  @override
  Stream<AppUser?> authStateChanges() => Stream.value(user);
  Future<AppUser> _signIn() async {
    if (signInError != null) throw signInError!;
    return user;
  }

  @override
  Future<AppUser> signInWithApple() => _signIn();
  @override
  Future<AppUser> signInWithGoogle() => _signIn();
  @override
  Future<bool> isUsernameAvailable(String username) async =>
      username.toLowerCase() != 'taken';
  @override
  Future<AppUser> updateProfile({
    required AppUser user,
    required String username,
    required String displayName,
  }) async {
    return this.user = user.copyWith(
      username: username.toLowerCase(),
      displayName: displayName,
      onboardingStep: UserOnboardingStep.permissions,
    );
  }

  @override
  Future<AppUser> updateOnboardingStep({
    required AppUser user,
    required UserOnboardingStep step,
  }) async {
    savedSteps.add(step);
    return this.user = user.copyWith(
      onboardingStep: step,
      onboardingComplete: step == UserOnboardingStep.complete,
    );
  }

  @override
  Future<void> signOut() async {}
  @override
  Future<void> deleteAccount() async {}
}
