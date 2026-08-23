abstract interface class WidgetRepository {
  Future<void> updateLatestStamp({
    required String stampId,
    required String senderName,
    required String thumbnailPath,
  });

  Future<void> clear();
}
