enum FriendStatus { pending, accepted, blocked }

class InkstampFriend {
  const InkstampFriend({
    required this.id,
    required this.username,
    required this.displayName,
    required this.status,
    this.isCloseFriend = false,
  });

  final String id;
  final String username;
  final String displayName;
  final FriendStatus status;
  final bool isCloseFriend;

  InkstampFriend copyWith({FriendStatus? status, bool? isCloseFriend}) {
    return InkstampFriend(
      id: id,
      username: username,
      displayName: displayName,
      status: status ?? this.status,
      isCloseFriend: isCloseFriend ?? this.isCloseFriend,
    );
  }
}
