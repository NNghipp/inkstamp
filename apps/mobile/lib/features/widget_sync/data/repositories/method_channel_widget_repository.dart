import 'package:flutter/services.dart';
import 'package:inkstamp/features/widget_sync/domain/repositories/widget_repository.dart';

class MethodChannelWidgetRepository implements WidgetRepository {
  const MethodChannelWidgetRepository();

  static const MethodChannel _channel = MethodChannel(
    'com.inkstamp.app/widget',
  );

  @override
  Future<void> clear() async {
    await _channel.invokeMethod<void>('clearWidget');
  }

  @override
  Future<void> updateLatestStamp({
    required String stampId,
    required String senderName,
    required String thumbnailPath,
  }) async {
    await _channel.invokeMethod<void>('updateLatestStamp', <String, String>{
      'stampId': stampId,
      'senderName': senderName,
      'thumbnailPath': thumbnailPath,
    });
  }
}
