import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkstamp/features/authentication/data/repositories/firebase_authentication_repository.dart';
import 'package:inkstamp/features/authentication/data/repositories/in_memory_authentication_repository.dart';
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
  StreamSubscription<User?>? _authSubscription;

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
    final bool isFirebaseReady = ref.read(firebaseInitializedProvider);
    if (!isFirebaseReady) {
      return;
    }

    _authSubscription?.cancel();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((
      User? firebaseUser,
    ) {
      if (firebaseUser == null) {
        // User signed out externally (e.g. revoked session).
        state = const SessionState.signedOut();
      } else if (state.stage == SessionStage.signedOut && !state.isLoading) {
        // An existing Firebase session was found on app launch – restore it.
        _restoreSession(firebaseUser.uid);
      }
    });
  }

  Future<void> _restoreSession(String uid) async {
    state = state.copyWith(isLoading: true);
    try {
      final AppUser? user = await _repository.authStateChanges().first;
      if (user != null) {
        state = SessionState(stage: _stageForUser(user), user: user);
        return;
      }
      state = const SessionState.signedOut();
    } on Object {
      state = const SessionState.signedOut();
    }
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
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final AppUser user = await SignIn(_repository)(provider);
      state = SessionState(stage: _stageForUser(user), user: user);
    } on AuthenticationException catch (error) {
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
    await _repository.signOut();
    state = const SessionState.signedOut();
  }

  Future<void> deleteAccount() async {
    state = state.copyWith(isLoading: true);
    await _repository.deleteAccount();
    state = const SessionState.signedOut();
  }
}
