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

    container
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
}
