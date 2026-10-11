import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkstamp/features/authentication/presentation/controllers/session_controller.dart';
import 'package:inkstamp/features/stamps/domain/entities/stamp.dart';
import 'package:inkstamp/features/stamps/domain/repositories/stamp_repository.dart';
import 'package:inkstamp/features/stamps/presentation/controllers/stamp_timeline_controller.dart';

class InboxState {
  const InboxState({
    this.items = const [],
    this.next,
    this.loading = false,
    this.error,
  });
  final List<Stamp> items;
  final StampCursor? next;
  final bool loading;
  final String? error;
}

final inboxControllerProvider = NotifierProvider<InboxController, InboxState>(
  InboxController.new,
);

class InboxController extends Notifier<InboxState> {
  int _generation = 0;
  final _reading = <String>{};
  final _confirmedRead = <String>{};

  @override
  InboxState build() {
    ref.watch(sessionControllerProvider.select((s) => s.user?.id));
    _generation++;
    _reading.clear();
    _confirmedRead.clear();
    Future<void>.microtask(refresh);
    return const InboxState();
  }

  Future<void> refresh() => _load(false);
  Future<void> loadMore() => _load(true);

  Future<void> _load(bool more) async {
    if (!ref.mounted || state.loading || (more && state.next == null)) return;
    final generation = _generation;
    final previous = state;
    state = InboxState(
      items: previous.items,
      next: previous.next,
      loading: true,
    );
    try {
      final page = await ref
          .read(stampRepositoryProvider)
          .fetchReceivedPage(after: more ? previous.next : null);
      if (!ref.mounted || generation != _generation) return;
      final readIds = {
        ..._confirmedRead,
        ...state.items.where((s) => s.isSeen).map((s) => s.id),
      };
      final items = <String, Stamp>{
        if (more)
          for (final s in state.items) s.id: s,
        for (final s in page.items)
          s.id: readIds.contains(s.id) ? s.copyWith(isSeen: true) : s,
      }.values.toList()..sort(compareStamps);
      state = InboxState(items: items, next: page.next);
    } on Object {
      if (ref.mounted && generation == _generation) {
        state = InboxState(
          items: state.items,
          next: previous.next,
          error: 'Không thể tải hộp thư.',
        );
      }
    }
  }

  /// Called only after the shared detail lookup succeeds. Never blocks viewing.
  Future<void> markRead(Stamp stamp) async {
    if (stamp.isSentByMe ||
        stamp.isSeen ||
        _confirmedRead.contains(stamp.id) ||
        _reading.contains(stamp.id) ||
        state.items.any((s) => s.id == stamp.id && s.isSeen)) {
      return;
    }
    _reading.add(stamp.id);
    final generation = _generation;
    try {
      await ref.read(stampRepositoryProvider).markDeliveryRead(stamp.id);
      if (!ref.mounted || generation != _generation) return;
      _confirmedRead.add(stamp.id);
      state = InboxState(
        items: state.items
            .map((s) => s.id == stamp.id ? s.copyWith(isSeen: true) : s)
            .toList(),
        next: state.next,
        loading: state.loading,
        error: state.error,
      );
      if (ref.exists(stampTimelineControllerProvider)) {
        ref.read(stampTimelineControllerProvider.notifier).markSeen(stamp.id);
      }
    } on Object {
      // Leave unread on failure: reopening Detail retries without hiding content.
    } finally {
      if (generation == _generation) _reading.remove(stamp.id);
    }
  }
}

final stampDetailProvider = FutureProvider.autoDispose.family<Stamp?, String>((
  ref,
  id,
) {
  ref.watch(sessionControllerProvider.select((s) => s.user?.id));
  final timer = Timer.periodic(const Duration(seconds: 30), (_) {
    if (ref.mounted) ref.invalidateSelf();
  });
  ref.onDispose(timer.cancel);
  ref.onCancel(timer.cancel);
  return ref.watch(stampRepositoryProvider).getById(id);
}, retry: (_, _) => null);
