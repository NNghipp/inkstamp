import 'dart:async';
import 'dart:convert';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:inkstamp/features/stamps/data/repositories/cloudinary_delivery_repository.dart';
import 'package:inkstamp/features/stamps/data/repositories/cloudinary_upload_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'viewed full and thumb are reauthorized after revoke, not cached for four minutes',
    () async {
      var allowed = true;
      var calls = 0;
      final repository = CloudinaryDeliveryRepository(
        gatewayBaseUrl: 'https://media.example.com',
        authToken: () async => 'unit-token',
        appCheckToken: () async => null,
        client: MockClient((request) async {
          calls++;
          if (!allowed) return http.Response('{}', 403);
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final ids = body['publicIds'] as List<dynamic>;
          final id = ids.first as String;
          return http.Response(
            jsonEncode({
              'deliveryUrls': {id: 'https://media.example.com/lease.jpg'},
            }),
            200,
          );
        }),
      );
      addTearDown(repository.dispose);
      for (final kind in ['stamp', 'thumbnail']) {
        final id = 'inkstamp/owner/$kind/media';
        await repository.resolve(id);
        allowed = false;
        await expectLater(
          repository.resolve(id),
          throwsA(isA<MediaUploadException>()),
        );
        allowed = true;
      }
      expect(calls, 4);
    },
  );
  test(
    'explicit eviction removes the protected network image cache key',
    () async {
      const url = 'https://media.example.com/protected.jpg';
      final repository = CloudinaryDeliveryRepository(
        gatewayBaseUrl: 'https://media.example.com',
        authToken: () async => 'unit-token',
        appCheckToken: () async => null,
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'deliveryUrls': {'id': url},
            }),
            200,
          ),
        ),
      );
      addTearDown(repository.dispose);
      await repository.resolve('id');
      final cache = PaintingBinding.instance.imageCache;
      final key = await const NetworkImage(
        url,
      ).obtainKey(ImageConfiguration.empty);
      cache.putIfAbsent(
        key,
        () => OneFrameImageStreamCompleter(Completer<ImageInfo>().future),
      );
      await repository.evict('id');
      expect(cache.containsKey(key), isFalse);
    },
  );
}
