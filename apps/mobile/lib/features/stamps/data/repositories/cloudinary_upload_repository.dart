import 'dart:convert';
import 'dart:io';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:inkstamp/features/stamps/domain/repositories/media_upload_repository.dart';
import 'package:uuid/uuid.dart';

final Provider<MediaUploadRepository> mediaUploadRepositoryProvider =
    Provider<MediaUploadRepository>((Ref ref) => CloudinaryUploadRepository());

class CloudinaryUploadRepository implements MediaUploadRepository {
  CloudinaryUploadRepository({
    this.gatewayUrl = 'https://media.inkstamp.app/v1/media/upload-signatures',
  });

  final String gatewayUrl;
  final Uuid _uuid = const Uuid();

  @override
  Future<String> uploadStamp(String localPath) async {
    return _upload(localPath, 'stamp');
  }

  @override
  Future<String> uploadThumbnail(String localPath) async {
    return _upload(localPath, 'thumbnail');
  }

  Future<String> _upload(String localPath, String mediaKind) async {
    final File file = File(localPath);
    if (!await file.exists()) {
      // In demo mode or if file path is simulated, return dummy ID
      if (localPath.startsWith('simulated/')) {
        return 'inkstamp/current-user/$mediaKind/${_uuid.v4()}';
      }
      throw Exception('Local file does not exist at $localPath');
    }

    final String idToken = await _getAuthToken();
    final String? appCheckToken = await _getAppCheckToken();

    if (idToken == 'demo-token') {
      return 'inkstamp/current-user/$mediaKind/${_uuid.v4()}';
    }

    final Map<String, String> headers = <String, String>{
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
    };
    if (appCheckToken != null) {
      headers['X-Firebase-App-Check'] = appCheckToken;
    }

    final http.Response signatureRes = await http.post(
      Uri.parse(gatewayUrl),
      headers: headers,
      body: jsonEncode(<String, String>{'mediaKind': mediaKind}),
    );

    if (signatureRes.statusCode != 200) {
      throw Exception('Failed to get Cloudinary signature: ${signatureRes.body}');
    }

    final Map<String, dynamic> signatureData =
        jsonDecode(signatureRes.body) as Map<String, dynamic>;

    final String uploadUrl = signatureData['uploadUrl'] as String;
    final Map<String, dynamic> params =
        signatureData['parameters'] as Map<String, dynamic>;

    final http.MultipartRequest request =
        http.MultipartRequest('POST', Uri.parse(uploadUrl));

    request.files.add(await http.MultipartFile.fromPath('file', localPath));

    params.forEach((String key, dynamic value) {
      request.fields[key] = value.toString();
    });
    request.fields['api_key'] = signatureData['apiKey'] as String;

    final http.StreamedResponse response = await request.send();
    final String responseBody = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw Exception('Cloudinary upload failed: $responseBody');
    }

    final Map<String, dynamic> uploadResult =
        jsonDecode(responseBody) as Map<String, dynamic>;
    return uploadResult['public_id'] as String;
  }

  Future<String> _getAuthToken() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        return await user.getIdToken() ?? '';
      }
    } catch (_) {}
    return 'demo-token';
  }

  Future<String?> _getAppCheckToken() async {
    try {
      return await FirebaseAppCheck.instance.getToken();
    } catch (_) {}
    return null;
  }
}
