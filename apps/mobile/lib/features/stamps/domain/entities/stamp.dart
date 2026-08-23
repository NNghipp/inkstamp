enum AudienceMode { allFriends, closeFriends, selected }

enum StampFrameStyle { classic, soft, mini, bold }

enum PaperTone { cream, sky, blush, mint, lilac, butter }

enum ReactionType { heart, laugh, wow, emotional, fire, cry }

extension ReactionTypeX on ReactionType {
  String get emoji {
    return switch (this) {
      ReactionType.heart => '❤️',
      ReactionType.laugh => '😂',
      ReactionType.wow => '😮',
      ReactionType.emotional => '🥹',
      ReactionType.fire => '🔥',
      ReactionType.cry => '😭',
    };
  }
}

class Stamp {
  const Stamp({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.createdAt,
    required this.seed,
    required this.frameStyle,
    required this.paperTone,
    required this.isSentByMe,
    this.reaction,
    this.replyToStampId,
    this.isSeen = false,
  });

  final String id;
  final String senderId;
  final String senderName;
  final DateTime createdAt;
  final int seed;
  final StampFrameStyle frameStyle;
  final PaperTone paperTone;
  final bool isSentByMe;
  final ReactionType? reaction;
  final String? replyToStampId;
  final bool isSeen;

  Stamp copyWith({
    ReactionType? reaction,
    bool clearReaction = false,
    bool? isSeen,
  }) {
    return Stamp(
      id: id,
      senderId: senderId,
      senderName: senderName,
      createdAt: createdAt,
      seed: seed,
      frameStyle: frameStyle,
      paperTone: paperTone,
      isSentByMe: isSentByMe,
      reaction: clearReaction ? null : reaction ?? this.reaction,
      replyToStampId: replyToStampId,
      isSeen: isSeen ?? this.isSeen,
    );
  }
}
