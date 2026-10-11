import 'package:inkstamp/features/friends/domain/entities/friend.dart';

abstract interface class FriendRepository {
  Future<List<InkstampFriend>> getFriends();

  Future<List<InkstampFriend>> getRequests();

  Future<List<InkstampFriend>> getBlocked();

  Future<List<InkstampFriend>> search(String query);

  Future<void> sendRequest(InkstampFriend friend);

  Future<void> respondToRequest(String userId, {required bool accept});

  Future<void> removeFriend(String userId);

  Future<void> updateCloseFriend(String friendId, {required bool enabled});

  Future<void> blockUser(String userId);

  Future<void> unblockUser(String userId);
}
