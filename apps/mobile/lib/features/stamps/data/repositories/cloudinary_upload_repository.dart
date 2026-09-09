import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:inkstamp/features/authentication/presentation/controllers/session_controller.dart';
import 'package:inkstamp/features/stamps/domain/repositories/media_upload_repository.dart';
import 'package:uuid/uuid.dart';

const String mediaGatewayBaseUrl = String.fromEnvironment(
  'MEDIA_GATEWAY_BASE_URL',
  defaultValue: 'http://127.0.0.1:8787',
);

final Provider<MediaUploadRepository> mediaUploadRepositoryProvider =
    Provider<MediaUploadRepository>((Ref ref) {
      if (!ref.watch(firebaseInitializedProvider)) {
        return DemoMediaUploadRepository();
      }
      return CloudinaryUploadRepository(
        gatewayBaseUrl: mediaGatewayBaseUrl,
        authToken: () async {
          final User? user = FirebaseAuth.instance.currentUser;
          if (user == null) {
            throw const MediaUploadException('Sign in before uploading.');
          }
          final String? token = await user.getIdToken();
          if (token == null || token.isEmpty) {
            throw const MediaUploadException('Unable to authenticate upload.');
          }
          return token;
        },
        appCheckToken: () => FirebaseAppCheck.instance.getToken(),
      );
    });

typedef TokenLoader = Future<String?> Function();

class CloudinaryUploadRepository implements MediaUploadRepository {
  CloudinaryUploadRepository({
    required this.gatewayBaseUrl,
    required this.authToken,
    required this.appCheckToken,
    http.Client? client,
    this.timeout = const Duration(seconds: 30),
    this.maximumBytes = 5 * 1024 * 1024,
  }) : _client = client ?? http.Client();

  final String gatewayBaseUrl;
  final TokenLoader authToken;
  final TokenLoader appCheckToken;
  final Duration timeout;
  final int maximumBytes;
  final http.Client _client;

  @override
  Future<String> uploadStamp(String localPath) => _upload(localPath, 'stamp');

  @override
  Future<String> uploadThumbnail(String localPath) =>
      _upload(localPath, 'thumbnail');

  @override
  Future<void> delete(String publicId) async {
    await _gatewayRequest('/v1/media/delete', <String, Object>{
      'publicId': publicId,
    }, failureMessage: 'Unable to clean up the uploaded image.');
  }

  Future<String> _upload(String localPath, String mediaKind) async {
    final File file = File(localPath);
    if (!await file.exists()) {
      throw const MediaUploadException('The image file no longer exists.');
    }
    if (!localPath.toLowerCase().endsWith('.jpg') &&
        !localPath.toLowerCase().endsWith('.jpeg')) {
      throw const MediaUploadException('Only JPEG images can be uploaded.');
    }
    if (await file.length() > maximumBytes) {
      throw const MediaUploadException('The image must be smaller than 5 MB.');
    }

    try {
      final Map<String, dynamic> signature = await _gatewayRequest(
        '/v1/media/upload-signatures',
        <String, Object>{'mediaKind': mediaKind},
        failureMessage: 'Upload authorization failed.',
      );
      final Uri uploadUrl = Uri.parse(_requiredString(signature, 'uploadUrl'));
      final String apiKey = _requiredString(signature, 'apiKey');
      final Object? rawParameters = signature['parameters'];
      if (rawParameters is! Map<String, dynamic>) {
        throw const MediaUploadException(
          'Invalid upload authorization response.',
        );
      }

      final http.MultipartRequest request =
          http.MultipartRequest('POST', uploadUrl)
            ..files.add(await http.MultipartFile.fromPath('file', localPath))
            ..fields['api_key'] = apiKey;
      rawParameters.forEach(
        (key, value) => request.fields[key] = value.toString(),
      );
      final String expectedPublicId =
          '${_requiredString(rawParameters, 'folder')}/'
          '${_requiredString(rawParameters, 'public_id')}';
      final http.StreamedResponse uploadResponse = await _client
          .send(request)
          .timeout(timeout);
      final String responseBody = await uploadResponse.stream.bytesToString();
      if (uploadResponse.statusCode < 200 || uploadResponse.statusCode >= 300) {
        throw MediaUploadException(
          'Cloudinary upload failed (${uploadResponse.statusCode}).',
        );
      }
      final Map<String, dynamic> result = _decodeObject(responseBody);
      final String publicId = _requiredString(result, 'public_id');
      if (result['resource_type'] != 'image' || publicId != expectedPublicId) {
        throw const MediaUploadException(
          'Cloudinary returned an invalid image identifier.',
        );
      }
      return publicId;
    } on MediaUploadException {
      rethrow;
    } on TimeoutException {
      throw const MediaUploadException('The upload timed out. Please retry.');
    } on Object {
      throw const MediaUploadException(
        'Unable to upload the image. Please retry.',
      );
    }
  }

  Future<Map<String, dynamic>> _gatewayRequest(
    String path,
    Map<String, Object> body, {
    required String failureMessage,
  }) async {
    try {
      final String? appCheck = await appCheckToken();
      final http.Response response = await _client
          .post(
            Uri.parse('$gatewayBaseUrl$path'),
            headers: <String, String>{
              'Authorization': 'Bearer ${await authToken()}',
              'Content-Type': 'application/json',
              if (appCheck != null && appCheck.isNotEmpty)
                'X-Firebase-App-Check': appCheck,
            },
            body: jsonEncode(body),
          )
          .timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw MediaUploadException('$failureMessage (${response.statusCode}).');
      }
      return _decodeObject(response.body);
    } on MediaUploadException {
      rethrow;
    } on TimeoutException {
      throw const MediaUploadException('The request timed out. Please retry.');
    } on Object {
      throw MediaUploadException('$failureMessage Please retry.');
    }
  }

  Map<String, dynamic> _decodeObject(String source) {
    final Object? decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const MediaUploadException('Invalid server response.');
    }
    return decoded;
  }

  String _requiredString(Map<String, dynamic> source, String key) {
    final Object? value = source[key];
    if (value is! String || value.isEmpty) {
      throw const MediaUploadException('Invalid server response.');
    }
    return value;
  }
}

class DemoMediaUploadRepository implements MediaUploadRepository {
  final Uuid _uuid = const Uuid();

  @override
  Future<String> uploadStamp(String localPath) async =>
      'inkstamp/current-user/stamp/${_uuid.v4()}';

  @override
  Future<String> uploadThumbnail(String localPath) async =>
      'inkstamp/current-user/thumbnail/${_uuid.v4()}';

  @override
  Future<void> delete(String publicId) async {}
}

class MediaUploadException implements Exception {
  const MediaUploadException(this.message);
  final String message;
}
