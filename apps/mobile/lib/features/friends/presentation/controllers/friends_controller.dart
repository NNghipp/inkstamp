import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkstamp/features/friends/data/repositories/in_memory_friend_repository.dart';
import 'package:inkstamp/features/friends/domain/entities/friend.dart';
import 'package:inkstamp/features/friends/domain/repositories/friend_repository.dart';

class FriendsState {
  const FriendsState({
    this.friends = const <InkstampFriend>[],
    this.requests = const <InkstampFriend>[],
    this.searchResults = const <InkstampFriend>[],
    this.blocked = const <InkstampFriend>[],
    this.isLoading = false,
  });

  final List<InkstampFriend> friends;
  final List<InkstampFriend> requests;
  final List<InkstampFriend> searchResults;
  final List<InkstampFriend> blocked;
  final bool isLoading;

  List<InkstampFriend> get closeFriends {
    return friends
        .where((InkstampFriend friend) => friend.isCloseFriend)
        .toList(growable: false);
  }

  FriendsState copyWith({
    List<InkstampFriend>? friends,
    List<InkstampFriend>? requests,
    List<InkstampFriend>? searchResults,
    List<InkstampFriend>? blocked,
    bool? isLoading,
  }) {
    return FriendsState(
      friends: friends ?? this.friends,
      requests: requests ?? this.requests,
      searchResults: searchResults ?? this.searchResults,
      blocked: blocked ?? this.blocked,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final Provider<FriendRepository> friendRepositoryProvider =
    Provider<FriendRepository>((Ref ref) => InMemoryFriendRepository());

final NotifierProvider<FriendsController, FriendsState>
friendsControllerProvider = NotifierProvider<FriendsController, FriendsState>(
  FriendsController.new,
);

class FriendsController extends Notifier<FriendsState> {
  FriendRepository get _repository => ref.read(friendRepositoryProvider);

  @override
  FriendsState build() {
    Future<void>.microtask(load);
    return const FriendsState(isLoading: true);
  }

  Future<void> load() async {
    final (List<InkstampFriend> friends, List<InkstampFriend> requests) =
        await (_repository.getFriends(), _repository.getRequests()).wait;
    state = state.copyWith(
      friends: friends,
      requests: requests,
      isLoading: false,
    );
  }

  Future<void> search(String query) async {
    state = state.copyWith(isLoading: true);
    final List<InkstampFriend> results = await _repository.search(query);
    state = state.copyWith(searchResults: results, isLoading: false);
  }

  void toggleCloseFriend(String friendId) {
    state = state.copyWith(
      friends: state.friends
          .map((InkstampFriend friend) {
            if (friend.id != friendId) {
              return friend;
            }
            return friend.copyWith(isCloseFriend: !friend.isCloseFriend);
          })
          .toList(growable: false),
    );
  }

  void acceptRequest(String friendId) {
    final InkstampFriend request = state.requests.firstWhere(
      (InkstampFriend friend) => friend.id == friendId,
    );
    state = state.copyWith(
      friends: <InkstampFriend>[
        ...state.friends,
        request.copyWith(status: FriendStatus.accepted),
      ],
      requests: state.requests
          .where((InkstampFriend friend) => friend.id != friendId)
          .toList(growable: false),
    );
  }

  void declineRequest(String friendId) {
    state = state.copyWith(
      requests: state.requests
          .where((InkstampFriend friend) => friend.id != friendId)
          .toList(growable: false),
    );
  }

  void removeFriend(String friendId) {
    state = state.copyWith(
      friends: state.friends
          .where((InkstampFriend friend) => friend.id != friendId)
          .toList(growable: false),
    );
  }

  void blockFriend(String friendId) {
    final InkstampFriend friend = state.friends.firstWhere(
      (InkstampFriend item) => item.id == friendId,
    );
    state = state.copyWith(
      friends: state.friends
          .where((InkstampFriend item) => item.id != friendId)
          .toList(growable: false),
      blocked: <InkstampFriend>[
        ...state.blocked,
        friend.copyWith(status: FriendStatus.blocked),
      ],
    );
  }

  void unblockFriend(String friendId) {
    state = state.copyWith(
      blocked: state.blocked
          .where((InkstampFriend item) => item.id != friendId)
          .toList(growable: false),
    );
  }
}
