import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as image;
import 'package:inkstamp/core/config/app_environment.dart';
import 'package:inkstamp/features/camera/data/repositories/local_image_processing_repository.dart';
import 'package:inkstamp/features/camera/domain/repositories/camera_repository.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

// Both conditions are compile-time constants: release/profile and non-DEV
// builds cannot enable the action, even by overriding a Riverpod provider.
const devAssetCaptureEnabled =
    kDebugMode &&
    String.fromEnvironment('APP_ENV', defaultValue: 'prod') == 'dev';

final devAssetCaptureSourceProvider = Provider<DevAssetCaptureSource>(
  (ref) => DevAssetCaptureSource(),
);

/// An alternate raw capture source, never a replacement hardware repository.
class DevAssetCaptureSource {
  DevAssetCaptureSource({
    AssetBundle? bundle,
    TemporaryDirectoryProvider? temporaryDirectoryProvider,
  }) : _bundle = bundle ?? rootBundle,
       _directory = temporaryDirectoryProvider ?? getTemporaryDirectory;

  static const prefix = 'assets/image_test/';
  final AssetBundle _bundle;
  final TemporaryDirectoryProvider _directory;

  static List<String> supportedAssets(Iterable<String> keys) =>
      keys
          .where(
            (key) =>
                key.startsWith(prefix) &&
                !key.substring(prefix.length).contains('/') &&
                image.findDecoderForNamedImage(key) != null,
          )
          .toList()
        ..sort();

  Future<List<String>> listImages() async {
    if (!devAssetCaptureEnabled || !AppEnvironment.current.isLocalDev) {
      return const [];
    }
    final manifest = await AssetManifest.loadFromAssetBundle(_bundle);
    return supportedAssets(manifest.listAssets());
  }

  Future<String> captureRawImage(String asset) async {
    if (!devAssetCaptureEnabled || !(await listImages()).contains(asset)) {
      throw const CameraRepositoryException(
        'invalid-dev-asset',
        'This DEV sample image is unavailable.',
      );
    }
    final data = await _bundle.load(asset);
    final directory = await _directory();
    // Matches the existing stale-draft cleanup prefix; never writes to assets.
    final file = File(
      '${directory.path}${Platform.pathSeparator}'
      '${LocalImageProcessingRepository.filePrefix}${const Uuid().v4()}_raw',
    );
    try {
      await file.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
      return file.path;
    } on Object {
      if (await file.exists()) await file.delete();
      rethrow;
    }
  }

  /// Optional presentation metadata. Discovery never depends on this file.
  Future<({String? title, String? locationLabel, DateTime capturedAt})>
  metadata(String asset) async {
    final now = DateTime.now();
    if (!devAssetCaptureEnabled) {
      return (title: null, locationLabel: null, capturedAt: now);
    }
    try {
      final all =
          jsonDecode(await _bundle.loadString('${prefix}demo_metadata.json'))
              as Map<String, dynamic>;
      final entry =
          all[asset.substring(prefix.length)] as Map<String, dynamic>?;
      String? label(String key) {
        final value = entry?[key];
        return value is String && value.trim().isNotEmpty && value.length <= 80
            ? value.trim()
            : null;
      }

      final time = label('time')?.split(':');
      final hour = time?.length == 2 ? int.tryParse(time![0]) : null;
      final minute = time?.length == 2 ? int.tryParse(time![1]) : null;
      final capturedAt =
          hour != null &&
              minute != null &&
              hour >= 0 &&
              hour < 24 &&
              minute >= 0 &&
              minute < 60
          ? DateTime(now.year, now.month, now.day, hour, minute)
          : now;
      return (
        title: label('title'),
        locationLabel: label('locationLabel'),
        capturedAt: capturedAt,
      );
    } on Object {
      return (title: null, locationLabel: null, capturedAt: now);
    }
  }
}
