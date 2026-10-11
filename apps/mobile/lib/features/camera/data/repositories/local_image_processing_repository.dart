import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as image;
import 'package:inkstamp/features/camera/data/stamp_alpha_mask.dart';
import 'package:inkstamp/features/camera/domain/repositories/image_processing_repository.dart';
import 'package:path_provider/path_provider.dart';

typedef TemporaryDirectoryProvider = Future<Directory> Function();

class LocalImageProcessingRepository implements ImageProcessingRepository {
  LocalImageProcessingRepository({
    TemporaryDirectoryProvider? temporaryDirectoryProvider,
    DateTime Function()? clock,
  }) : _temporaryDirectoryProvider =
           temporaryDirectoryProvider ?? getTemporaryDirectory,
       _clock = clock ?? DateTime.now;

  static const int imageSize = 1440;
  static const int thumbnailSize = 512;
  static const int maximumImageBytes = 5 * 1024 * 1024;
  static const String filePrefix = 'inkstamp_draft_';

  final TemporaryDirectoryProvider _temporaryDirectoryProvider;
  final DateTime Function() _clock;
  int _sequence = 0;

  @override
  Future<ProcessedCameraImage> process(String rawImagePath) async {
    final File rawFile = File(rawImagePath);
    File? output;
    File? thumbnail;
    try {
      final Uint8List rawBytes = await rawFile.readAsBytes();
      final _EncodedOutputs encoded = await Isolate.run(
        () => _processBytes(rawBytes),
      );
      final Directory directory = await _temporaryDirectoryProvider();
      final String id = '${_clock().millisecondsSinceEpoch}_${_sequence++}';
      output = File(
        '${directory.path}${Platform.pathSeparator}$filePrefix${id}_1440_stamp_v1.png',
      );
      thumbnail = File(
        '${directory.path}${Platform.pathSeparator}$filePrefix${id}_512_stamp_v1.png',
      );
      await output.writeAsBytes(encoded.imageBytes, flush: true);
      await thumbnail.writeAsBytes(encoded.thumbnailBytes, flush: true);
      return ProcessedCameraImage(
        imagePath: output.path,
        thumbnailPath: thumbnail.path,
      );
    } on ImageProcessingException {
      rethrow;
    } on FileSystemException {
      await deleteFiles(<String?>[output?.path, thumbnail?.path]);
      throw const ImageProcessingException(
        'Unable to save the photo. Check available storage.',
      );
    } on Object {
      await deleteFiles(<String?>[output?.path, thumbnail?.path]);
      throw const ImageProcessingException(
        'Unable to process this photo. Please retake it.',
      );
    } finally {
      await deleteFiles(<String?>[rawImagePath]);
    }
  }

  @override
  Future<void> deleteFiles(Iterable<String?> paths) async {
    for (final String? path in paths) {
      if (path == null || path.isEmpty) continue;
      final File file = File(path);
      try {
        if (await file.exists()) await file.delete();
      } on FileSystemException {
        // Cleanup is best-effort; stale drafts are retried on the next launch.
      }
    }
  }

  @override
  Future<int> cleanupExpiredDrafts({
    Duration maximumAge = const Duration(hours: 24),
  }) async {
    final Directory directory = await _temporaryDirectoryProvider();
    if (!await directory.exists()) return 0;
    final DateTime cutoff = _clock().subtract(maximumAge);
    int deleted = 0;
    await for (final FileSystemEntity entity in directory.list()) {
      if (entity is! File ||
          !entity.uri.pathSegments.last.startsWith(filePrefix)) {
        continue;
      }
      try {
        if ((await entity.lastModified()).isBefore(cutoff)) {
          await entity.delete();
          deleted += 1;
        }
      } on FileSystemException {
        // Continue cleaning other draft files.
      }
    }
    return deleted;
  }
}

class _EncodedOutputs {
  const _EncodedOutputs({
    required this.imageBytes,
    required this.thumbnailBytes,
  });

  final Uint8List imageBytes;
  final Uint8List thumbnailBytes;
}

_EncodedOutputs _processBytes(Uint8List rawBytes) {
  final image.Image? decoded = image.decodeImage(rawBytes);
  if (decoded == null) {
    throw const ImageProcessingException('The captured photo is invalid.');
  }
  // A camera capture is a still image, even when a DEV asset is animated.
  final image.Image oriented = image.bakeOrientation(
    decoded.clone(noAnimation: true),
  );
  final int squareSize = oriented.width < oriented.height
      ? oriented.width
      : oriented.height;
  final image.Image square = image.copyCrop(
    oriented,
    x: (oriented.width - squareSize) ~/ 2,
    y: (oriented.height - squareSize) ~/ 2,
    width: squareSize,
    height: squareSize,
  );
  final image.Image fullSize = image.copyResize(
    square,
    width: LocalImageProcessingRepository.imageSize,
    height: LocalImageProcessingRepository.imageSize,
    interpolation: image.Interpolation.cubic,
  );
  final image.Image thumbnail = image.copyResize(
    square,
    width: LocalImageProcessingRepository.thumbnailSize,
    height: LocalImageProcessingRepository.thumbnailSize,
    interpolation: image.Interpolation.cubic,
  );
  _stripMetadata(fullSize);
  _stripMetadata(thumbnail);
  return _EncodedOutputs(
    imageBytes: _encodeWithinLimit(StampAlphaMask.apply(fullSize)),
    thumbnailBytes: _encodeWithinLimit(StampAlphaMask.apply(thumbnail)),
  );
}

Uint8List _encodeWithinLimit(image.Image value) {
  // Lossless first. Rare noisy photos use bounded RGB precision reduction,
  // retaining exact alpha, dimensions and mask rather than flattening to JPEG.
  for (final int bits in <int>[8, 7, 6, 5, 4]) {
    final candidate = value.clone();
    if (bits < 8) {
      final shift = 8 - bits;
      final maximum = (1 << bits) - 1;
      for (final pixel in candidate) {
        pixel.r = ((pixel.r.toInt() >> shift) * 255 / maximum).round();
        pixel.g = ((pixel.g.toInt() >> shift) * 255 / maximum).round();
        pixel.b = ((pixel.b.toInt() >> shift) * 255 / maximum).round();
      }
    }
    final Uint8List encoded = image.encodePng(
      candidate,
      level: 6,
      singleFrame: true,
    );
    if (encoded.length <= LocalImageProcessingRepository.maximumImageBytes) {
      return encoded;
    }
  }
  throw const ImageProcessingException(
    'The processed photo is larger than 5 MB.',
  );
}

void _stripMetadata(image.Image value) {
  value.exif.clear();
  value.iccProfile = null;
  value.textData = null;
}
