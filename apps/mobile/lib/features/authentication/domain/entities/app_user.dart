enum UserOnboardingStep { profile, permissions, widgetIntro, complete }

class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    required this.displayName,
    required this.onboardingComplete,
    this.onboardingStep = UserOnboardingStep.profile,
  });

  final String id;
  final String username;
  final String displayName;
  final bool onboardingComplete;
  final UserOnboardingStep onboardingStep;

  AppUser copyWith({
    String? username,
    String? displayName,
    bool? onboardingComplete,
    UserOnboardingStep? onboardingStep,
  }) {
    return AppUser(
      id: id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      onboardingStep: onboardingStep ?? this.onboardingStep,
    );
  }
}
