import 'package:inkstamp/features/friends/domain/entities/friend.dart';

abstract interface class FriendRepository {
  Future<List<InkstampFriend>> getFriends();

  Future<List<InkstampFriend>> getRequests();

  Future<List<InkstampFriend>> search(String query);
}
