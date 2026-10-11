import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:inkstamp/core/config/functions_backend.dart';
import 'package:inkstamp/features/friends/domain/entities/friend.dart';
import 'package:inkstamp/features/friends/domain/repositories/friend_repository.dart';

class FirebaseFriendRepository implements FriendRepository {
  FirebaseFriendRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _functions = functions ?? FunctionsBackend.create();

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  String get _userId {
    final String? uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('A signed-in user is required.');
    return uid;
  }

  @override
  Future<List<InkstampFriend>> getFriends() async {
    final String uid = _userId;
    final (
      QuerySnapshot<Map<String, dynamic>> friendships,
      QuerySnapshot<Map<String, dynamic>> closeFriends,
    ) = await (
      _firestore
          .collection('friendships')
          .where('members', arrayContains: uid)
          .where('status', isEqualTo: 'accepted')
          .get()
          .timeout(const Duration(seconds: 20)),
      _firestore
          .collection('users/$uid/closeFriends')
          .get()
          .timeout(const Duration(seconds: 20)),
    ).wait;
    final Set<String> closeFriendIds = closeFriends.docs
        .map((snapshot) => snapshot.id)
        .toSet();
    return friendships.docs
        .map((snapshot) => _fromFriendship(snapshot, uid))
        .map(
          (friend) => friend.copyWith(
            isCloseFriend: closeFriendIds.contains(friend.id),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<InkstampFriend>> getRequests() async {
    final String uid = _userId;
    final QuerySnapshot<Map<String, dynamic>> snapshots = await _firestore
        .collection('friendships')
        .where('members', arrayContains: uid)
        .where('status', isEqualTo: 'pending')
        .get()
        .timeout(const Duration(seconds: 20));
    return snapshots.docs
        .where((snapshot) => snapshot.data()['requestedTo'] == uid)
        .map((snapshot) => _fromFriendship(snapshot, uid))
        .toList(growable: false);
  }

  @override
  Future<List<InkstampFriend>> getBlocked() async {
    final String uid = _userId;
    final QuerySnapshot<Map<String, dynamic>> snapshots = await _firestore
        .collection('friendships')
        .where('members', arrayContains: uid)
        .where('status', isEqualTo: 'blocked')
        .get()
        .timeout(const Duration(seconds: 20));
    return snapshots.docs
        .where((snapshot) => snapshot.data()['blockedBy'] == uid)
        .map((snapshot) => _fromFriendship(snapshot, uid))
        .toList(growable: false);
  }

  @override
  Future<List<InkstampFriend>> search(String query) async {
    final String normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return const <InkstampFriend>[];
    final HttpsCallableResult<Map<String, dynamic>> result = await _functions
        .httpsCallable('findUserByUsername')
        .call<Map<String, dynamic>>(<String, String>{'username': normalized});
    final Object? rawUser = result.data['user'];
    if (rawUser is! Map) return const <InkstampFriend>[];
    final Map<String, dynamic> user = Map<String, dynamic>.from(rawUser);
    return <InkstampFriend>[
      InkstampFriend(
        id: user['id'] as String,
        username: user['username'] as String,
        displayName: user['displayName'] as String,
        status: switch (user['relationshipStatus']) {
          'accepted' => FriendStatus.accepted,
          'pending' => FriendStatus.pending,
          'blocked' => FriendStatus.blocked,
          _ => FriendStatus.none,
        },
        isIncomingRequest: user['isIncomingRequest'] == true,
      ),
    ];
  }

  @override
  Future<void> sendRequest(InkstampFriend friend) async {
    await _functions.httpsCallable('sendFriendRequest').call<void>(
      <String, String>{'username': friend.username},
    );
  }

  @override
  Future<void> respondToRequest(String userId, {required bool accept}) async {
    await _functions.httpsCallable('respondFriendRequest').call<void>(
      <String, Object>{'userId': userId, 'accept': accept},
    );
  }

  @override
  Future<void> removeFriend(String userId) =>
      _callWithUserId('removeFriend', userId);

  @override
  Future<void> updateCloseFriend(
    String friendId, {
    required bool enabled,
  }) async {
    await _functions.httpsCallable('updateCloseFriends').call<void>(
      <String, Object>{'friendId': friendId, 'enabled': enabled},
    );
  }

  @override
  Future<void> blockUser(String userId) => _callWithUserId('blockUser', userId);

  @override
  Future<void> unblockUser(String userId) =>
      _callWithUserId('unblockUser', userId);

  Future<void> _callWithUserId(String name, String userId) async {
    await _functions.httpsCallable(name).call<void>(<String, String>{
      'userId': userId,
    });
  }

  InkstampFriend _fromFriendship(
    QueryDocumentSnapshot<Map<String, dynamic>> snapshot,
    String uid,
  ) {
    final Map<String, dynamic> data = snapshot.data();
    final List<String> members = List<String>.from(data['members'] as List);
    final String friendId = members.firstWhere((member) => member != uid);
    final Map<String, dynamic> profiles = Map<String, dynamic>.from(
      data['memberProfiles'] as Map? ?? const <String, dynamic>{},
    );
    final Map<String, dynamic> profile = Map<String, dynamic>.from(
      profiles[friendId] as Map? ?? const <String, dynamic>{},
    );
    return InkstampFriend(
      id: friendId,
      username: profile['username'] as String? ?? '',
      displayName: profile['displayName'] as String? ?? 'Inkstamp user',
      status: switch (data['status']) {
        'accepted' => FriendStatus.accepted,
        'blocked' => FriendStatus.blocked,
        _ => FriendStatus.pending,
      },
      isIncomingRequest: data['requestedTo'] == uid,
    );
  }
}
