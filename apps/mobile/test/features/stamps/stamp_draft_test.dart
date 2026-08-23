import 'package:flutter_test/flutter_test.dart';
import 'package:inkstamp/features/stamps/domain/entities/stamp.dart';
import 'package:inkstamp/features/stamps/domain/entities/stamp_draft.dart';

void main() {
  group('StampDraft', () {
    test('starts with the MVP defaults', () {
      final StampDraft draft = StampDraft.initial();

      expect(draft.frameStyle, StampFrameStyle.classic);
      expect(draft.paperTone, PaperTone.cream);
      expect(draft.audience, AudienceMode.allFriends);
      expect(draft.selectedRecipientIds, isEmpty);
    });

    test('copyWith keeps unrelated fields immutable', () {
      final StampDraft draft = StampDraft.initial();
      final StampDraft updated = draft.copyWith(
        paperTone: PaperTone.sky,
        selectedRecipientIds: <String>{'mai', 'linh'},
      );

      expect(updated.paperTone, PaperTone.sky);
      expect(updated.frameStyle, draft.frameStyle);
      expect(updated.seed, draft.seed);
      expect(updated.selectedRecipientIds, <String>{'mai', 'linh'});
    });
  });

  test('reaction types have the expected private-social emoji', () {
    expect(ReactionType.heart.emoji, '❤️');
    expect(ReactionType.emotional.emoji, '🥹');
    expect(ReactionType.fire.emoji, '🔥');
  });
}
