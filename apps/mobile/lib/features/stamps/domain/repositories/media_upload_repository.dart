abstract interface class MediaUploadRepository {
  Future<String> uploadStamp(String localPath);
  Future<String> uploadThumbnail(String localPath);
  Future<void> delete(String publicId);
}
