import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:inkstamp/features/stamps/data/repositories/cloudinary_upload_repository.dart';

void main() {
  late Directory directory;
  late File image;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('inkstamp-upload-test');
    image = await File(
      '${directory.path}/stamp.jpg',
    ).writeAsBytes([0xff, 0xd8, 0xff, 0xd9]);
  });

  tearDown(() => directory.delete(recursive: true));

  test(
    'PNG stamp and thumbnail preserve format and version through upload',
    () async {
      final png = await File(
        '${directory.path}/photo_stamp_v1.png',
      ).writeAsBytes([137, 80, 78, 71]);
      for (final kind in ['stamp', 'thumbnail']) {
        var calls = 0;
        final client = MockClient((request) async {
          calls++;
          if (calls == 1) {
            expect(jsonDecode(request.body), {
              'mediaKind': kind,
              'imageFormat': 'stamp_png_v1',
            });
            return http.Response(
              jsonEncode({
                'uploadUrl': 'https://api.cloudinary.com/upload',
                'apiKey': 'key',
                'parameters': {
                  'folder': 'inkstamp/user',
                  'public_id': '$kind/id_stamp_v1',
                  'format': 'png',
                },
              }),
              200,
            );
          }
          expect(
            utf8.decode(request.bodyBytes, allowMalformed: true).toLowerCase(),
            contains('content-type: image/png'),
          );
          return http.Response(
            jsonEncode({
              'resource_type': 'image',
              'format': 'png',
              'public_id': 'inkstamp/user/$kind/id_stamp_v1',
            }),
            200,
          );
        });
        final repo = CloudinaryUploadRepository(
          gatewayBaseUrl: 'http://localhost',
          authToken: () async => 'test',
          appCheckToken: () async => null,
          client: client,
        );
        final id = kind == 'stamp'
            ? await repo.uploadStamp(png.path)
            : await repo.uploadThumbnail(png.path);
        expect(id, 'inkstamp/user/$kind/id_stamp_v1');
        expect(calls, 2);
      }
    },
  );

  test(
    'uploads using gateway tokens and validates Cloudinary response',
    () async {
      var calls = 0;
      final client = MockClient((request) async {
        calls += 1;
        if (calls == 1) {
          expect(request.headers['authorization'], 'Bearer firebase-token');
          expect(request.headers['x-firebase-app-check'], 'app-check-token');
          return http.Response(
            '{"uploadUrl":"https://api.cloudinary.com/upload","apiKey":"key",'
            '"parameters":{"folder":"inkstamp/user-1",'
            '"public_id":"stamp/id-1"}}',
            200,
          );
        }
        return http.Response(
          '{"public_id":"inkstamp/user-1/stamp/id-1","resource_type":"image"}',
          200,
        );
      });
      final repository = CloudinaryUploadRepository(
        gatewayBaseUrl: 'http://127.0.0.1:8787',
        authToken: () async => 'firebase-token',
        appCheckToken: () async => 'app-check-token',
        client: client,
      );
      expect(
        await repository.uploadStamp(image.path),
        'inkstamp/user-1/stamp/id-1',
      );
      expect(calls, 2);
    },
  );

  test('rejects a legacy gateway before uploading a new alpha stamp', () async {
    final png = await File(
      '${directory.path}/photo_stamp_v1.png',
    ).writeAsBytes([1]);
    var calls = 0;
    final repo = CloudinaryUploadRepository(
      gatewayBaseUrl: 'http://localhost',
      authToken: () async => 'test',
      appCheckToken: () async => null,
      client: MockClient((_) async {
        calls++;
        return http.Response(
          jsonEncode({
            'uploadUrl': 'https://api.cloudinary.com/upload',
            'apiKey': 'key',
            'parameters': {'folder': 'inkstamp/user', 'public_id': 'stamp/old'},
          }),
          200,
        );
      }),
    );
    await expectLater(
      repo.uploadStamp(png.path),
      throwsA(isA<MediaUploadException>()),
    );
    expect(calls, 1);
  });

  test('rejects missing, non-JPEG and oversized files', () async {
    final repository = CloudinaryUploadRepository(
      gatewayBaseUrl: 'http://127.0.0.1:8787',
      authToken: () async => 'token',
      appCheckToken: () async => null,
      client: MockClient((_) async => http.Response('{}', 500)),
      maximumBytes: 3,
    );
    await expectLater(
      repository.uploadStamp('${directory.path}/missing.jpg'),
      throwsA(isA<MediaUploadException>()),
    );
    await expectLater(
      repository.uploadStamp(
        await File(
          '${directory.path}/bad.png',
        ).writeAsString('x').then((f) => f.path),
      ),
      throwsA(isA<MediaUploadException>()),
    );
    await expectLater(
      repository.uploadStamp(image.path),
      throwsA(isA<MediaUploadException>()),
    );
  });

  test('turns network timeout into a retryable upload error', () async {
    final repository = CloudinaryUploadRepository(
      gatewayBaseUrl: 'http://127.0.0.1:8787',
      authToken: () async => 'token',
      appCheckToken: () async => null,
      client: MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return http.Response('{}', 200);
      }),
      timeout: const Duration(milliseconds: 1),
    );
    await expectLater(
      repository.uploadStamp(image.path),
      throwsA(
        isA<MediaUploadException>().having(
          (error) => error.message,
          'message',
          contains('timed out'),
        ),
      ),
    );
  });

  test('cleanup sends tokens and the exact public ID to the gateway', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/v1/media/delete');
      expect(request.headers['authorization'], 'Bearer firebase-token');
      expect(request.headers['x-firebase-app-check'], 'app-check-token');
      expect(request.body, contains('inkstamp/user-1/stamp/id-1'));
      return http.Response('{"deleted":true}', 200);
    });
    final repository = CloudinaryUploadRepository(
      gatewayBaseUrl: 'http://127.0.0.1:8787',
      authToken: () async => 'firebase-token',
      appCheckToken: () async => 'app-check-token',
      client: client,
    );
    await repository.delete('inkstamp/user-1/stamp/id-1');
  });
}
