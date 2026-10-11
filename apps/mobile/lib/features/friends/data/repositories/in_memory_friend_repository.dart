import 'package:inkstamp/features/friends/domain/entities/friend.dart';
import 'package:inkstamp/features/friends/domain/repositories/friend_repository.dart';

class InMemoryFriendRepository implements FriendRepository {
  InMemoryFriendRepository()
    : _people = <InkstampFriend>[
        const InkstampFriend(
          id: 'mai',
          username: 'mai.paper',
          displayName: 'Mai',
          status: FriendStatus.accepted,
          isCloseFriend: true,
        ),
        const InkstampFriend(
          id: 'linh',
          username: 'linhblue',
          displayName: 'Linh',
          status: FriendStatus.accepted,
          isCloseFriend: true,
        ),
        const InkstampFriend(
          id: 'minh',
          username: 'minh.frames',
          displayName: 'Minh',
          status: FriendStatus.accepted,
        ),
        const InkstampFriend(
          id: 'an',
          username: 'an.daylight',
          displayName: 'An',
          status: FriendStatus.accepted,
        ),
        const InkstampFriend(
          id: 'vy',
          username: 'vy.archive',
          displayName: 'Vy',
          status: FriendStatus.pending,
          isIncomingRequest: true,
        ),
        const InkstampFriend(
          id: 'khoa',
          username: 'khoa.film',
          displayName: 'Khoa',
          status: FriendStatus.pending,
          isIncomingRequest: true,
        ),
      ];

  final List<InkstampFriend> _people;

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
          return friend.status == FriendStatus.pending &&
              friend.isIncomingRequest;
        })
        .toList(growable: false);
  }

  @override
  Future<List<InkstampFriend>> getBlocked() async => _people
      .where((InkstampFriend friend) => friend.status == FriendStatus.blocked)
      .toList(growable: false);

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

  @override
  Future<void> sendRequest(InkstampFriend friend) async {
    final int index = _people.indexWhere((item) => item.id == friend.id);
    final InkstampFriend pending = friend.copyWith(
      status: FriendStatus.pending,
      isIncomingRequest: false,
    );
    if (index == -1) {
      _people.add(pending);
    } else {
      _people[index] = pending;
    }
  }

  @override
  Future<void> respondToRequest(String userId, {required bool accept}) async {
    final int index = _people.indexWhere((item) => item.id == userId);
    if (index == -1) return;
    if (accept) {
      _people[index] = _people[index].copyWith(
        status: FriendStatus.accepted,
        isIncomingRequest: false,
      );
    } else {
      _people.removeAt(index);
    }
  }

  @override
  Future<void> removeFriend(String userId) async {
    _people.removeWhere((item) => item.id == userId);
  }

  @override
  Future<void> updateCloseFriend(
    String friendId, {
    required bool enabled,
  }) async {
    final int index = _people.indexWhere((item) => item.id == friendId);
    if (index != -1) {
      _people[index] = _people[index].copyWith(isCloseFriend: enabled);
    }
  }

  @override
  Future<void> blockUser(String userId) async {
    final int index = _people.indexWhere((item) => item.id == userId);
    if (index != -1) {
      _people[index] = _people[index].copyWith(
        status: FriendStatus.blocked,
        isCloseFriend: false,
      );
    }
  }

  @override
  Future<void> unblockUser(String userId) async {
    _people.removeWhere((item) => item.id == userId);
  }
}
