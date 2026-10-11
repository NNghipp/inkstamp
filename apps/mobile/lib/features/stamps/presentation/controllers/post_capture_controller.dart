import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkstamp/features/camera/presentation/controllers/camera_controller.dart';
import 'package:inkstamp/features/stamps/domain/entities/stamp.dart';
import 'package:inkstamp/features/stamps/domain/entities/stamp_draft.dart';
import 'package:inkstamp/features/stamps/presentation/controllers/stamp_composer_controller.dart';
import 'package:inkstamp/features/stamps/presentation/controllers/stamp_timeline_controller.dart';

enum PostCapturePhase { idle, sending, sent, failed, discarding }

final postCaptureControllerProvider =
    NotifierProvider.autoDispose<PostCaptureController, PostCapturePhase>(
      PostCaptureController.new,
    );

/// Orchestrates the existing draft, upload/publish and file lifecycle.
/// Animation timing and navigation are the presentation's responsibility.
class PostCaptureController extends Notifier<PostCapturePhase> {
  @override
  PostCapturePhase build() => PostCapturePhase.idle;

  bool get busy =>
      state == PostCapturePhase.sending ||
      state == PostCapturePhase.sent ||
      state == PostCapturePhase.discarding;

  Future<bool> send() async {
    if (busy) return false;
    final draft = ref.read(stampComposerControllerProvider);
    if (draft.localImagePath == null ||
        draft.localThumbnailPath == null ||
        (draft.audience == AudienceMode.selected &&
            draft.selectedRecipientIds.isEmpty)) {
      return false;
    }
    state = PostCapturePhase.sending;
    final stamp = await ref
        .read(stampTimelineControllerProvider.notifier)
        .publish(draft);
    if (!ref.mounted) return stamp != null;
    state = stamp == null ? PostCapturePhase.failed : PostCapturePhase.sent;
    return stamp != null;
  }

  Future<void> finish() async {
    if (state != PostCapturePhase.sent) return;
    await _clear(ref.read(stampComposerControllerProvider));
  }

  Future<bool> discard() async {
    if (busy) return false;
    state = PostCapturePhase.discarding;
    final draft = ref.read(stampComposerControllerProvider);
    final timeline = ref.read(stampTimelineControllerProvider.notifier);
    await _clear(draft);
    if (!ref.mounted) return true;
    await timeline.abandon(draft);
    return true;
  }

  Future<void> _clear(StampDraft draft) async {
    try {
      await ref.read(imageProcessingRepositoryProvider).deleteFiles(<String?>[
        draft.localImagePath,
        draft.localThumbnailPath,
      ]);
    } on Object {
      // Stale-draft cleanup will retry. A successful publish stays successful.
    }
    if (ref.mounted &&
        ref.read(stampComposerControllerProvider).seed == draft.seed) {
      ref.read(stampComposerControllerProvider.notifier).reset();
    }
  }
}
