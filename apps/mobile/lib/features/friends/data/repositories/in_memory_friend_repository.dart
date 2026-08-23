import 'package:inkstamp/features/friends/domain/entities/friend.dart';
import 'package:inkstamp/features/friends/domain/repositories/friend_repository.dart';

class InMemoryFriendRepository implements FriendRepository {
  static const List<InkstampFriend> _people = <InkstampFriend>[
    InkstampFriend(
      id: 'mai',
      username: 'mai.paper',
      displayName: 'Mai',
      status: FriendStatus.accepted,
      isCloseFriend: true,
    ),
    InkstampFriend(
      id: 'linh',
      username: 'linhblue',
      displayName: 'Linh',
      status: FriendStatus.accepted,
      isCloseFriend: true,
    ),
    InkstampFriend(
      id: 'minh',
      username: 'minh.frames',
      displayName: 'Minh',
      status: FriendStatus.accepted,
    ),
    InkstampFriend(
      id: 'an',
      username: 'an.daylight',
      displayName: 'An',
      status: FriendStatus.accepted,
    ),
    InkstampFriend(
      id: 'vy',
      username: 'vy.archive',
      displayName: 'Vy',
      status: FriendStatus.pending,
    ),
    InkstampFriend(
      id: 'khoa',
      username: 'khoa.film',
      displayName: 'Khoa',
      status: FriendStatus.pending,
    ),
  ];

  @override
  Future<List<InkstampFriend>> getFriends() async {
    return _people
        .where((InkstampFriend friend) {
          return friend.status == FriendStatus.accepted;
        })
        .toList(growable: false);
  }

  @override
  Future<List<InkstampFriend>> getRequests() async {
    return _people
        .where((InkstampFriend friend) {
          return friend.status == FriendStatus.pending;
        })
        .toList(growable: false);
  }

  @override
  Future<List<InkstampFriend>> search(String query) async {
    final String normalized = query.trim().toLowerCase();
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (normalized.isEmpty) {
      return const <InkstampFriend>[];
    }
    return _people
        .where((InkstampFriend friend) {
          return friend.username.contains(normalized) ||
              friend.displayName.toLowerCase().contains(normalized);
        })
        .toList(growable: false);
  }
}
