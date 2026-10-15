import 'package:inkstamp/features/stamps/domain/entities/stamp.dart';
import 'package:inkstamp/features/stamps/domain/entities/stamp_draft.dart';
import 'package:inkstamp/features/stamps/domain/repositories/stamp_repository.dart';
import 'package:uuid/uuid.dart';

class InMemoryStampRepository implements StampRepository {
  InMemoryStampRepository()
    : _received = <Stamp>[
        Stamp(
          id: 'stamp-mai',
          senderId: 'mai',
          senderName: 'Mai',
          createdAt: DateTime.now().subtract(const Duration(minutes: 8)),
          seed: 14,
          frameStyle: StampFrameStyle.classic,
          paperTone: PaperTone.sky,
          isSentByMe: false,
        ),
        Stamp(
          id: 'stamp-linh',
          senderId: 'linh',
          senderName: 'Linh',
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
          seed: 27,
          frameStyle: StampFrameStyle.soft,
          paperTone: PaperTone.blush,
          isSentByMe: false,
          isSeen: true,
          reaction: ReactionType.heart,
        ),
        Stamp(
          id: 'stamp-an',
          senderId: 'an',
          senderName: 'An',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          seed: 38,
          frameStyle: StampFrameStyle.mini,
          paperTone: PaperTone.mint,
          isSentByMe: false,
          isSeen: true,
        ),
      ],
      _sent = <Stamp>[
        Stamp(
          id: 'sent-yesterday',
          senderId: 'current-user',
          senderName: 'You',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          seed: 52,
          frameStyle: StampFrameStyle.bold,
          paperTone: PaperTone.cream,
          isSentByMe: true,
        ),
        Stamp(
          id: 'sent-week',
          senderId: 'current-user',
          senderName: 'You',
          createdAt: DateTime.now().subtract(const Duration(days: 4)),
          seed: 67,
          frameStyle: StampFrameStyle.classic,
          paperTone: PaperTone.lilac,
          isSentByMe: true,
        ),
      ];

  final List<Stamp> _received;
  final List<Stamp> _sent;
  final Uuid _uuid = const Uuid();

  @override
  Future<StampPage> fetchReceivedPage({
    StampCursor? after,
    int limit = 25,
  }) async => pageStamps(_received, after, limit);

  @override
  Future<List<Stamp>> fetchMonth(DateTime start, DateTime end) async =>
      [..._received, ..._sent]
          .where(
            (s) => !s.createdAt.isBefore(start) && s.createdAt.isBefore(end),
          )
          .toList()
        ..sort(compareStamps);

  @override
  Future<Stamp?> getById(String id) async {
    for (final stamp in [..._received, ..._sent]) {
      if (stamp.id == id) return stamp;
    }
    return null;
  }

  @override
  Future<void> markDeliveryRead(String id) async {
    final index = _received.indexWhere((s) => s.id == id);
    if (index >= 0) _received[index] = _received[index].copyWith(isSeen: true);
  }

  @override
  Future<List<Stamp>> getReceived() async =>
      List<Stamp>.unmodifiable(_received);

  @override
  Future<List<Stamp>> getSent() async => List<Stamp>.unmodifiable(_sent);

  @override
  Future<Stamp> publish({
    required StampDraft draft,
    required List<String> recipientIds,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 850));
    final Stamp stamp = Stamp(
      id: _uuid.v4(),
      senderId: 'current-user',
      senderName: 'You',
      createdAt: DateTime.now(),
      seed: draft.seed,
      capturedAt: draft.capturedAt,
      title: draft.title,
      locationLabel: draft.locationLabel,
      frameStyle: draft.frameStyle,
      paperTone: draft.paperTone,
      isSentByMe: true,
      replyToStampId: draft.replyToStampId,
      cloudinaryPublicId: draft.cloudinaryPublicId,
      cloudinaryThumbnailPublicId: draft.cloudinaryThumbnailPublicId,
    );
    _sent.insert(0, stamp);
    return stamp;
  }
}
