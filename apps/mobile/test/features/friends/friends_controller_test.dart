import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkstamp/features/friends/presentation/controllers/friends_controller.dart';

void main() {
  test('declining a request removes it from pending state', () async {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(friendsControllerProvider.notifier).load();
    final String requestId = container
        .read(friendsControllerProvider)
        .requests
        .first
        .id;

    await container
        .read(friendsControllerProvider.notifier)
        .declineRequest(requestId);

    expect(
      container
          .read(friendsControllerProvider)
          .requests
          .any((friend) => friend.id == requestId),
      isFalse,
    );
  });

  test('accepting a request creates one accepted friend', () async {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(friendsControllerProvider.notifier).load();
    final String requestId = container
        .read(friendsControllerProvider)
        .requests
        .first
        .id;

    expect(
      await container
          .read(friendsControllerProvider.notifier)
          .acceptRequest(requestId),
      isTrue,
    );
    final FriendsState state = container.read(friendsControllerProvider);
    expect(state.requests.any((friend) => friend.id == requestId), isFalse);
    expect(
      state.friends.where((friend) => friend.id == requestId),
      hasLength(1),
    );
  });

  test('close-friend and removal mutations persist through reload', () async {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(friendsControllerProvider.notifier).load();
    final String friendId = container
        .read(friendsControllerProvider)
        .friends
        .firstWhere((friend) => !friend.isCloseFriend)
        .id;

    expect(
      await container
          .read(friendsControllerProvider.notifier)
          .toggleCloseFriend(friendId),
      isTrue,
    );
    await container.read(friendsControllerProvider.notifier).load();
    expect(
      container
          .read(friendsControllerProvider)
          .friends
          .firstWhere((friend) => friend.id == friendId)
          .isCloseFriend,
      isTrue,
    );

    expect(
      await container
          .read(friendsControllerProvider.notifier)
          .removeFriend(friendId),
      isTrue,
    );
    await container.read(friendsControllerProvider.notifier).load();
    expect(
      container
          .read(friendsControllerProvider)
          .friends
          .any((friend) => friend.id == friendId),
      isFalse,
    );
  });
}
