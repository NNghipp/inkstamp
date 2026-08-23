class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    required this.displayName,
    required this.onboardingComplete,
  });

  final String id;
  final String username;
  final String displayName;
  final bool onboardingComplete;

  AppUser copyWith({
    String? username,
    String? displayName,
    bool? onboardingComplete,
  }) {
    return AppUser(
      id: id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    );
  }
}
