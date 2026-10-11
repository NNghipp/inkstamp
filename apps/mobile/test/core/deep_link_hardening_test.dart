import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkstamp/app/router/app_router.dart';
import 'package:inkstamp/app/theme/app_theme.dart';
import 'package:inkstamp/features/authentication/domain/entities/app_user.dart';
import 'package:inkstamp/features/authentication/presentation/controllers/session_controller.dart';
import 'package:inkstamp/features/friends/presentation/screens/friend_search_screen.dart';

import '../features/authentication/dev_auth_test.dart' show StreamAuth;

void main() {
  testWidgets(
    'invite waits for auth and resumes only after ready; logout hides lookup',
    (tester) async {
      final auth = StreamAuth();
      final container = ProviderContainer(
        overrides: [authenticationRepositoryProvider.overrideWithValue(auth)],
      );
      final router = container.read(appRouterProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      router.go('/u/test_a');
      await tester.pumpAndSettle();
      expect(find.byType(FriendSearchScreen), findsNothing);
      auth.events.add(
        const AppUser(
          id: 'unit-B',
          username: 'unit_b',
          displayName: 'B',
          onboardingComplete: true,
          onboardingStep: UserOnboardingStep.complete,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FriendSearchScreen), findsOneWidget);
      await container.read(sessionControllerProvider.notifier).signOut();
      await tester.pumpAndSettle();
      expect(find.byType(FriendSearchScreen), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
      await auth.close();
    },
  );
  testWidgets('malformed invite does not construct a search screen', (
    tester,
  ) async {
    final container = ProviderContainer();
    final router = container.read(appRouterProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    router.go('/u/invalid%20target');
    await tester.pumpAndSettle();
    expect(find.byType(FriendSearchScreen), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
  });
}
