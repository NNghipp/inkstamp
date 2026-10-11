import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkstamp/features/authentication/data/repositories/firebase_authentication_repository.dart';
import 'package:inkstamp/features/authentication/data/repositories/in_memory_authentication_repository.dart';
import 'package:inkstamp/features/authentication/domain/dev_auth_policy.dart';
import 'package:inkstamp/features/authentication/domain/entities/app_user.dart';
import 'package:inkstamp/features/authentication/domain/repositories/authentication_repository.dart';
import 'package:inkstamp/features/authentication/domain/use_cases/sign_in.dart';

// ---------------------------------------------------------------------------
// Session stage
// ---------------------------------------------------------------------------

enum SessionStage { signedOut, profileSetup, permissions, widgetIntro, ready }

// ---------------------------------------------------------------------------
// Session state
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Whether Firebase has been initialised.  Set to `true` in [bootstrap] after
/// `Firebase.initializeApp()` succeeds.
final Provider<bool> firebaseInitializedProvider = Provider<bool>(
  (Ref ref) => false,
);

/// Resolves to [FirebaseAuthenticationRepository] in production or
/// [InMemoryAuthenticationRepository] when Firebase is unavailable (demo mode).
final Provider<AuthenticationRepository> authenticationRepositoryProvider =
    Provider<AuthenticationRepository>((Ref ref) {
      final bool isFirebaseReady = ref.watch(firebaseInitializedProvider);
      if (isFirebaseReady) {
        return FirebaseAuthenticationRepository();
      }
      return InMemoryAuthenticationRepository();
    });

final NotifierProvider<SessionController, SessionState>
sessionControllerProvider = NotifierProvider<SessionController, SessionState>(
  SessionController.new,
);

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

class SessionController extends Notifier<SessionState> {
  StreamSubscription<AppUser?>? _authSubscription;
  int _operation = 0;

  AuthenticationRepository get _repository {
    return ref.read(authenticationRepositoryProvider);
  }

  @override
  SessionState build() {
    _listenToAuthChanges();
    ref.onDispose(() => _authSubscription?.cancel());
    return const SessionState.signedOut();
  }

  // ---- Auth state listener -------------------------------------------------

  void _listenToAuthChanges() {
    _authSubscription?.cancel();
    _authSubscription = _repository.authStateChanges().listen(
      (user) {
        if (!ref.mounted || state.isLoading) return;
        if (user == null) {
          _operation++;
          state = const SessionState.signedOut();
        } else {
          state = SessionState(stage: _stageForUser(user), user: user);
        }
      },
      onError: (Object _) {
        if (ref.mounted && !state.isLoading) {
          state = const SessionState.signedOut();
        }
      },
    );
  }

  SessionStage _stageForUser(AppUser user) {
    return switch (user.onboardingStep) {
      UserOnboardingStep.profile => SessionStage.profileSetup,
      UserOnboardingStep.permissions => SessionStage.permissions,
      UserOnboardingStep.widgetIntro => SessionStage.widgetIntro,
      UserOnboardingStep.complete => SessionStage.ready,
    };
  }

  // ---- Public API ----------------------------------------------------------

  Future<void> signIn(SignInProvider provider) async {
    final operation = ++_operation;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final AppUser user = await SignIn(_repository)(provider);
      if (!ref.mounted || operation != _operation) return;
      state = SessionState(stage: _stageForUser(user), user: user);
    } on AuthenticationException catch (error) {
      if (!ref.mounted || operation != _operation) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: switch (error.failure) {
          AuthenticationFailure.cancelled => 'Sign-in was cancelled.',
          AuthenticationFailure.network =>
            'Check your connection and try again.',
          AuthenticationFailure.disabled => 'This account has been disabled.',
          AuthenticationFailure.providerConfiguration =>
            'Sign-in is not configured correctly for this app.',
          AuthenticationFailure.unknown =>
            'Unable to sign in. Please try again.',
        },
      );
    } on Object {
      if (!ref.mounted || operation != _operation) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to sign in. Please try again.',
      );
    }
  }

  Future<void> signInForDevelopment(
    DevTestAccount account, {
    required String password,
  }) async {
    if (!DevAuthPolicy.compiledEnabled || state.isLoading) {
      throw StateError('DEV test authentication is unavailable.');
    }
    final operation = ++_operation;
    state = const SessionState(stage: SessionStage.signedOut, isLoading: true);
    try {
      final user = await _repository.signInForDevelopment(
        email: account.email,
        password: password,
      );
      if (!ref.mounted || operation != _operation) return;
      state = SessionState(stage: _stageForUser(user), user: user);
    } on Object {
      if (!ref.mounted || operation != _operation) return;
      state = const SessionState(
        stage: SessionStage.signedOut,
        errorMessage: 'DEV sign-in failed. Check local setup and credentials.',
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

      final AppUser updated = await _repository.updateProfile(
        user: user,
        username: username,
        displayName: displayName,
      );
      state = SessionState(stage: SessionStage.permissions, user: updated);
      return true;
    } on Object {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to save your profile. Please try again.',
      );
      return false;
    }
  }

  Future<void> completePermissions() async {
    final AppUser? user = state.user;
    if (user == null) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final AppUser updated = await _repository.updateOnboardingStep(
        user: user,
        step: UserOnboardingStep.widgetIntro,
      );
      state = state.copyWith(
        stage: SessionStage.widgetIntro,
        user: updated,
        isLoading: false,
      );
    } on Object {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to save permissions. Please try again.',
      );
    }
  }

  Future<void> completeOnboarding() async {
    final AppUser? user = state.user;
    if (user == null) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final AppUser updated = await _repository.updateOnboardingStep(
        user: user,
        step: UserOnboardingStep.complete,
      );
      state = state.copyWith(
        stage: SessionStage.ready,
        user: updated,
        isLoading: false,
      );
    } on Object {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to finish onboarding. Please try again.',
      );
    }
  }

  void updateDisplayName(String displayName) {
    final AppUser? user = state.user;
    if (user == null) {
      return;
    }
    state = state.copyWith(user: user.copyWith(displayName: displayName));
  }

  Future<void> signOut() async {
    final operation = ++_operation;
    // Clear all user-scoped consumers before asynchronous provider sign-out.
    state = const SessionState.signedOut();
    await _repository.signOut();
    if (ref.mounted && operation == _operation) {
      state = const SessionState.signedOut();
    }
  }

  Future<void> deleteAccount() async {
    state = state.copyWith(isLoading: true);
    await _repository.deleteAccount();
    state = const SessionState.signedOut();
  }
}
