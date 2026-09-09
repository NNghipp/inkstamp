import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:inkstamp/features/stamps/data/repositories/cloudinary_delivery_repository.dart';

void main() {
  test('resolves an authorized delivery URL and caches it', () async {
    var calls = 0;
    final repository = CloudinaryDeliveryRepository(
      gatewayBaseUrl: 'http://127.0.0.1:8787',
      authToken: () async => 'firebase-token',
      appCheckToken: () async => 'app-check-token',
      client: MockClient((request) async {
        calls += 1;
        expect(request.headers['authorization'], 'Bearer firebase-token');
        expect(request.headers['x-firebase-app-check'], 'app-check-token');
        return http.Response(
          '{"deliveryUrls":{"inkstamp/user-1/stamp/id-1":'
          '"https://api.cloudinary.com/private"}}',
          200,
        );
      }),
    );

    const publicId = 'inkstamp/user-1/stamp/id-1';
    expect(await repository.resolve(publicId), contains('cloudinary.com'));
    expect(await repository.resolve(publicId), contains('cloudinary.com'));
    expect(calls, 1);
  });

  test('rejects unauthorized delivery responses', () async {
    final repository = CloudinaryDeliveryRepository(
      gatewayBaseUrl: 'http://127.0.0.1:8787',
      authToken: () async => 'firebase-token',
      appCheckToken: () async => null,
      client: MockClient(
        (_) async => http.Response('{"error":"forbidden"}', 403),
      ),
    );

    await expectLater(
      repository.resolve('inkstamp/user-2/stamp/id-1'),
      throwsException,
    );
  });
}
