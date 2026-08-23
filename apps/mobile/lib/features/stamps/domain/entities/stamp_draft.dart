import 'package:inkstamp/features/stamps/domain/entities/stamp.dart';

class StampDraft {
  const StampDraft({
    required this.seed,
    required this.frameStyle,
    required this.paperTone,
    required this.audience,
    this.selectedRecipientIds = const <String>{},
    this.replyToStampId,
  });

  factory StampDraft.initial() {
    return StampDraft(
      seed: DateTime.now().millisecondsSinceEpoch,
      frameStyle: StampFrameStyle.classic,
      paperTone: PaperTone.cream,
      audience: AudienceMode.allFriends,
    );
  }

  final int seed;
  final StampFrameStyle frameStyle;
  final PaperTone paperTone;
  final AudienceMode audience;
  final Set<String> selectedRecipientIds;
  final String? replyToStampId;

  StampDraft copyWith({
    int? seed,
    StampFrameStyle? frameStyle,
    PaperTone? paperTone,
    AudienceMode? audience,
    Set<String>? selectedRecipientIds,
    String? replyToStampId,
    bool clearReply = false,
  }) {
    return StampDraft(
      seed: seed ?? this.seed,
      frameStyle: frameStyle ?? this.frameStyle,
      paperTone: paperTone ?? this.paperTone,
      audience: audience ?? this.audience,
      selectedRecipientIds: selectedRecipientIds ?? this.selectedRecipientIds,
      replyToStampId: clearReply ? null : replyToStampId ?? this.replyToStampId,
    );
  }
}
