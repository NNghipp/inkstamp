import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:inkstamp/features/authentication/data/repositories/current_auth_profiles.dart';
import 'package:inkstamp/features/authentication/domain/entities/app_user.dart';

AppUser profile(String uid) =>
    AppUser(id: uid, username: uid, displayName: uid, onboardingComplete: true);

void main() {
  for (final fails in [false, true]) {
    test(
      'stale profile ${fails ? 'error' : 'result'} and queued logout cannot clear B',
      () async {
        var current = 'a';
        final source = StreamController<String?>();
        final started = Completer<void>();
        final pending = Completer<AppUser>();
        final results = currentAuthProfiles(
          authUids: source.stream,
          currentUid: () => current,
          loadProfile: (uid) {
            if (uid == 'a') {
              started.complete();
              return pending.future;
            }
            return Future.value(profile(uid));
          },
        ).toList();
        source.add('a');
        await started.future;
        current = 'b';
        source.add(null);
        source.add('b');
        if (fails) {
          pending.completeError(StateError('stale profile denied'));
        } else {
          pending.complete(profile('a'));
        }
        await source.close();
        expect((await results).map((user) => user?.id), ['b']);
      },
    );
  }
  test('current profile errors remain observable', () async {
    await expectLater(
      currentAuthProfiles(
        authUids: Stream.value('b'),
        currentUid: () => 'b',
        loadProfile: (_) => Future.error(StateError('current profile denied')),
      ),
      emitsError(isA<StateError>()),
    );
  });
  test('real current logout emits null', () async {
    expect(
      await currentAuthProfiles(
        authUids: Stream<String?>.value(null),
        currentUid: () => null,
        loadProfile: (uid) => Future.value(profile(uid)),
      ).toList(),
      [null],
    );
  });
}
