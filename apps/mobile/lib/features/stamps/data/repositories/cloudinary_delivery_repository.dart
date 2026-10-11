import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:inkstamp/core/config/functions_backend.dart';
import 'package:inkstamp/features/authentication/presentation/controllers/session_controller.dart';
import 'package:inkstamp/features/stamps/data/repositories/cloudinary_upload_repository.dart';

final Provider<CloudinaryDeliveryRepository>
cloudinaryDeliveryRepositoryProvider = Provider<CloudinaryDeliveryRepository>((
  Ref ref,
) {
  ref.watch(sessionControllerProvider.select((s) => s.user?.id));
  final repository = CloudinaryDeliveryRepository(
    gatewayBaseUrl: mediaGatewayBaseUrl,
    authToken: () async => FirebaseAuth.instance.currentUser?.getIdToken(),
    appCheckToken: FunctionsBackend.mediaAppCheckToken,
  );
  ref.onDispose(repository.dispose);
  return repository;
});

final mediaDeliveryUrlProvider = FutureProvider.autoDispose
    .family<String, String>((Ref ref, String publicId) {
      final repository = ref.watch(cloudinaryDeliveryRepositoryProvider);
      // Reauthorize mounted images: a previously valid URL is not proof of
      // continuing access after revoke/block. No automatic retry on denial.
      final timer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (ref.mounted) ref.invalidateSelf();
      });
      ref.onCancel(timer.cancel);
      ref.onDispose(() {
        timer.cancel();
        unawaited(repository.evict(publicId));
      });
      return repository.resolve(publicId);
    }, retry: (_, _) => null);

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

  void dispose() {
    _client.close();
    for (final id in _cache.keys.toList()) {
      unawaited(evict(id));
    }
  }

  Future<void> evict(String publicId) async {
    final cached = _cache.remove(publicId);
    if (cached != null) await NetworkImage(cached.url).evict();
  }

  Future<String> resolve(String publicId) async {
    // Always check current authorization; do not reuse the four-minute lease.
    final String? idToken = await authToken().timeout(timeout);
    if (idToken == null || idToken.isEmpty) {
      throw const MediaUploadException('Sign in before loading media.');
    }
    final String? appCheck = await appCheckToken().timeout(timeout);
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
      await evict(publicId);
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
