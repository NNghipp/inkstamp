class ProcessedCameraImage {
  const ProcessedCameraImage({
    required this.imagePath,
    required this.thumbnailPath,
  });

  final String imagePath;
  final String thumbnailPath;
}

abstract interface class ImageProcessingRepository {
  Future<ProcessedCameraImage> process(String rawImagePath);

  Future<void> deleteFiles(Iterable<String?> paths);

  Future<int> cleanupExpiredDrafts({
    Duration maximumAge = const Duration(hours: 24),
  });
}

class ImageProcessingException implements Exception {
  const ImageProcessingException(this.message);

  final String message;
}
