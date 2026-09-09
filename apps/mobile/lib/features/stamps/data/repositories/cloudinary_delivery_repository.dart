import 'dart:async';
import 'dart:convert';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:inkstamp/features/stamps/data/repositories/cloudinary_upload_repository.dart';

final Provider<CloudinaryDeliveryRepository>
cloudinaryDeliveryRepositoryProvider = Provider<CloudinaryDeliveryRepository>((
  Ref ref,
) {
  return CloudinaryDeliveryRepository(
    gatewayBaseUrl: mediaGatewayBaseUrl,
    authToken: () async => FirebaseAuth.instance.currentUser?.getIdToken(),
    appCheckToken: () => FirebaseAppCheck.instance.getToken(),
  );
});

final mediaDeliveryUrlProvider = FutureProvider.family<String, String>((
  Ref ref,
  String publicId,
) {
  return ref.watch(cloudinaryDeliveryRepositoryProvider).resolve(publicId);
});

class CloudinaryDeliveryRepository {
  CloudinaryDeliveryRepository({
    required this.gatewayBaseUrl,
    required this.authToken,
    required this.appCheckToken,
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
    this.cacheDuration = const Duration(minutes: 4),
  }) : _client = client ?? http.Client();

  final String gatewayBaseUrl;
  final TokenLoader authToken;
  final TokenLoader appCheckToken;
  final Duration timeout;
  final Duration cacheDuration;
  final http.Client _client;
  final Map<String, _CachedUrl> _cache = <String, _CachedUrl>{};

  Future<String> resolve(String publicId) async {
    final _CachedUrl? cached = _cache[publicId];
    if (cached != null && cached.expiresAt.isAfter(DateTime.now())) {
      return cached.url;
    }
    final String? idToken = await authToken();
    if (idToken == null || idToken.isEmpty) {
      throw const MediaUploadException('Sign in before loading media.');
    }
    final String? appCheck = await appCheckToken();
    final http.Response response = await _client
        .post(
          Uri.parse('$gatewayBaseUrl/v1/media/delivery-urls'),
          headers: <String, String>{
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
            if (appCheck != null && appCheck.isNotEmpty)
              'X-Firebase-App-Check': appCheck,
          },
          body: jsonEncode(<String, Object>{
            'publicIds': <String>[publicId],
          }),
        )
        .timeout(timeout);
    if (response.statusCode != 200) {
      throw MediaUploadException(
        'Unable to load media (${response.statusCode}).',
      );
    }
    final Object? decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> ||
        decoded['deliveryUrls'] is! Map<String, dynamic>) {
      throw const MediaUploadException('Invalid delivery response.');
    }
    final Object? url =
        (decoded['deliveryUrls'] as Map<String, dynamic>)[publicId];
    if (url is! String || !url.startsWith('https://')) {
      throw const MediaUploadException('Invalid delivery URL.');
    }
    _cache[publicId] = _CachedUrl(url, DateTime.now().add(cacheDuration));
    return url;
  }
}

class _CachedUrl {
  const _CachedUrl(this.url, this.expiresAt);

  final String url;
  final DateTime expiresAt;
}
