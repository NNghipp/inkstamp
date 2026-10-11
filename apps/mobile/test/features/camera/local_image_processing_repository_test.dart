import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:inkstamp/features/camera/data/repositories/local_image_processing_repository.dart';
import 'package:inkstamp/features/camera/domain/repositories/image_processing_repository.dart';

void main() {
  late Directory directory;
  late LocalImageProcessingRepository repository;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('inkstamp_image_test_');
    repository = LocalImageProcessingRepository(
      temporaryDirectoryProvider: () async => directory,
      clock: () => DateTime.utc(2026, 9, 11, 12),
    );
  });

  tearDown(() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  test(
    'center-crops, resizes, strips metadata and deletes the raw file',
    () async {
      final image.Image source = image.Image(width: 1800, height: 1200)
        ..exif.imageIfd.make = 'Private camera model'
        ..textData = <String, String>{'location': 'private'};
      image.fill(source, color: image.ColorRgb8(30, 120, 220));
      final File raw = File(
        '${directory.path}${Platform.pathSeparator}raw.jpg',
      );
      await raw.writeAsBytes(image.encodeJpg(source));

      final ProcessedCameraImage result = await repository.process(raw.path);
      final File fullFile = File(result.imagePath);
      final File thumbnailFile = File(result.thumbnailPath);
      final image.Image full = image.decodePng(await fullFile.readAsBytes())!;
      final image.Image thumbnail = image.decodePng(
        await thumbnailFile.readAsBytes(),
      )!;

      expect((full.width, full.height), (1440, 1440));
      expect((thumbnail.width, thumbnail.height), (512, 512));
      expect(result.imagePath, endsWith('_stamp_v1.png'));
      for (final output in [full, thumbnail]) {
        final n = output.width;
        final notch = (n / 24).floor();
        expect(output.numChannels, 4);
        expect(output.getPixel(0, 0).a, 0);
        expect(output.getPixel(notch, 0).a, 0);
        expect(output.getPixel(notch, n - 1).a, 0);
        expect(output.getPixel(0, notch).a, 0);
        expect(output.getPixel(n - 1, notch).a, 0);
        expect(output.getPixel(n ~/ 2, n ~/ 2).a, 255);
        expect(output.any((p) => p.a > 0 && p.a < 255), isTrue);
      }
      expect(await fullFile.length(), lessThanOrEqualTo(5 * 1024 * 1024));
      expect(await thumbnailFile.length(), lessThanOrEqualTo(5 * 1024 * 1024));
      expect(full.exif.isEmpty, isTrue);
      expect(full.textData, isNull);
      expect(await raw.exists(), isFalse);
    },
  );

  test('bakes EXIF orientation before producing square outputs', () async {
    final image.Image source = image.Image(width: 1200, height: 1800)
      ..exif.imageIfd.orientation = 6;
    image.fill(source, color: image.ColorRgb8(220, 80, 40));
    final File raw = File('${directory.path}${Platform.pathSeparator}turn.jpg');
    await raw.writeAsBytes(image.encodeJpg(source));

    final ProcessedCameraImage result = await repository.process(raw.path);
    final image.Image output = image.decodePng(
      await File(result.imagePath).readAsBytes(),
    )!;

    expect((output.width, output.height), (1440, 1440));
    expect(output.exif.isEmpty, isTrue);
  });

  test('cleans only Inkstamp drafts older than 24 hours', () async {
    final File stale = File(
      '${directory.path}${Platform.pathSeparator}inkstamp_draft_stale_1440.jpg',
    );
    final File recent = File(
      '${directory.path}${Platform.pathSeparator}inkstamp_draft_recent_1440.jpg',
    );
    final File unrelated = File(
      '${directory.path}${Platform.pathSeparator}other.jpg',
    );
    await stale.writeAsBytes(<int>[1]);
    await recent.writeAsBytes(<int>[1]);
    await unrelated.writeAsBytes(<int>[1]);
    await stale.setLastModified(DateTime.utc(2026, 9, 9));
    await recent.setLastModified(DateTime.utc(2026, 9, 11, 11));
    await unrelated.setLastModified(DateTime.utc(2026, 9, 9));

    expect(await repository.cleanupExpiredDrafts(), 1);
    expect(await stale.exists(), isFalse);
    expect(await recent.exists(), isTrue);
    expect(await unrelated.exists(), isTrue);
  });

  test('rejects an invalid capture and still deletes the raw file', () async {
    final File raw = File('${directory.path}${Platform.pathSeparator}bad.jpg');
    await raw.writeAsString('not a JPEG');

    await expectLater(
      repository.process(raw.path),
      throwsA(isA<ImageProcessingException>()),
    );
    expect(await raw.exists(), isFalse);
  });
}
