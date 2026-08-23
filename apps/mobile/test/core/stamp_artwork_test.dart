import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkstamp/core/widgets/stamp_artwork.dart';
import 'package:inkstamp/features/stamps/domain/entities/stamp.dart';

void main() {
  for (final StampFrameStyle style in StampFrameStyle.values) {
    testWidgets('renders the ${style.name} stamp frame', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox.square(
                dimension: 240,
                child: StampArtwork(
                  seed: 42,
                  frameStyle: style,
                  paperTone: PaperTone.sky,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(StampArtwork), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
