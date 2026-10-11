import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:inkstamp/features/camera/data/repositories/camera_plugin_repository.dart';
import 'package:inkstamp/features/camera/data/repositories/local_image_processing_repository.dart';
import 'package:inkstamp/features/camera/domain/repositories/camera_repository.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'real Android camera: back/front, normalization, metadata and cleanup',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('InkStamp camera hardware verification')),
        ),
      );
      final camera = CameraPluginRepository();
      final processor = LocalImageProcessingRepository();
      try {
        await camera.initialize();
        expect(camera.previewHandle, isNotNull);
        final raw = await camera.captureRawImage();
        final processed = await processor.process(raw);
        final full = img.decodePng(
          await File(processed.imagePath).readAsBytes(),
        )!;
        final thumb = img.decodePng(
          await File(processed.thumbnailPath).readAsBytes(),
        )!;
        expect((full.width, full.height), (1440, 1440));
        expect((thumb.width, thumb.height), (512, 512));
        expect(full.exif.isEmpty, isTrue);
        expect(thumb.exif.isEmpty, isTrue);
        expect(await File(raw).exists(), isFalse);
        expect(
          await File(processed.imagePath).length(),
          lessThanOrEqualTo(5 * 1024 * 1024),
        );
        await processor.deleteFiles([
          processed.imagePath,
          processed.thumbnailPath,
        ]);
        expect(await File(processed.imagePath).exists(), isFalse);
        expect(await File(processed.thumbnailPath).exists(), isFalse);
        await camera.switchLens();
        expect(camera.lens, CameraLens.front);
        final frontRaw = await camera.captureRawImage();
        final front = await processor.process(frontRaw);
        final frontImage = img.decodePng(
          await File(front.imagePath).readAsBytes(),
        )!;
        expect((frontImage.width, frontImage.height), (1440, 1440));
        await processor.deleteFiles([front.imagePath, front.thumbnailPath]);
        // A lack of flash hardware is explicitly supported by the camera layer.
        try {
          await camera.setFlashEnabled(true);
          await camera.setFlashEnabled(false);
        } on CameraRepositoryException {
          debugPrint(
            'FLASH_UNSUPPORTED: emulator has no supported flash capability',
          );
        }
      } finally {
        await camera.dispose();
      }
    },
  );
}
