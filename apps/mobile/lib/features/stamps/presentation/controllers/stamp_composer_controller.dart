import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkstamp/core/observability/safe_error_reporter.dart';
import 'package:inkstamp/features/authentication/presentation/controllers/session_controller.dart';
import 'package:inkstamp/features/camera/data/repositories/local_image_processing_repository.dart';
import 'package:inkstamp/features/stamps/domain/entities/stamp.dart';
import 'package:inkstamp/features/stamps/domain/entities/stamp_draft.dart';

final NotifierProvider<StampComposerController, StampDraft>
stampComposerControllerProvider =
    NotifierProvider<StampComposerController, StampDraft>(
      StampComposerController.new,
    );

class StampComposerController extends Notifier<StampDraft> {
  List<String?> _ownedPaths = [];
  @override
  StampDraft build() {
    ref.watch(sessionControllerProvider.select((s) => s.user?.id));
    final paths = <String?>[];
    _ownedPaths = paths;
    ref.onDispose(() {
      // Runs on account change as well as scope disposal. Only this draft's
      // explicit local paths are removed; never scan/delete another directory.
      LocalImageProcessingRepository()
          .deleteFiles(paths)
          .catchError(
            (Object error, StackTrace stack) => SafeErrorReporter().report(
              ErrorEvent.draftCleanup,
              error,
              stack,
            ),
          );
    });
    return StampDraft.initial();
  }

  void beginCapture({String? replyToStampId}) {
    state = StampDraft.initial().copyWith(replyToStampId: replyToStampId);
  }

  void capture({
    String? replyToStampId,
    required String localImagePath,
    required String localThumbnailPath,
    DateTime? capturedAt,
    String? title,
    String? locationLabel,
  }) {
    _ownedPaths
      ..clear()
      ..addAll([localImagePath, localThumbnailPath]);
    state = StampDraft.initial().copyWith(
      replyToStampId: replyToStampId,
      localImagePath: localImagePath,
      localThumbnailPath: localThumbnailPath,
      capturedAt: capturedAt,
      title: title,
      locationLabel: locationLabel,
    );
  }

  void clearCapturedFiles() {
    _ownedPaths.clear();
    state = state.copyWith(clearLocalImages: true);
  }

  void reset() {
    _ownedPaths.clear();
    state = StampDraft.initial();
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
