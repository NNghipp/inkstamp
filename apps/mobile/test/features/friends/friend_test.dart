import 'package:flutter_test/flutter_test.dart';
import 'package:inkstamp/features/friends/domain/entities/friend.dart';

void main() {
  test('close friend state is immutable', () {
    const InkstampFriend friend = InkstampFriend(
      id: 'mai',
      username: 'mai.paper',
      displayName: 'Mai',
      status: FriendStatus.accepted,
    );

    final InkstampFriend closeFriend = friend.copyWith(isCloseFriend: true);

    expect(friend.isCloseFriend, isFalse);
    expect(closeFriend.isCloseFriend, isTrue);
    expect(closeFriend.id, friend.id);
  });
}
