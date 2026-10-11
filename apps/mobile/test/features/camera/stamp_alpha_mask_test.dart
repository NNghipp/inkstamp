import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:inkstamp/core/images/stamp_image_format.dart';
import 'package:inkstamp/core/widgets/stamp_artwork.dart';
import 'package:inkstamp/features/camera/data/repositories/local_image_processing_repository.dart';
import 'package:inkstamp/features/camera/data/stamp_alpha_mask.dart';

void main() {
  test('normalizes higher bit depth before applying coverage alpha', () {
    final source = image.Image(
      width: 512,
      height: 512,
      format: image.Format.uint16,
      numChannels: 3,
    );
    for (final pixel in source) {
      pixel.setRgb(65535, 0, 0);
    }
    final masked = StampAlphaMask.apply(source);
    expect(masked.format, image.Format.uint8);
    expect(masked.getPixel(256, 256).r, 255);
    expect(masked.getPixel(256, 256).a, 255);
    expect(masked.getPixel(0, 0).a, 0);
  });

  test(
    'animated sample produces one masked still, not unmasked later frames',
    () async {
      final dir = await Directory.systemTemp.createTemp(
        'inkstamp-mask-animation-',
      );
      addTearDown(() => dir.delete(recursive: true));
      final source = image.Image(width: 80, height: 120);
      image.fill(source, color: image.ColorRgb8(255, 0, 0));
      final second = image.Image(width: 80, height: 120);
      image.fill(second, color: image.ColorRgb8(0, 0, 255));
      source.addFrame(second);
      final raw = File('${dir.path}/raw.gif');
      await raw.writeAsBytes(image.encodeGif(source));
      final output = await LocalImageProcessingRepository(
        temporaryDirectoryProvider: () async => dir,
      ).process(raw.path);
      for (final path in [output.imagePath, output.thumbnailPath]) {
        final decoded = image.decodePng(await File(path).readAsBytes())!;
        expect(decoded.numFrames, 1);
        expect(
          decoded.getPixel(decoded.width ~/ 2, decoded.height ~/ 2).r,
          255,
        );
        expect(decoded.getPixel(0, 0).a, 0);
      }
    },
  );
  test(
    'same normalized perforations on all four sides at both resolutions',
    () {
      for (final n in [1440, 512]) {
        final original = image.Image(width: n, height: n);
        image.fill(original, color: image.ColorRgb8(120, 80, 40));
        final masked = StampAlphaMask.apply(original);
        for (var i = 0; i < StampAlphaMask.perforations; i++) {
          final c = ((i + .5) * n / StampAlphaMask.perforations).floor();
          for (final p in [
            masked.getPixel(c, 0),
            masked.getPixel(c, n - 1),
            masked.getPixel(0, c),
            masked.getPixel(n - 1, c),
          ]) {
            expect(p.a, 0);
            expect([p.r, p.g, p.b], [0, 0, 0]);
          }
        }
        final center = masked.getPixel(n ~/ 2, n ~/ 2);
        expect([center.r, center.g, center.b, center.a], [120, 80, 40, 255]);
        expect(masked.getPixel(n ~/ 2, 0).a, 255); // Tooth between holes.
        expect(original.numChannels, 3); // No source mutation.
      }
    },
  );

  test(
    'noisy capture stays within upload limit without losing alpha',
    () async {
      final dir = await Directory.systemTemp.createTemp('inkstamp-mask-noise-');
      addTearDown(() => dir.delete(recursive: true));
      final source = image.Image(width: 1440, height: 1440);
      final random = Random(42);
      for (final p in source) {
        p.setRgb(random.nextInt(256), random.nextInt(256), random.nextInt(256));
      }
      final raw = File('${dir.path}/raw.png');
      await raw.writeAsBytes(image.encodePng(source));
      final output = await LocalImageProcessingRepository(
        temporaryDirectoryProvider: () async => dir,
      ).process(raw.path);
      for (final path in [output.imagePath, output.thumbnailPath]) {
        final file = File(path);
        expect(await file.length(), lessThanOrEqualTo(5 * 1024 * 1024));
        final decoded = image.decodePng(await file.readAsBytes())!;
        expect(decoded.getPixel(0, 0).a, 0);
        expect(
          decoded.getPixel(decoded.width ~/ 2, decoded.height ~/ 2).a,
          255,
        );
      }
    },
  );

  test('version marker distinguishes new outputs from legacy JPEG', () {
    expect(isProcessedStampImage('inkstamp/a/stamp/id_stamp_v1'), isTrue);
    expect(isProcessedStampImage('/tmp/1440_stamp_v1.png'), isTrue);
    expect(isProcessedStampImage('inkstamp/a/stamp/id'), isFalse);
    expect(isProcessedStampImage('/tmp/old.jpg'), isFalse);
    expect(isProcessedStampImage(null), isFalse);
  });

  testWidgets(
    'new alpha artwork has no paper frame; old square keeps its frame',
    (tester) async {
      final dir = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('inkstamp-mask-widget-'),
      ))!;
      addTearDown(() => dir.delete(recursive: true));
      final source = image.Image(width: 64, height: 64);
      image.fill(source, color: image.ColorRgb8(30, 100, 180));
      final png = File('${dir.path}/photo_stamp_v1.png');
      final jpg = File('${dir.path}/legacy.jpg');
      await tester.runAsync(() async {
        await png.writeAsBytes(image.encodePng(StampAlphaMask.apply(source)));
        await jpg.writeAsBytes(image.encodeJpg(source));
      });
      Future<void> show(String path) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: SizedBox.square(
                  dimension: 240,
                  child: StampArtwork(seed: 1, localImagePath: path),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await show(png.path);
      expect(find.byType(ClipPath), findsNothing);
      expect(tester.widget<Image>(find.byType(Image)).fit, BoxFit.contain);
      await show(jpg.path);
      expect(find.byType(ClipPath), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
