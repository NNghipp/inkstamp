import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:inkstamp/features/stamps/domain/entities/stamp.dart';
import 'package:inkstamp/features/stamps/domain/entities/stamp_draft.dart';
import 'package:inkstamp/features/stamps/domain/repositories/stamp_repository.dart';
import 'package:uuid/uuid.dart';

class FirebaseStampRepository implements StampRepository {
  FirebaseStampRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _functions = functions ?? FirebaseFunctions.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;
  final Uuid _uuid = const Uuid();

  String get _userId {
    final String? value = _auth.currentUser?.uid;
    if (value == null) throw StateError('Authentication is required.');
    return value;
  }

  @override
  Future<List<Stamp>> getReceived() async {
    final snapshot = await _firestore
        .collection('users/$_userId/deliveries')
        .get();
    final stamps = snapshot.docs
        .map((doc) => _fromData(doc.id, doc.data(), false))
        .toList();
    stamps.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return stamps;
  }

  @override
  Future<List<Stamp>> getSent() async {
    final snapshot = await _firestore
        .collection('stamps')
        .where('senderId', isEqualTo: _userId)
        .get();
    final stamps = snapshot.docs
        .map((doc) => _fromData(doc.id, doc.data(), true))
        .toList();
    stamps.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return stamps;
  }

  @override
  Future<Stamp> publish({
    required StampDraft draft,
    required List<String> recipientIds,
  }) async {
    final String? imageId = draft.cloudinaryPublicId;
    final String? thumbnailId = draft.cloudinaryThumbnailPublicId;
    if (imageId == null || thumbnailId == null) {
      throw StateError('Upload both media files before publishing.');
    }
    final String requestId = _uuid.v5(
      Namespace.url.value,
      'inkstamp://publish/$_userId/$imageId/$thumbnailId',
    );
    final result = await _functions
        .httpsCallable('publishStamp')
        .call<Map<String, dynamic>>({
          'requestId': requestId,
          'cloudinaryPublicId': imageId,
          'cloudinaryThumbnailPublicId': thumbnailId,
          'audience': draft.audience.name,
          'selectedRecipientIds': recipientIds,
          if (draft.replyToStampId != null)
            'replyToStampId': draft.replyToStampId,
          'frameStyle': draft.frameStyle.name,
          'paperTone': draft.paperTone.name,
          'captureLocalDate': DateTime.now().toIso8601String().substring(0, 10),
          'timezoneOffsetMinutes': DateTime.now().timeZoneOffset.inMinutes,
        });
    final String stampId = result.data['stampId'] as String;
    return Stamp(
      id: stampId,
      senderId: _userId,
      senderName: 'You',
      createdAt: DateTime.now(),
      seed: draft.seed,
      frameStyle: draft.frameStyle,
      paperTone: draft.paperTone,
      isSentByMe: true,
      replyToStampId: draft.replyToStampId,
      cloudinaryPublicId: imageId,
      cloudinaryThumbnailPublicId: thumbnailId,
    );
  }

  Stamp _fromData(String id, Map<String, dynamic> data, bool isSentByMe) {
    final Timestamp? timestamp = data['createdAt'] as Timestamp?;
    return Stamp(
      id: id,
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? 'Friend',
      createdAt: timestamp?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
      seed: id.hashCode,
      frameStyle: StampFrameStyle.values.byName(
        data['frameStyle'] as String? ?? 'classic',
      ),
      paperTone: PaperTone.values.byName(
        data['paperTone'] as String? ?? 'cream',
      ),
      isSentByMe: isSentByMe,
      isSeen: data['isSeen'] as bool? ?? false,
      replyToStampId: data['replyToStampId'] as String?,
      cloudinaryPublicId: data['cloudinaryPublicId'] as String?,
      cloudinaryThumbnailPublicId:
          data['cloudinaryThumbnailPublicId'] as String?,
    );
  }
}
