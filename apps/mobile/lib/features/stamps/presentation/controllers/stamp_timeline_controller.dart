import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkstamp/features/authentication/presentation/controllers/session_controller.dart';
import 'package:inkstamp/features/friends/domain/entities/friend.dart';
import 'package:inkstamp/features/friends/presentation/controllers/friends_controller.dart';
import 'package:inkstamp/features/stamps/data/repositories/cloudinary_upload_repository.dart';
import 'package:inkstamp/features/stamps/data/repositories/firebase_stamp_repository.dart';
import 'package:inkstamp/features/stamps/data/repositories/in_memory_stamp_repository.dart';
import 'package:inkstamp/features/stamps/domain/entities/stamp.dart';
import 'package:inkstamp/features/stamps/domain/entities/stamp_draft.dart';
import 'package:inkstamp/features/stamps/domain/repositories/media_upload_repository.dart';
import 'package:inkstamp/features/stamps/domain/repositories/stamp_repository.dart';
import 'package:inkstamp/features/stamps/presentation/controllers/stamp_publication_controller.dart';

class StampTimelineState {
  const StampTimelineState({
    this.received = const <Stamp>[],
    this.sent = const <Stamp>[],
    this.isLoading = false,
    this.isPublishing = false,
    this.errorMessage,
  });

  final List<Stamp> received;
  final List<Stamp> sent;
  final bool isLoading;
  final bool isPublishing;
  final String? errorMessage;

  StampTimelineState copyWith({
    List<Stamp>? received,
    List<Stamp>? sent,
    bool? isLoading,
    bool? isPublishing,
    String? errorMessage,
    bool clearError = false,
  }) {
    return StampTimelineState(
      received: received ?? this.received,
      sent: sent ?? this.sent,
      isLoading: isLoading ?? this.isLoading,
      isPublishing: isPublishing ?? this.isPublishing,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

final Provider<StampRepository> stampRepositoryProvider =
    Provider<StampRepository>((Ref ref) {
      return ref.watch(firebaseInitializedProvider)
          ? FirebaseStampRepository()
          : InMemoryStampRepository();
    });

final NotifierProvider<StampTimelineController, StampTimelineState>
stampTimelineControllerProvider =
    NotifierProvider<StampTimelineController, StampTimelineState>(
      StampTimelineController.new,
    );

class StampTimelineController extends Notifier<StampTimelineState> {
  final Map<int, _PublishAttempt> _attempts = <int, _PublishAttempt>{};
  int _generation = 0;
  StampRepository get _repository => ref.read(stampRepositoryProvider);

  @override
  StampTimelineState build() {
    ref.watch(sessionControllerProvider.select((value) => value.user?.id));
    _generation++;
    _attempts.clear();
    Future<void>.microtask(load);
    return const StampTimelineState(isLoading: true);
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final generation = _generation;
    final repository = _repository;
    final initialSentIds = state.sent.map((stamp) => stamp.id).toSet();
    try {
      final (List<Stamp> received, List<Stamp> sent) = await (
        repository.getReceived(),
        repository.getSent(),
      ).wait;
      if (!ref.mounted || generation != _generation) return;
      // A refresh must not overwrite a publish that completed while loading.
      final merged = <String, Stamp>{
        for (final stamp in sent) stamp.id: stamp,
        for (final stamp in state.sent.where(
          (stamp) => !initialSentIds.contains(stamp.id),
        ))
          stamp.id: stamp,
      }.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = state.copyWith(
        received: received,
        sent: merged,
        isLoading: false,
        clearError: true,
      );
    } on Object {
      if (ref.mounted && generation == _generation) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Không thể tải ký ức. Thử lại sau.',
        );
      }
    }
  }

  Stamp? findById(String stampId) {
    for (final Stamp stamp in <Stamp>[...state.received, ...state.sent]) {
      if (stamp.id == stampId) {
        return stamp;
      }
    }
    return null;
  }

  void markSeen(String stampId) {
    state = state.copyWith(
      received: state.received
          .map((Stamp stamp) {
            return stamp.id == stampId ? stamp.copyWith(isSeen: true) : stamp;
          })
          .toList(growable: false),
    );
  }

  void react(String stampId, ReactionType reaction) {
    state = state.copyWith(
      received: state.received
          .map((Stamp stamp) {
            return stamp.id == stampId
                ? stamp.copyWith(reaction: reaction)
                : stamp;
          })
          .toList(growable: false),
    );
  }

  Future<Stamp?> publish(StampDraft draft) async {
    final generation = _generation;
    final repository = _repository;
    if (state.isPublishing) return null;
    final existing = _attempts[draft.seed];
    if (existing?.stamp != null) return existing!.stamp;
    if (ref.read(firebaseInitializedProvider) &&
        (draft.localImagePath == null || draft.localThumbnailPath == null)) {
      state = state.copyWith(
        errorMessage: 'Retake this photo before sending it.',
      );
      return null;
    }
    final FriendsState friendsState = ref.read(friendsControllerProvider);
    final eligible = friendsState.friends
        .where((friend) => friend.status == FriendStatus.accepted)
        .map((friend) => friend.id)
        .toSet();
    final List<String> recipientIds = existing?.committed == true
        ? existing!.recipients
        : switch (draft.audience) {
            AudienceMode.allFriends => eligible.toList(growable: false),
            AudienceMode.closeFriends =>
              friendsState.closeFriends
                  .map((friend) => friend.id)
                  .toList(growable: false),
            AudienceMode.selected =>
              draft.selectedRecipientIds
                  .intersection(eligible)
                  .toList(growable: false),
          };

    if (recipientIds.isEmpty && draft.replyToStampId == null) {
      state = state.copyWith(errorMessage: 'Select at least one recipient.');
      return null;
    }

    state = state.copyWith(isPublishing: true, clearError: true);
    final MediaUploadRepository uploads = ref.read(
      mediaUploadRepositoryProvider,
    );
    final attempt = existing ?? _PublishAttempt(draft, recipientIds);
    _attempts[draft.seed] = attempt;
    if (!attempt.committed) {
      attempt.draft = attempt.draft.copyWith(
        audience: draft.audience,
        selectedRecipientIds: draft.selectedRecipientIds,
      );
      attempt.recipients = recipientIds;
    }
    try {
      if (attempt.draft.cloudinaryPublicId == null &&
          draft.localImagePath != null) {
        final String pubId = await uploads.uploadStamp(draft.localImagePath!);
        attempt.draft = attempt.draft.copyWith(cloudinaryPublicId: pubId);
        if (!ref.mounted || generation != _generation) return null;
      }
      if (attempt.draft.cloudinaryThumbnailPublicId == null &&
          draft.localThumbnailPath != null) {
        final String thumbId = await uploads.uploadThumbnail(
          draft.localThumbnailPath!,
        );
        attempt.draft = attempt.draft.copyWith(
          cloudinaryThumbnailPublicId: thumbId,
        );
        if (!ref.mounted || generation != _generation) return null;
      }
      // The callable may commit even if its response is lost. Retain these
      // exact media IDs and recipients so Firebase's requestId remains stable.
      attempt.committed = true;
      final Stamp stamp = await repository.publish(
        draft: attempt.draft,
        recipientIds: attempt.recipients,
      );
      attempt.stamp = stamp;
      if (!ref.mounted || generation != _generation) return null;
      state = state.copyWith(
        sent: <Stamp>[
          stamp,
          ...state.sent.where((item) => item.id != stamp.id),
        ],
        isPublishing: false,
      );
      ref.read(stampPublicationProvider.notifier).published(stamp);
      return stamp;
    } on Object catch (error) {
      // Never destroy media after an ambiguous publish response. Partial
      // uploads are also retained for a retry of this same processed draft.
      if (!ref.mounted || generation != _generation) return null;
      state = state.copyWith(
        isPublishing: false,
        errorMessage: error is MediaUploadException
            ? error.message
            : 'Unable to send this stamp. Please try again.',
      );
      return null;
    }
  }

  bool isRetryLocked(StampDraft draft) =>
      _attempts[draft.seed]?.committed ?? false;

  Future<void> abandon(StampDraft draft) async {
    final attempt = _attempts[draft.seed];
    if (attempt == null || attempt.committed) return;
    final uploads = ref.read(mediaUploadRepositoryProvider);
    for (final id in <String?>[
      attempt.draft.cloudinaryPublicId,
      attempt.draft.cloudinaryThumbnailPublicId,
    ].whereType<String>()) {
      try {
        await uploads.delete(id);
      } on Object {
        // Cleanup is best effort; record outstanding media in E2E evidence.
      }
    }
    _attempts.remove(draft.seed);
  }

  void removeFromArchive(String stampId) {
    state = state.copyWith(
      received: state.received
          .where((Stamp stamp) => stamp.id != stampId)
          .toList(growable: false),
    );
  }

  void deleteForEveryone(String stampId) {
    state = state.copyWith(
      sent: state.sent
          .where((Stamp stamp) => stamp.id != stampId)
          .toList(growable: false),
    );
  }
}

class _PublishAttempt {
  _PublishAttempt(this.draft, this.recipients);
  StampDraft draft;
  List<String> recipients;
  bool committed = false;
  Stamp? stamp;
}
