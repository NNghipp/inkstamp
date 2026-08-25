import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkstamp/app/dependencies/authentication_dependencies.dart';
import 'package:inkstamp/features/authentication/domain/entities/app_user.dart';
import 'package:inkstamp/features/authentication/domain/repositories/authentication_repository.dart';
import 'package:inkstamp/features/authentication/domain/use_cases/complete_onboarding.dart';
import 'package:inkstamp/features/authentication/domain/use_cases/sign_in.dart';
import 'package:inkstamp/features/authentication/domain/use_cases/update_profile.dart';
import 'package:inkstamp/features/authentication/domain/use_cases/watch_authentication_state.dart';

enum SessionStage {
  restoring,
  signedOut,
  profileSetup,
  permissions,
  widgetIntro,
  ready,
}

class SessionState {
  const SessionState({
    required this.stage,
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  const SessionState.signedOut() : this(stage: SessionStage.signedOut);

  const SessionState.restoring()
    : this(stage: SessionStage.restoring, isLoading: true);

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

final NotifierProvider<SessionController, SessionState>
sessionControllerProvider = NotifierProvider<SessionController, SessionState>(
  SessionController.new,
);

final StreamProvider<AppUser?> authenticationStateChangesProvider =
    StreamProvider<AppUser?>((Ref ref) {
      final AuthenticationRepository repository = ref.watch(
        authenticationRepositoryProvider,
      );
      return WatchAuthenticationState(repository)();
    });

class SessionController extends Notifier<SessionState> {
  AuthenticationRepository get _repository {
    return ref.read(authenticationRepositoryProvider);
  }

  @override
  SessionState build() {
    final AsyncValue<AppUser?> authenticationState = ref.watch(
      authenticationStateChangesProvider,
    );
    return authenticationState.when(
      data: _stateForUser,
      error: (Object error, StackTrace stackTrace) => const SessionState(
        stage: SessionStage.signedOut,
        errorMessage: 'Unable to restore your session. Please sign in again.',
      ),
      loading: SessionState.restoring,
    );
  }

  Future<void> signIn(SignInProvider provider) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final AppUser user = await SignIn(_repository)(provider);
      state = _stateForUser(user);
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
    try {
      final bool available = await _repository.isUsernameAvailable(username);
      if (!available) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'This username is already taken.',
        );
        return false;
      }

      final AppUser updated = await UpdateProfile(_repository)(
        user: user,
        username: username,
        displayName: displayName,
      );
      state = SessionState(stage: SessionStage.permissions, user: updated);
      return true;
    } on InvalidProfileInput catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.message);
      return false;
    } on Object {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to save your profile. Please try again.',
      );
      return false;
    }
  }

  void completePermissions() {
    state = state.copyWith(stage: SessionStage.widgetIntro);
  }

  Future<void> completeOnboarding() async {
    final AppUser? user = state.user;
    if (user == null) {
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final AppUser updated = await CompleteOnboarding(_repository)(user);
      state = SessionState(stage: SessionStage.ready, user: updated);
    } on Object {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to complete onboarding. Please try again.',
      );
    }
  }

  Future<bool> updateDisplayName(String displayName) async {
    final AppUser? user = state.user;
    if (user == null) {
      return false;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final AppUser updated = await UpdateProfile(_repository)(
        user: user,
        username: user.username,
        displayName: displayName,
      );
      state = SessionState(stage: SessionStage.ready, user: updated);
      return true;
    } on InvalidProfileInput catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.message);
      return false;
    } on Object {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to update your profile. Please try again.',
      );
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.signOut();
      state = const SessionState.signedOut();
    } on Object {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to sign out. Please try again.',
      );
    }
  }

  Future<void> deleteAccount() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.deleteAccount();
      state = const SessionState.signedOut();
    } on Object {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to delete your account. Please try again.',
      );
    }
  }
}

SessionState _stateForUser(AppUser? user) {
  if (user == null) {
    return const SessionState.signedOut();
  }
  if (user.needsProfileSetup) {
    return SessionState(stage: SessionStage.profileSetup, user: user);
  }
  if (!user.onboardingComplete) {
    return SessionState(stage: SessionStage.permissions, user: user);
  }
  return SessionState(stage: SessionStage.ready, user: user);
}
