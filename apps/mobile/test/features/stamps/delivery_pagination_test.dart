import 'package:flutter_test/flutter_test.dart';
import 'package:inkstamp/features/stamps/domain/entities/stamp.dart';
import 'package:inkstamp/features/stamps/domain/repositories/stamp_repository.dart';

void main() {
  final time = DateTime.utc(2026, 10, 7);
  Stamp row(int i) => Stamp(
    id: i.toString().padLeft(4, '0'),
    senderId: 'a',
    senderName: 'A',
    createdAt: time,
    seed: i,
    frameStyle: StampFrameStyle.classic,
    paperTone: PaperTone.cream,
    isSentByMe: false,
  );
  for (final count in [0, 1, 25, 26, 100, 101, 126]) {
    test('25-row cursor pages $count equal timestamps without gaps', () {
      final source = List.generate(count, row);
      final ids = <String>[];
      StampCursor? cursor;
      do {
        final page = pageStamps(source, cursor, 25);
        ids.addAll(page.items.map((s) => s.id));
        cursor = page.next;
      } while (cursor != null);
      expect(ids, List.generate(count, (i) => row(count - i - 1).id));
      expect(ids.toSet().length, count);
    });
  }
  test('value cursor survives deletion/revoke between pages', () {
    final source = List.generate(51, row);
    final first = pageStamps(source, null, 25);
    source.removeWhere((s) => s.id == first.next!.id || s.id == '0025');
    expect(
      pageStamps(source, first.next, 25).items.map((s) => s.id),
      List.generate(25, (i) => row(24 - i).id),
    );
  });
  test('invalid cursors and limits fail clearly', () {
    for (final id in ['', '.', '..', 'bad/id']) {
      expect(
        () => pageStamps([], StampCursor(time, id), 25),
        throwsArgumentError,
      );
    }
    for (final limit in [-1, 0, 101]) {
      expect(() => pageStamps([], null, limit), throwsArgumentError);
    }
  });
}
