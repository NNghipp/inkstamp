import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkstamp/features/archive/presentation/controllers/memory_view_controller.dart';
import 'package:inkstamp/features/authentication/data/repositories/firebase_authentication_repository.dart';
import 'package:inkstamp/features/authentication/data/repositories/in_memory_authentication_repository.dart';
import 'package:inkstamp/features/authentication/domain/dev_auth_policy.dart';
import 'package:inkstamp/features/authentication/domain/entities/app_user.dart';
import 'package:inkstamp/features/authentication/presentation/controllers/session_controller.dart';
import 'package:inkstamp/features/authentication/presentation/widgets/dev_test_login.dart';
import 'package:inkstamp/features/friends/data/repositories/in_memory_friend_repository.dart';
import 'package:inkstamp/features/friends/domain/entities/friend.dart';
import 'package:inkstamp/features/friends/presentation/controllers/friends_controller.dart';
import 'package:inkstamp/features/inbox/presentation/controllers/inbox_controller.dart';
import 'package:inkstamp/features/stamps/presentation/controllers/stamp_composer_controller.dart';
import 'package:inkstamp/features/stamps/presentation/controllers/stamp_timeline_controller.dart';

import '../stamps/post_capture_flow_test.dart'
    show FlowStampRepository, flowStamp;
import 'session_controller_test.dart' show FakeAuthenticationRepository;

class StreamAuth extends FakeAuthenticationRepository {
  final events = StreamController<AppUser?>.broadcast();
  Future<void> close() => events.close();
  final emails = <String>[];
  Completer<AppUser>? pending;
  @override
  Stream<AppUser?> authStateChanges() => events.stream;
  @override
  Future<AppUser> signInForDevelopment({
    required String email,
    required String password,
  }) async {
    emails.add(email);
    if (pending != null) return pending!.future;
    return user = AppUser(
      id: email,
      username: email,
      displayName: email,
      onboardingComplete: true,
      onboardingStep: UserOnboardingStep.complete,
    );
  }
}

class UnusedAuth extends Fake implements FirebaseAuth {}

class UnusedFirestore extends Fake implements FirebaseFirestore {}

class UnusedFunctions extends Fake implements FirebaseFunctions {}

class SlowFriends extends InMemoryFriendRepository {
  Completer<List<InkstampFriend>>? pending;
  @override
  Future<List<InkstampFriend>> getFriends() async =>
      pending == null ? [] : pending!.future;
}

Future<void> flush() => Future<void>.delayed(Duration.zero);

void main() {
  test('DEV policy requires every guard and allowlisted project/account', () {
    for (final debug in [false, true]) {
      for (final environment in ['dev', 'staging', 'prod', '']) {
        for (final flag in [false, true]) {
          final policy = DevAuthPolicy(
            debug: debug,
            environment: environment,
            explicitlyEnabled: flag,
          );
          expect(policy.enabled, debug && environment == 'dev' && flag);
        }
      }
    }
    const dev = DevAuthPolicy(
      debug: true,
      environment: 'dev',
      explicitlyEnabled: true,
    );
    for (final account in DevTestAccount.values) {
      expect(
        () =>
            dev.requireAllowed(projectId: 'inkstamp-dev', email: account.email),
        returnsNormally,
      );
      expect(
        () => dev.requireAllowed(
          projectId: 'inkstamp-prod',
          email: account.email,
        ),
        throwsStateError,
      );
    }
    expect(
      () => dev.requireAllowed(
        projectId: 'inkstamp-dev',
        email: 'other@inkstamp.dev',
      ),
      throwsStateError,
    );
  });

  test('demo repository cannot impersonate a real DEV user', () async {
    await expectLater(
      InMemoryAuthenticationRepository().signInForDevelopment(
        email: DevTestAccount.a.email,
        password: 'unit-only-not-a-credential',
      ),
      throwsStateError,
    );
  });

  test('disabled build blocks repository before invoking Firebase', () async {
    if (DevAuthPolicy.current.enabled) return;
    final repo = FirebaseAuthenticationRepository(
      auth: UnusedAuth(),
      firestore: UnusedFirestore(),
      functions: UnusedFunctions(),
    );
    await expectLater(
      repo.signInForDevelopment(
        email: DevTestAccount.a.email,
        password: 'unit-only-not-a-credential',
      ),
      throwsStateError,
    );
  });

  testWidgets(
    'test login is absent in normal/prod configuration and without Firebase',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: DevTestLogin())),
      );
      expect(find.text('Login as Test A'), findsNothing);
      expect(find.text('Login as Test B'), findsNothing);
    },
  );

  testWidgets('DEV affordance obeys build flag even when Firebase is ready', (
    tester,
  ) async {
    final auth = StreamAuth();
    addTearDown(auth.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseInitializedProvider.overrideWithValue(true),
          authenticationRepositoryProvider.overrideWithValue(auth),
        ],
        child: const MaterialApp(home: Scaffold(body: DevTestLogin())),
      ),
    );
    expect(
      find.text('Login as Test A'),
      DevAuthPolicy.compiledEnabled ? findsOneWidget : findsNothing,
    );
    expect(
      find.text('Login as Test B'),
      DevAuthPolicy.compiledEnabled ? findsOneWidget : findsNothing,
    );
    if (DevAuthPolicy.compiledEnabled) {
      await tester.tap(find.text('Login as Test B'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        'unit-only-not-a-credential',
      );
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(auth.emails, [DevTestAccount.b.email]);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test(
    'auth abstraction restores external A/B changes and logout clears identity',
    () async {
      final auth = StreamAuth();
      final container = ProviderContainer(
        overrides: [authenticationRepositoryProvider.overrideWithValue(auth)],
      );
      addTearDown(container.dispose);
      addTearDown(auth.close);
      container.read(sessionControllerProvider);
      for (final id in ['real-unit-A', 'real-unit-B']) {
        auth.events.add(
          AppUser(
            id: id,
            username: id,
            displayName: id,
            onboardingComplete: true,
            onboardingStep: UserOnboardingStep.complete,
          ),
        );
        await flush();
        expect(container.read(sessionControllerProvider).user?.id, id);
      }
      await container.read(sessionControllerProvider.notifier).signOut();
      expect(container.read(sessionControllerProvider).user, isNull);
    },
  );

  test(
    'DEV A/B login uses existing controller, resets Inbox Calendar and Friends',
    () async {
      final auth = StreamAuth();
      final stamps = FlowStampRepository()
        ..received = [flowStamp('A-only', DateTime(2026, 10, 7), own: false)];
      final friends = SlowFriends();
      final container = ProviderContainer(
        overrides: [
          authenticationRepositoryProvider.overrideWithValue(auth),
          stampRepositoryProvider.overrideWithValue(stamps),
          friendRepositoryProvider.overrideWithValue(friends),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(auth.close);
      final controller = container.read(sessionControllerProvider.notifier);
      if (!DevAuthPolicy.current.enabled) {
        await expectLater(
          controller.signInForDevelopment(
            DevTestAccount.a,
            password: 'unit-only',
          ),
          throwsStateError,
        );
        expect(auth.emails, isEmpty);
        return;
      }
      await controller.signInForDevelopment(
        DevTestAccount.a,
        password: 'unit-only',
      );
      expect(
        container.read(sessionControllerProvider).user?.id,
        DevTestAccount.a.email,
      );
      container
          .read(stampComposerControllerProvider.notifier)
          .capture(
            localImagePath: 'unit-A-private-photo',
            localThumbnailPath: 'unit-A-private-thumb',
          );
      final inboxSub = container.listen(inboxControllerProvider, (_, _) {});
      final friendsSub = container.listen(friendsControllerProvider, (_, _) {});
      final month = calendarMonthProvider(DateTime(2026, 10));
      final monthSub = container.listen(month, (_, _) {});
      addTearDown(inboxSub.close);
      addTearDown(friendsSub.close);
      addTearDown(monthSub.close);
      await container.read(month.future);
      await flush();
      expect(container.read(inboxControllerProvider).items.single.id, 'A-only');
      final old = Completer<List<InkstampFriend>>();
      friends.pending = old;
      final oldLoad = container.read(friendsControllerProvider.notifier).load();
      await controller.signOut();
      expect(
        container.read(stampComposerControllerProvider).localImagePath,
        isNull,
      );
      expect(
        container.read(stampComposerControllerProvider).selectedRecipientIds,
        isEmpty,
      );
      expect(container.read(inboxControllerProvider).items, isEmpty);
      friends.pending = null;
      stamps.received = [
        flowStamp('B-only', DateTime(2026, 10, 7), own: false),
      ];
      await controller.signInForDevelopment(
        DevTestAccount.b,
        password: 'unit-only',
      );
      expect(
        container.read(sessionControllerProvider).user?.id,
        DevTestAccount.b.email,
      );
      await container.read(month.future);
      await flush();
      old.complete([
        const InkstampFriend(
          id: 'A-private',
          username: 'A-private',
          displayName: 'A-private',
          status: FriendStatus.accepted,
        ),
      ]);
      await oldLoad;
      expect(container.read(friendsControllerProvider).friends, isEmpty);
      expect(container.read(inboxControllerProvider).items.single.id, 'B-only');
      expect(container.read(month).value!.single.id, 'B-only');
      expect(auth.emails, [DevTestAccount.a.email, DevTestAccount.b.email]);
    },
  );
}
