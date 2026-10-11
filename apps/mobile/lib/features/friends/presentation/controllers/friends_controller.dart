import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkstamp/features/authentication/presentation/controllers/session_controller.dart';
import 'package:inkstamp/features/friends/data/repositories/firebase_friend_repository.dart';
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
    this.busyUserIds = const <String>{},
    this.errorMessage,
  });

  final List<InkstampFriend> friends;
  final List<InkstampFriend> requests;
  final List<InkstampFriend> searchResults;
  final List<InkstampFriend> blocked;
  final bool isLoading;
  final Set<String> busyUserIds;
  final String? errorMessage;

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
    Set<String>? busyUserIds,
    String? errorMessage,
    bool clearError = false,
  }) {
    return FriendsState(
      friends: friends ?? this.friends,
      requests: requests ?? this.requests,
      searchResults: searchResults ?? this.searchResults,
      blocked: blocked ?? this.blocked,
      isLoading: isLoading ?? this.isLoading,
      busyUserIds: busyUserIds ?? this.busyUserIds,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

final Provider<FriendRepository> friendRepositoryProvider =
    Provider<FriendRepository>((Ref ref) {
      return ref.watch(firebaseInitializedProvider)
          ? FirebaseFriendRepository()
          : InMemoryFriendRepository();
    });

final NotifierProvider<FriendsController, FriendsState>
friendsControllerProvider = NotifierProvider<FriendsController, FriendsState>(
  FriendsController.new,
);

class FriendsController extends Notifier<FriendsState> {
  int _generation = 0;
  bool _current(int generation) => ref.mounted && generation == _generation;
  FriendRepository get _repository => ref.read(friendRepositoryProvider);

  @override
  FriendsState build() {
    ref.watch(sessionControllerProvider.select((s) => s.user?.id));
    _generation++;
    Future<void>.microtask(load);
    return const FriendsState(isLoading: true);
  }

  Future<void> load() async {
    final generation = _generation;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final (
        List<InkstampFriend> friends,
        List<InkstampFriend> requests,
        List<InkstampFriend> blocked,
      ) = await (
        _repository.getFriends(),
        _repository.getRequests(),
        _repository.getBlocked(),
      ).wait;
      if (!_current(generation)) return;
      state = state.copyWith(
        friends: friends,
        requests: requests,
        blocked: blocked,
        isLoading: false,
      );
    } on Object {
      if (!_current(generation)) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to load friends. Please try again.',
      );
    }
  }

  Future<void> search(String query) async {
    final generation = _generation;
    final String normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      state = state.copyWith(searchResults: const <InkstampFriend>[]);
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final List<InkstampFriend> results = await _repository.search(normalized);
      if (!_current(generation)) return;
      final List<InkstampFriend> known = <InkstampFriend>[
        ...state.friends,
        ...state.requests,
        ...state.blocked,
      ];
      state = state.copyWith(
        searchResults: results
            .map((result) {
              return known.where((item) => item.id == result.id).firstOrNull ??
                  result;
            })
            .toList(growable: false),
        isLoading: false,
      );
    } on Object {
      if (!_current(generation)) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to search right now. Please try again.',
      );
    }
  }

  Future<bool> sendRequest(InkstampFriend friend) async {
    final generation = _generation;
    return _runForUser(friend.id, () async {
      await _repository.sendRequest(friend);
      if (!_current(generation)) return;
      state = state.copyWith(
        searchResults: state.searchResults
            .map(
              (item) => item.id == friend.id
                  ? item.copyWith(
                      status: FriendStatus.pending,
                      isIncomingRequest: false,
                    )
                  : item,
            )
            .toList(growable: false),
      );
    });
  }

  Future<bool> toggleCloseFriend(String friendId) async {
    final generation = _generation;
    final InkstampFriend friend = state.friends.firstWhere(
      (item) => item.id == friendId,
    );
    final bool enabled = !friend.isCloseFriend;
    return _runForUser(friendId, () async {
      await _repository.updateCloseFriend(friendId, enabled: enabled);
      if (!_current(generation)) return;
      state = state.copyWith(
        friends: state.friends
            .map(
              (item) => item.id == friendId
                  ? item.copyWith(isCloseFriend: enabled)
                  : item,
            )
            .toList(growable: false),
      );
    });
  }

  Future<bool> acceptRequest(String friendId) =>
      _respondToRequest(friendId, accept: true);

  Future<bool> declineRequest(String friendId) =>
      _respondToRequest(friendId, accept: false);

  Future<bool> _respondToRequest(
    String friendId, {
    required bool accept,
  }) async {
    final generation = _generation;
    final InkstampFriend? request = state.requests
        .where((friend) => friend.id == friendId)
        .firstOrNull;
    if (request == null) return false;
    return _runForUser(friendId, () async {
      await _repository.respondToRequest(friendId, accept: accept);
      if (!_current(generation)) return;
      state = state.copyWith(
        friends: accept
            ? <InkstampFriend>[
                ...state.friends.where((friend) => friend.id != friendId),
                request.copyWith(
                  status: FriendStatus.accepted,
                  isIncomingRequest: false,
                ),
              ]
            : state.friends,
        requests: state.requests
            .where((friend) => friend.id != friendId)
            .toList(growable: false),
      );
    });
  }

  Future<bool> removeFriend(String friendId) async {
    final generation = _generation;
    return _runForUser(friendId, () async {
      await _repository.removeFriend(friendId);
      if (!_current(generation)) return;
      state = state.copyWith(
        friends: state.friends
            .where((friend) => friend.id != friendId)
            .toList(growable: false),
      );
    });
  }

  Future<bool> blockFriend(String friendId) async {
    final generation = _generation;
    final InkstampFriend friend = state.friends.firstWhere(
      (InkstampFriend item) => item.id == friendId,
    );
    return _runForUser(friendId, () async {
      await _repository.blockUser(friendId);
      if (!_current(generation)) return;
      state = state.copyWith(
        friends: state.friends
            .where((item) => item.id != friendId)
            .toList(growable: false),
        blocked: <InkstampFriend>[
          ...state.blocked.where((item) => item.id != friendId),
          friend.copyWith(status: FriendStatus.blocked, isCloseFriend: false),
        ],
      );
    });
  }

  Future<bool> unblockFriend(String friendId) async {
    final generation = _generation;
    return _runForUser(friendId, () async {
      await _repository.unblockUser(friendId);
      if (!_current(generation)) return;
      state = state.copyWith(
        blocked: state.blocked
            .where((item) => item.id != friendId)
            .toList(growable: false),
      );
    });
  }

  Future<bool> _runForUser(
    String userId,
    Future<void> Function() operation,
  ) async {
    final generation = _generation;
    if (state.busyUserIds.contains(userId)) return false;
    state = state.copyWith(
      busyUserIds: <String>{...state.busyUserIds, userId},
      clearError: true,
    );
    try {
      await operation();
      if (!_current(generation)) return false;
      state = state.copyWith(
        busyUserIds: {...state.busyUserIds}..remove(userId),
      );
      return true;
    } on Object {
      if (!_current(generation)) return false;
      state = state.copyWith(
        busyUserIds: {...state.busyUserIds}..remove(userId),
        errorMessage: 'Unable to update this connection. Please try again.',
      );
      return false;
    }
  }
}
