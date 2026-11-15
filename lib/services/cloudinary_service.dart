import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

enum CloudinaryFolder {
  eventPosters('draghub/event-posters'),
  paymentProofs('draghub/payment-proofs');

  const CloudinaryFolder(this.path);

  final String path;
}

class CloudinaryService {
  CloudinaryService({
    required String cloudName,
    required String uploadPreset,
    http.Client? client,
  }) : _cloudName = _validateConfig(cloudName, 'cloudName'),
       _uploadPreset = _validateConfig(uploadPreset, 'uploadPreset'),
       _client = client ?? http.Client(),
       _ownsClient = client == null;

  final String _cloudName;
  final String _uploadPreset;
  final http.Client _client;
  final bool _ownsClient;

  void close() {
    if (_ownsClient) _client.close();
  }

  Future<Uri> uploadImage({
    required Uint8List bytes,
    required String fileName,
    required CloudinaryFolder folder,
  }) async {
    if (bytes.isEmpty) {
      throw ArgumentError.value(bytes.length, 'bytes', 'Image cannot be empty');
    }
    if (fileName.trim().isEmpty) {
      throw ArgumentError.value(fileName, 'fileName', 'Must not be empty');
    }

    final request =
        http.MultipartRequest(
            'POST',
            Uri.https('api.cloudinary.com', '/v1_1/$_cloudName/image/upload'),
          )
          ..fields['upload_preset'] = _uploadPreset
          ..fields['folder'] = folder.path
          ..files.add(
            http.MultipartFile.fromBytes('file', bytes, filename: fileName),
          );

    final streamedResponse = await _client
        .send(request)
        .timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamedResponse)
        .timeout(const Duration(seconds: 30));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CloudinaryUploadException(
        'Cloudinary upload failed with HTTP ${response.statusCode}.',
      );
    }

    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic> || body['secure_url'] is! String) {
      throw const CloudinaryUploadException(
        'Cloudinary response did not contain a secure image URL.',
      );
    }

    final uri = Uri.tryParse(body['secure_url'] as String);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw const CloudinaryUploadException(
        'Cloudinary returned an invalid secure image URL.',
      );
    }
    return uri;
  }

  static String _validateConfig(String value, String name) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(value, name, 'Must not be empty');
    }
    return normalized;
  }
}

class CloudinaryUploadException implements Exception {
  const CloudinaryUploadException(this.message);

  final String message;

  @override
  String toString() => 'CloudinaryUploadException: $message';
}
