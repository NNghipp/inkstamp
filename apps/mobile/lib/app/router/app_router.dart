import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstamp/app/router/app_routes.dart';
import 'package:inkstamp/app/router/main_shell.dart';
import 'package:inkstamp/features/archive/presentation/screens/archive_day_screen.dart';
import 'package:inkstamp/features/archive/presentation/screens/archive_stamp_screen.dart';
import 'package:inkstamp/features/archive/presentation/screens/calendar_screen.dart';
import 'package:inkstamp/features/authentication/presentation/controllers/session_controller.dart';
import 'package:inkstamp/features/authentication/presentation/screens/sign_in_screen.dart';
import 'package:inkstamp/features/authentication/presentation/screens/username_setup_screen.dart';
import 'package:inkstamp/features/camera/presentation/screens/camera_screen.dart';
import 'package:inkstamp/features/friends/presentation/screens/close_friends_screen.dart';
import 'package:inkstamp/features/friends/presentation/screens/friend_profile_screen.dart';
import 'package:inkstamp/features/friends/presentation/screens/friend_requests_screen.dart';
import 'package:inkstamp/features/friends/presentation/screens/friend_search_screen.dart';
import 'package:inkstamp/features/friends/presentation/screens/friends_screen.dart';
import 'package:inkstamp/features/friends/presentation/screens/invite_friend_screen.dart';
import 'package:inkstamp/features/inbox/presentation/screens/inbox_screen.dart';
import 'package:inkstamp/features/inbox/presentation/screens/stamp_detail_screen.dart';
import 'package:inkstamp/features/inbox/presentation/screens/stamp_reply_screen.dart';
import 'package:inkstamp/features/onboarding/presentation/screens/permissions_screen.dart';
import 'package:inkstamp/features/onboarding/presentation/screens/splash_screen.dart';
import 'package:inkstamp/features/onboarding/presentation/screens/welcome_screen.dart';
import 'package:inkstamp/features/onboarding/presentation/screens/widget_intro_screen.dart';
import 'package:inkstamp/features/safety/presentation/screens/report_stamp_screen.dart';
import 'package:inkstamp/features/settings/presentation/screens/blocked_users_screen.dart';
import 'package:inkstamp/features/settings/presentation/screens/delete_account_screen.dart';
import 'package:inkstamp/features/settings/presentation/screens/edit_profile_screen.dart';
import 'package:inkstamp/features/settings/presentation/screens/help_screen.dart';
import 'package:inkstamp/features/settings/presentation/screens/notification_settings_screen.dart';
import 'package:inkstamp/features/settings/presentation/screens/privacy_settings_screen.dart';
import 'package:inkstamp/features/settings/presentation/screens/settings_screen.dart';
import 'package:inkstamp/features/stamps/presentation/screens/audience_picker_screen.dart';
import 'package:inkstamp/features/stamps/presentation/screens/stamp_editor_screen.dart';
import 'package:inkstamp/features/stamps/presentation/screens/stamp_preview_screen.dart';
import 'package:inkstamp/features/stamps/presentation/screens/stamp_sending_screen.dart';
import 'package:inkstamp/features/stamps/presentation/screens/stamp_sent_screen.dart';

final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((Ref ref) {
  final _RouterRefreshNotifier refreshNotifier = _RouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshNotifier,
    redirect: (BuildContext context, GoRouterState state) {
      return _redirectForSession(
        ref.read(sessionControllerProvider),
        state.matchedLocation,
      );
    },
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: AppRoutes.setupUsername,
        builder: (context, state) => const UsernameSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.permissions,
        builder: (context, state) => const PermissionsScreen(),
      ),
      GoRoute(
        path: AppRoutes.widgetIntro,
        builder: (context, state) => const WidgetIntroScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: <RouteBase>[
          GoRoute(
            path: AppRoutes.inbox,
            builder: (context, state) => const InboxScreen(),
          ),
          GoRoute(
            path: AppRoutes.camera,
            builder: (context, state) => const CameraScreen(),
          ),
          GoRoute(
            path: AppRoutes.calendar,
            builder: (context, state) => const CalendarScreen(),
          ),
          GoRoute(
            path: AppRoutes.friends,
            builder: (context, state) => const FriendsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.cameraPreview,
        builder: (context, state) => const StampPreviewScreen(),
      ),
      GoRoute(
        path: AppRoutes.cameraEditor,
        builder: (context, state) => const StampEditorScreen(),
      ),
      GoRoute(
        path: AppRoutes.cameraAudience,
        builder: (context, state) => const AudiencePickerScreen(),
      ),
      GoRoute(
        path: AppRoutes.cameraSending,
        builder: (context, state) => const StampSendingScreen(),
      ),
      GoRoute(
        path: AppRoutes.cameraSuccess,
        builder: (context, state) => const StampSentScreen(),
      ),
      GoRoute(
        path: '/stamp/:stampId',
        builder: (context, state) {
          return StampDetailScreen(stampId: state.pathParameters['stampId']!);
        },
      ),
      GoRoute(
        path: '/stamp/:stampId/reply',
        builder: (context, state) {
          return StampReplyScreen(stampId: state.pathParameters['stampId']!);
        },
      ),
      GoRoute(
        path: '/stamp/:stampId/report',
        builder: (context, state) {
          return ReportStampScreen(stampId: state.pathParameters['stampId']!);
        },
      ),
      GoRoute(
        path: '/calendar/day/:date',
        builder: (context, state) {
          return ArchiveDayScreen(date: state.pathParameters['date']!);
        },
      ),
      GoRoute(
        path: '/calendar/stamp/:stampId',
        builder: (context, state) {
          return ArchiveStampScreen(stampId: state.pathParameters['stampId']!);
        },
      ),
      GoRoute(
        path: AppRoutes.friendSearch,
        builder: (context, state) => const FriendSearchScreen(),
      ),
      GoRoute(
        path: AppRoutes.friendRequests,
        builder: (context, state) => const FriendRequestsScreen(),
      ),
      GoRoute(
        path: AppRoutes.closeFriends,
        builder: (context, state) => const CloseFriendsScreen(),
      ),
      GoRoute(
        path: '/friends/profile/:uid',
        builder: (context, state) {
          return FriendProfileScreen(userId: state.pathParameters['uid']!);
        },
      ),
      GoRoute(
        path: AppRoutes.inviteFriend,
        builder: (context, state) => const InviteFriendScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.notificationSettings,
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.privacySettings,
        builder: (context, state) => const PrivacySettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.blockedUsers,
        builder: (context, state) => const BlockedUsersScreen(),
      ),
      GoRoute(
        path: AppRoutes.help,
        builder: (context, state) => const HelpScreen(),
      ),
      GoRoute(
        path: AppRoutes.deleteAccount,
        builder: (context, state) => const DeleteAccountScreen(),
      ),
    ],
  );
});

String? _redirectForSession(SessionState session, String location) {
  switch (session.stage) {
    case SessionStage.restoring:
      return location == AppRoutes.splash ? null : AppRoutes.splash;
    case SessionStage.signedOut:
      if (location == AppRoutes.welcome || location == AppRoutes.signIn) {
        return null;
      }
      return AppRoutes.welcome;
    case SessionStage.profileSetup:
      return location == AppRoutes.setupUsername
          ? null
          : AppRoutes.setupUsername;
    case SessionStage.permissions:
      return location == AppRoutes.permissions ? null : AppRoutes.permissions;
    case SessionStage.widgetIntro:
      return location == AppRoutes.widgetIntro ? null : AppRoutes.widgetIntro;
    case SessionStage.ready:
      if (_onboardingLocations.contains(location)) {
        return AppRoutes.camera;
      }
      return null;
  }
}

const Set<String> _onboardingLocations = <String>{
  AppRoutes.splash,
  AppRoutes.welcome,
  AppRoutes.signIn,
  AppRoutes.setupUsername,
  AppRoutes.permissions,
  AppRoutes.widgetIntro,
};

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen<SessionState>(sessionControllerProvider, (
      SessionState? previous,
      SessionState next,
    ) {
      notifyListeners();
    });
  }
}
