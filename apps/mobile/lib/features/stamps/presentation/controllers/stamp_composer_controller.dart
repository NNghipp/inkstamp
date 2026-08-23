import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkstamp/features/stamps/domain/entities/stamp.dart';
import 'package:inkstamp/features/stamps/domain/entities/stamp_draft.dart';

final NotifierProvider<StampComposerController, StampDraft>
stampComposerControllerProvider =
    NotifierProvider<StampComposerController, StampDraft>(
      StampComposerController.new,
    );

class StampComposerController extends Notifier<StampDraft> {
  @override
  StampDraft build() => StampDraft.initial();

  void capture({String? replyToStampId}) {
    state = StampDraft.initial().copyWith(replyToStampId: replyToStampId);
  }

  void setFrame(StampFrameStyle style) {
    state = state.copyWith(frameStyle: style);
  }

  void setPaperTone(PaperTone tone) {
    state = state.copyWith(paperTone: tone);
  }

  void setAudience(AudienceMode audience) {
    state = state.copyWith(
      audience: audience,
      selectedRecipientIds: audience == AudienceMode.selected
          ? state.selectedRecipientIds
          : {},
    );
  }

  void toggleRecipient(String friendId) {
    final Set<String> selected = <String>{...state.selectedRecipientIds};
    if (!selected.add(friendId)) {
      selected.remove(friendId);
    }
    state = state.copyWith(
      audience: AudienceMode.selected,
      selectedRecipientIds: selected,
    );
  }
}
