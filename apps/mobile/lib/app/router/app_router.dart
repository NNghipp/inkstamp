import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstamp/app/app.dart';
import 'package:inkstamp/app/router/app_routes.dart';
import 'package:inkstamp/app/router/main_shell.dart';
import 'package:inkstamp/app/theme/app_motion.dart';
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
import 'package:inkstamp/features/home/presentation/screens/home_screen.dart';
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
import 'package:inkstamp/features/stamps/presentation/screens/stamp_preview_screen.dart';

// ---------------------------------------------------------------------------
// Onboarding / unauthenticated routes – the redirect will NOT force a user
// away from these when they are in an early session stage.
// ---------------------------------------------------------------------------
const Set<String> _onboardingPaths = <String>{
  AppRoutes.splash,
  AppRoutes.welcome,
  AppRoutes.signIn,
  AppRoutes.setupUsername,
  AppRoutes.permissions,
  AppRoutes.widgetIntro,
};

// ---------------------------------------------------------------------------
// Router provider
// ---------------------------------------------------------------------------

final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((Ref ref) {
  final SessionRedirectNotifier redirectNotifier = SessionRedirectNotifier(ref);
  String? pendingInviteUsername;

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: redirectNotifier,
    redirect: (context, state) {
      final SessionStage stage = ref.read(sessionControllerProvider).stage;
      final String location = state.matchedLocation;
      final String? inviteUsername = state.pathParameters['username'];
      if (location.startsWith('/u/') &&
          (inviteUsername == null ||
              !RegExp(r'^[a-zA-Z0-9._]{3,20}$').hasMatch(inviteUsername))) {
        pendingInviteUsername = null;
        return stage == SessionStage.ready ? AppRoutes.home : AppRoutes.welcome;
      }
      if (location.startsWith('/u/') &&
          inviteUsername != null &&
          stage != SessionStage.ready) {
        pendingInviteUsername = inviteUsername;
      }

      // Never redirect while on the splash screen – it auto-navigates.
      if (location == AppRoutes.splash) {
        return null;
      }

      switch (stage) {
        case SessionStage.signedOut:
          // User is not authenticated – allow only onboarding routes.
          if (!_onboardingPaths.contains(location)) {
            return AppRoutes.welcome;
          }
          return null;

        case SessionStage.profileSetup:
          // User is signed in but hasn't set a username yet.
          if (location != AppRoutes.setupUsername) {
            return AppRoutes.setupUsername;
          }
          return null;

        case SessionStage.permissions:
          // User completed username, show permissions step.
          if (location != AppRoutes.permissions) {
            return AppRoutes.permissions;
          }
          return null;

        case SessionStage.widgetIntro:
          if (location != AppRoutes.widgetIntro) {
            return AppRoutes.widgetIntro;
          }
          return null;

        case SessionStage.ready:
          // Fully onboarded – redirect away from onboarding screens.
          if (_onboardingPaths.contains(location)) {
            if (pendingInviteUsername != null) {
              final String username = pendingInviteUsername!;
              pendingInviteUsername = null;
              return '/u/${Uri.encodeComponent(username)}';
            }
            return AppRoutes.home;
          }
          return null;
      }
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
            path: AppRoutes.home,
            pageBuilder: (context, state) => NoTransitionPage<void>(
              key: state.pageKey,
              child: const HomeScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.inbox,
            builder: (context, state) => const InboxScreen(),
          ),
          GoRoute(
            path: AppRoutes.camera,
            pageBuilder: (context, state) => NoTransitionPage<void>(
              key: state.pageKey,
              child: const CameraScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.calendar,
            pageBuilder: (context, state) => NoTransitionPage<void>(
              key: state.pageKey,
              child: const CalendarScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.friends,
            builder: (context, state) => const FriendsScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: (context, state) => NoTransitionPage<void>(
              key: state.pageKey,
              child: const SettingsScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.cameraPreview,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const StampPreviewScreen(),
          transitionDuration: AppMotion.duration(context, AppMotion.screen),
          reverseTransitionDuration: AppMotion.duration(
            context,
            AppMotion.standard,
          ),
          transitionsBuilder: (context, animation, secondary, child) =>
              AppMotion.transition(context, animation, child),
        ),
      ),
      GoRoute(
        path: AppRoutes.cameraEditor,
        redirect: (_, _) => AppRoutes.cameraPreview,
      ),
      GoRoute(
        path: AppRoutes.cameraAudience,
        redirect: (_, _) => AppRoutes.cameraPreview,
      ),
      GoRoute(
        path: AppRoutes.cameraSending,
        redirect: (_, _) => AppRoutes.cameraPreview,
      ),
      GoRoute(
        path: AppRoutes.cameraSuccess,
        redirect: (_, _) => AppRoutes.camera,
      ),
      GoRoute(
        path: '/stamp/:stampId',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: StampDetailScreen(stampId: state.pathParameters['stampId']!),
          transitionDuration: AppMotion.duration(context, AppMotion.screen),
          reverseTransitionDuration: AppMotion.duration(
            context,
            AppMotion.standard,
          ),
          transitionsBuilder: (context, animation, secondary, child) =>
              AppMotion.transition(context, animation, child),
        ),
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
        path: '/u/:username',
        builder: (context, state) => FriendSearchScreen(
          initialUsername: state.pathParameters['username'],
        ),
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
  ref.onDispose(() {
    router.dispose();
    redirectNotifier.dispose();
  });
  return router;
});
