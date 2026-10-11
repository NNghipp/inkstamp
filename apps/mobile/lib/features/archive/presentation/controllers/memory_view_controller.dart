import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkstamp/features/authentication/presentation/controllers/session_controller.dart';
import 'package:inkstamp/features/stamps/domain/entities/stamp.dart';
import 'package:inkstamp/features/stamps/presentation/controllers/stamp_publication_controller.dart';
import 'package:inkstamp/features/stamps/presentation/controllers/stamp_timeline_controller.dart';

final memoriesProvider = Provider<List<Stamp>>((ref) {
  final state = ref.watch(stampTimelineControllerProvider);
  final byId = <String, Stamp>{
    for (final stamp in [...state.received, ...state.sent]) stamp.id: stamp,
  };
  return byId.values.toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

class CalendarSelection {
  const CalendarSelection(this.month, this.date, {this.direction = 1});
  final DateTime month;
  final DateTime? date;
  final int direction;
}

final calendarSelectionProvider =
    NotifierProvider<CalendarSelectionController, CalendarSelection>(
      CalendarSelectionController.new,
    );

class CalendarSelectionController extends Notifier<CalendarSelection> {
  @override
  CalendarSelection build() {
    final now = DateTime.now();
    return CalendarSelection(
      DateTime(now.year, now.month),
      DateTime(now.year, now.month, now.day),
    );
  }

  void select(DateTime date) {
    state = CalendarSelection(
      DateTime(date.year, date.month),
      date,
      direction: state.direction,
    );
  }

  void moveMonth(int delta) {
    final month = DateTime(state.month.year, state.month.month + delta);
    final today = DateTime.now();
    state = CalendarSelection(
      month,
      month.year == today.year && month.month == today.month
          ? DateTime(today.year, today.month, today.day)
          : null,
      direction: delta.sign,
    );
  }
}

/// The accessible archive: own active stamps + available received deliveries.
/// Local midnight boundaries convert to UTC instants in the repository query.
final calendarMonthProvider = FutureProvider.family<List<Stamp>, DateTime>((
  ref,
  month,
) {
  ref.watch(sessionControllerProvider.select((s) => s.user?.id));
  ref.listen(stampPublicationProvider, (_, stamp) {
    if (stamp != null &&
        stamp.createdAt.toLocal().year == month.year &&
        stamp.createdAt.toLocal().month == month.month) {
      ref.invalidateSelf();
    }
  });
  return ref
      .watch(stampRepositoryProvider)
      .fetchMonth(
        DateTime(month.year, month.month),
        DateTime(month.year, month.month + 1),
      );
}, retry: (_, _) => null);

final dayMemoriesProvider = Provider<List<Stamp>>((ref) {
  final day = ref.watch(calendarSelectionProvider).date;
  if (day == null) return [];
  final month = ref.watch(
    calendarMonthProvider(ref.watch(calendarSelectionProvider).month),
  );
  if (month.isReloading) return [];
  return month.value
          ?.where((stamp) => sameDay(stamp.createdAt, day))
          .toList() ??
      [];
});

bool sameDay(DateTime a, DateTime b) {
  final localA = a.toLocal();
  final localB = b.toLocal();
  return localA.year == localB.year &&
      localA.month == localB.month &&
      localA.day == localB.day;
}

enum CollectionFilter { all, month, year2026, year2025 }

final collectionFilterProvider =
    NotifierProvider<CollectionFilterController, CollectionFilter>(
      CollectionFilterController.new,
    );

class CollectionFilterController extends Notifier<CollectionFilter> {
  @override
  CollectionFilter build() => CollectionFilter.all;
  void select(CollectionFilter filter) => state = filter;
}

final collectionMemoriesProvider = Provider<List<Stamp>>((ref) {
  final filter = ref.watch(collectionFilterProvider);
  final now = DateTime.now();
  final sent = ref.watch(stampTimelineControllerProvider).sent;
  return sent
      .where(
        (stamp) => switch (filter) {
          CollectionFilter.all => true,
          CollectionFilter.month =>
            stamp.createdAt.year == now.year &&
                stamp.createdAt.month == now.month,
          CollectionFilter.year2026 => stamp.createdAt.year == 2026,
          CollectionFilter.year2025 => stamp.createdAt.year == 2025,
        },
      )
      .toList();
});
