import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkstamp/app/theme/app_theme.dart';
import 'package:inkstamp/core/widgets/stamp_date_overlay.dart';
import 'package:inkstamp/features/stamps/domain/entities/stamp.dart';
import 'package:inkstamp/features/stamps/domain/entities/stamp_draft.dart';

void main() {
  test(
    'optional metadata survives upload and reaction copies, legacy falls back',
    () {
      final captured = DateTime(2026, 10, 15, 9, 5);
      final draft = StampDraft.initial().copyWith(
        capturedAt: captured,
        title: 'Cổng đỏ Kyoto',
        locationLabel: 'Kyoto',
      );
      final uploaded = draft.copyWith(
        cloudinaryPublicId: 'full_stamp_v1',
        cloudinaryThumbnailPublicId: 'thumb_stamp_v1',
      );
      expect(uploaded.captureTime, captured);
      expect(uploaded.title, draft.title);
      expect(uploaded.locationLabel, 'Kyoto');
      final published = DateTime(2026, 10, 15, 16, 45);
      final stamp = Stamp(
        id: 'one',
        senderId: 'owner',
        senderName: 'Owner',
        createdAt: published,
        seed: 1,
        frameStyle: StampFrameStyle.classic,
        paperTone: PaperTone.cream,
        isSentByMe: true,
        capturedAt: captured,
        title: uploaded.title,
        locationLabel: uploaded.locationLabel,
      );
      final reacted = stamp.copyWith(reaction: ReactionType.heart);
      expect(reacted.captureTime, captured);
      expect(reacted.publishedAt, published);
      expect(reacted.shortTitle, 'Cổng đỏ Kyoto');
      expect(reacted.locationLabel, 'Kyoto');
      final legacy = Stamp(
        id: 'old',
        senderId: 'owner',
        senderName: 'Owner',
        createdAt: published,
        seed: 1,
        frameStyle: StampFrameStyle.classic,
        paperTone: PaperTone.cream,
        isSentByMe: true,
        caption: 'Ảnh cũ',
      );
      expect(legacy.captureTime, published);
      expect(legacy.shortTitle, 'Ảnh cũ');
    },
  );

  testWidgets(
    'date is inside bottom-right safe area, unchanged child, one format',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Center(
            child: SizedBox.square(
              dimension: 300,
              child: StampDateOverlay(
                date: DateTime(2026, 10, 15),
                child: const ColoredBox(
                  key: ValueKey('photo'),
                  color: Colors.transparent,
                ),
              ),
            ),
          ),
        ),
      );
      final photo = tester.getRect(find.byKey(const ValueKey('photo')));
      final date = tester.getRect(find.text('15.10.2026'));
      expect(photo.contains(date.topLeft), isTrue);
      expect(photo.contains(date.bottomRight), isTrue);
      expect(date.left, greaterThan(photo.center.dx));
      expect(date.top, greaterThan(photo.center.dy));
      expect(photo.right - date.right, greaterThan(15));
      expect(photo.bottom - date.bottom, greaterThan(15));
    },
  );

  testWidgets(
    'tiny Calendar thumbnails stay clear without illegible date text',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox.square(
              dimension: 28,
              child: StampDateOverlay(
                date: DateTime(2026, 10, 15),
                child: const ColoredBox(color: Colors.transparent),
              ),
            ),
          ),
        ),
      );
      expect(find.text('15.10.2026'), findsNothing);
    },
  );
}
