import 'package:inkstamp/features/stamps/domain/entities/stamp.dart';
import 'package:inkstamp/features/stamps/domain/entities/stamp_draft.dart';

abstract interface class StampRepository {
  Future<StampPage> fetchReceivedPage({StampCursor? after, int limit = 25});
  Future<List<Stamp>> fetchMonth(DateTime start, DateTime end);
  Future<Stamp?> getById(String id);
  Future<void> markDeliveryRead(String id);
  Future<List<Stamp>> getReceived();

  Future<List<Stamp>> getSent();

  Future<Stamp> publish({
    required StampDraft draft,
    required List<String> recipientIds,
  });
}

class StampCursor {
  const StampCursor(this.createdAt, this.id);
  final DateTime createdAt;
  final String id;
}

class StampPage {
  const StampPage(this.items, this.next);
  final List<Stamp> items;
  final StampCursor? next;
}

/// Same stable ordering for Firestore pages and local/demo repositories.
int compareStamps(Stamp a, Stamp b) {
  final time = b.createdAt.compareTo(a.createdAt);
  return time == 0 ? b.id.compareTo(a.id) : time;
}

StampPage pageStamps(List<Stamp> source, StampCursor? after, int limit) {
  validateStampPageRequest(after, limit);
  final ordered = List<Stamp>.of(source)..sort(compareStamps);
  final eligible = ordered
      .where(
        (stamp) =>
            after == null ||
            stamp.createdAt.isBefore(after.createdAt) ||
            (stamp.createdAt.isAtSameMomentAs(after.createdAt) &&
                stamp.id.compareTo(after.id) < 0),
      )
      .toList();
  final items = eligible.take(limit).toList();
  return StampPage(
    items,
    eligible.length > limit
        ? StampCursor(items.last.createdAt, items.last.id)
        : null,
  );
}

void validateStampPageRequest(StampCursor? after, int limit) {
  if (limit < 1 ||
      limit > 100 ||
      (after != null &&
          (after.id.isEmpty ||
              after.id.contains('/') ||
              after.id == '.' ||
              after.id == '..'))) {
    throw ArgumentError('Invalid delivery page size or cursor.');
  }
}
