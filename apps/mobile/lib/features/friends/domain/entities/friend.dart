enum FriendStatus { none, pending, accepted, blocked }

class InkstampFriend {
  const InkstampFriend({
    required this.id,
    required this.username,
    required this.displayName,
    required this.status,
    this.isCloseFriend = false,
    this.isIncomingRequest = false,
  });

  final String id;
  final String username;
  final String displayName;
  final FriendStatus status;
  final bool isCloseFriend;
  final bool isIncomingRequest;

  InkstampFriend copyWith({
    FriendStatus? status,
    bool? isCloseFriend,
    bool? isIncomingRequest,
  }) {
    return InkstampFriend(
      id: id,
      username: username,
      displayName: displayName,
      status: status ?? this.status,
      isCloseFriend: isCloseFriend ?? this.isCloseFriend,
      isIncomingRequest: isIncomingRequest ?? this.isIncomingRequest,
    );
  }
}
