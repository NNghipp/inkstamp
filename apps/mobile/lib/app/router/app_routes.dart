abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String welcome = '/welcome';
  static const String signIn = '/sign-in';
  static const String setupUsername = '/setup-username';
  static const String permissions = '/permissions';
  static const String widgetIntro = '/widget-intro';

  static const String inbox = '/inbox';
  static const String camera = '/camera';
  static const String calendar = '/calendar';
  static const String friends = '/friends';

  static const String cameraPreview = '/camera/preview';
  static const String cameraEditor = '/camera/editor';
  static const String cameraAudience = '/camera/audience';
  static const String cameraSending = '/camera/sending';
  static const String cameraSuccess = '/camera/success';

  static String stamp(String stampId) => '/stamp/$stampId';
  static String stampReply(String stampId) => '/stamp/$stampId/reply';
  static String stampReport(String stampId) => '/stamp/$stampId/report';

  static String archiveDay(String date) => '/calendar/day/$date';
  static String archiveStamp(String stampId) {
    return '/calendar/stamp/$stampId';
  }

  static const String friendSearch = '/friends/search';
  static const String friendRequests = '/friends/requests';
  static const String closeFriends = '/friends/close-friends';
  static String friendProfile(String userId) => '/friends/profile/$userId';
  static const String inviteFriend = '/friends/invite';

  static const String settings = '/settings';
  static const String editProfile = '/settings/profile';
  static const String notificationSettings = '/settings/notifications';
  static const String privacySettings = '/settings/privacy';
  static const String blockedUsers = '/settings/blocked-users';
  static const String help = '/settings/help';
  static const String deleteAccount = '/settings/delete-account';
}
