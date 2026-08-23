import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkstamp/features/authentication/data/repositories/in_memory_authentication_repository.dart';
import 'package:inkstamp/features/authentication/domain/entities/app_user.dart';
import 'package:inkstamp/features/authentication/domain/repositories/authentication_repository.dart';
import 'package:inkstamp/features/authentication/domain/use_cases/sign_in.dart';

enum SessionStage { signedOut, profileSetup, permissions, widgetIntro, ready }

class SessionState {
  const SessionState({
    required this.stage,
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  const SessionState.signedOut() : this(stage: SessionStage.signedOut);

  final SessionStage stage;
  final AppUser? user;
  final bool isLoading;
  final String? errorMessage;

  SessionState copyWith({
    SessionStage? stage,
    AppUser? user,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SessionState(
      stage: stage ?? this.stage,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

final Provider<AuthenticationRepository> authenticationRepositoryProvider =
    Provider<AuthenticationRepository>(
      (Ref ref) => InMemoryAuthenticationRepository(),
    );

final NotifierProvider<SessionController, SessionState>
sessionControllerProvider = NotifierProvider<SessionController, SessionState>(
  SessionController.new,
);

class SessionController extends Notifier<SessionState> {
  AuthenticationRepository get _repository {
    return ref.read(authenticationRepositoryProvider);
  }

  @override
  SessionState build() => const SessionState.signedOut();

  Future<void> signIn(SignInProvider provider) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final AppUser user = await SignIn(_repository)(provider);
      state = SessionState(stage: SessionStage.profileSetup, user: user);
    } on Object {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to sign in. Please try again.',
      );
    }
  }

  Future<bool> completeProfile({
    required String username,
    required String displayName,
  }) async {
    final AppUser? user = state.user;
    if (user == null) {
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    final bool available = await _repository.isUsernameAvailable(username);
    if (!available) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'This username is already taken.',
      );
      return false;
    }

    final AppUser updated = await _repository.updateProfile(
      user: user,
      username: username,
      displayName: displayName,
    );
    state = SessionState(stage: SessionStage.permissions, user: updated);
    return true;
  }

  void completePermissions() {
    state = state.copyWith(stage: SessionStage.widgetIntro);
  }

  void completeOnboarding() {
    final AppUser? user = state.user;
    state = state.copyWith(
      stage: SessionStage.ready,
      user: user?.copyWith(onboardingComplete: true),
    );
  }

  void updateDisplayName(String displayName) {
    final AppUser? user = state.user;
    if (user == null) {
      return;
    }
    state = state.copyWith(user: user.copyWith(displayName: displayName));
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = const SessionState.signedOut();
  }

  Future<void> deleteAccount() async {
    state = state.copyWith(isLoading: true);
    await _repository.deleteAccount();
    state = const SessionState.signedOut();
  }
}
