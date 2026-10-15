import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:inkstamp/core/config/functions_backend.dart';
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
       _functions = functions ?? FunctionsBackend.create(),
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
    return (await fetchReceivedPage()).items;
  }

  Query<Map<String, dynamic>> get _deliveries => _firestore
      .collection('users/$_userId/deliveries')
      .where('status', isEqualTo: 'available');

  Query<Map<String, dynamic>> get _sent => _firestore
      .collection('stamps')
      .where('senderId', isEqualTo: _userId)
      .where('status', isEqualTo: 'active');

  @override
  Future<StampPage> fetchReceivedPage({
    StampCursor? after,
    int limit = 25,
  }) async {
    validateStampPageRequest(after, limit);
    var query = _deliveries
        .orderBy('createdAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true);
    if (after != null) {
      query = query.startAfter([Timestamp.fromDate(after.createdAt), after.id]);
    }
    final snapshot = await query
        .limit(limit + 1)
        .get()
        .timeout(const Duration(seconds: 20));
    final items = snapshot.docs
        .take(limit)
        .map((doc) => _fromData(doc.id, doc.data(), false))
        .toList();
    return StampPage(
      items,
      snapshot.docs.length > limit
          ? StampCursor(items.last.createdAt, items.last.id)
          : null,
    );
  }

  @override
  Future<List<Stamp>> fetchMonth(DateTime start, DateTime end) async {
    Future<List<Stamp>> range(
      Query<Map<String, dynamic>> query,
      bool own,
    ) async {
      final result = await query
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThan: Timestamp.fromDate(end))
          .orderBy('createdAt', descending: true)
          .get()
          .timeout(const Duration(seconds: 20));
      return result.docs
          .map((doc) => _fromData(doc.id, doc.data(), own))
          .toList();
    }

    final (received, sent) = await (
      range(_deliveries, false),
      range(_sent, true),
    ).wait;
    return {
      ...{for (final s in received) s.id: s},
      ...{for (final s in sent) s.id: s},
    }.values.toList()..sort(compareStamps);
  }

  @override
  Future<Stamp?> getById(String id) async {
    final delivery = await _firestore
        .doc('users/$_userId/deliveries/$id')
        .get()
        .timeout(const Duration(seconds: 20));
    if (delivery.exists) {
      return delivery.data()?['status'] == 'available' &&
              delivery.data()?['cloudinaryPublicId'] is String
          ? _fromData(id, delivery.data()!, false)
          : null;
    }
    try {
      final stamp = await _firestore
          .doc('stamps/$id')
          .get()
          .timeout(const Duration(seconds: 20));
      return stamp.data()?['status'] == 'active' &&
              stamp.data()?['cloudinaryPublicId'] is String
          ? _fromData(id, stamp.data()!, true)
          : null;
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied' || error.code == 'not-found') {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<void> markDeliveryRead(String id) =>
      _firestore.doc('users/$_userId/deliveries/$id').update({'isSeen': true});

  @override
  Future<List<Stamp>> getSent() async {
    final snapshot = await _sent
        .orderBy('createdAt', descending: true)
        .get()
        .timeout(const Duration(seconds: 20));
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
          'captureLocalDate': draft.captureTime.toIso8601String().substring(
            0,
            10,
          ),
          if (draft.capturedAt != null)
            'capturedAt': draft.capturedAt!.toUtc().toIso8601String(),
          if (draft.title != null) 'title': draft.title,
          if (draft.locationLabel != null) 'locationLabel': draft.locationLabel,
          'timezoneOffsetMinutes': DateTime.now().timeZoneOffset.inMinutes,
        });
    final String stampId = result.data['stampId'] as String;
    final published = await _firestore.doc('stamps/$stampId').get();
    final publishedData = published.data();
    if (publishedData == null) throw StateError('Published stamp unavailable.');
    return Stamp(
      id: stampId,
      senderId: _userId,
      senderName: publishedData['senderName'] as String? ?? 'Bạn bè',
      createdAt: (publishedData['createdAt'] as Timestamp).toDate(),
      seed: draft.seed,
      capturedAt: draft.capturedAt,
      title: draft.title,
      locationLabel: draft.locationLabel,
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
      caption: data['caption'] as String?,
      capturedAt: (data['capturedAt'] as Timestamp?)?.toDate(),
      title: data['title'] as String?,
      locationLabel: data['locationLabel'] as String?,
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
