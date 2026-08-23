import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkstamp/features/friends/presentation/controllers/friends_controller.dart';
import 'package:inkstamp/features/stamps/data/repositories/in_memory_stamp_repository.dart';
import 'package:inkstamp/features/stamps/domain/entities/stamp.dart';
import 'package:inkstamp/features/stamps/domain/entities/stamp_draft.dart';
import 'package:inkstamp/features/stamps/domain/repositories/stamp_repository.dart';

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
    Provider<StampRepository>((Ref ref) => InMemoryStampRepository());

final NotifierProvider<StampTimelineController, StampTimelineState>
stampTimelineControllerProvider =
    NotifierProvider<StampTimelineController, StampTimelineState>(
      StampTimelineController.new,
    );

class StampTimelineController extends Notifier<StampTimelineState> {
  StampRepository get _repository => ref.read(stampRepositoryProvider);

  @override
  StampTimelineState build() {
    Future<void>.microtask(load);
    return const StampTimelineState(isLoading: true);
  }

  Future<void> load() async {
    final (List<Stamp> received, List<Stamp> sent) = await (
      _repository.getReceived(),
      _repository.getSent(),
    ).wait;
    state = state.copyWith(received: received, sent: sent, isLoading: false);
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
    final FriendsState friendsState = ref.read(friendsControllerProvider);
    final List<String> recipientIds = switch (draft.audience) {
      AudienceMode.allFriends =>
        friendsState.friends.map((friend) => friend.id).toList(growable: false),
      AudienceMode.closeFriends =>
        friendsState.closeFriends
            .map((friend) => friend.id)
            .toList(growable: false),
      AudienceMode.selected => draft.selectedRecipientIds.toList(
        growable: false,
      ),
    };

    if (recipientIds.isEmpty && draft.replyToStampId == null) {
      state = state.copyWith(errorMessage: 'Select at least one recipient.');
      return null;
    }

    state = state.copyWith(isPublishing: true, clearError: true);
    try {
      final Stamp stamp = await _repository.publish(
        draft: draft,
        recipientIds: recipientIds,
      );
      state = state.copyWith(
        sent: <Stamp>[stamp, ...state.sent],
        isPublishing: false,
      );
      return stamp;
    } on Object {
      state = state.copyWith(
        isPublishing: false,
        errorMessage: 'Unable to send this stamp. Please try again.',
      );
      return null;
    }
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
