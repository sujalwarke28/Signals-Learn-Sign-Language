import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../core/config/app_config.dart';

class UploadFailure implements Exception {
  const UploadFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

class UploadResult {
  const UploadResult({
    required this.secureUrl,
    required this.publicId,
    required this.durationSeconds,
    this.thumbnailUrl,
  });

  final String secureUrl;
  final String publicId;

  /// Cloudinary probes the file and reports its real duration, so the admin
  /// never has to type it in.
  final int durationSeconds;
  final String? thumbnailUrl;
}

/// Unsigned client-side upload to Cloudinary.
///
/// Unsigned is deliberate: a signed upload needs the API secret, and anything
/// compiled into an APK or a web bundle can be extracted from it. The upload
/// preset is the only credential the app carries, and it grants nothing but
/// "may add a file to this folder".
class CloudinaryService {
  CloudinaryService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  bool get isConfigured => AppConfig.isCloudinaryConfigured;

  /// Cloudinary routes by resource type in the path: `video` probes duration and
  /// can render poster frames, `image` applies image transformations.
  Uri _endpointFor(String resourceType) => Uri.parse(
      'https://api.cloudinary.com/v1_1/${AppConfig.cloudinaryCloudName}/$resourceType/upload');

  /// Uploads [bytes] and returns the delivery URL plus probed metadata.
  ///
  /// [onProgress] reports 0..1. The underlying HTTP client doesn't expose real
  /// upload progress on web, so callers get a coarse indication only.
  Future<UploadResult> uploadVideo({
    required Uint8List bytes,
    required String filename,
  }) async {
    final body = await _post(
      resourceType: 'video',
      bytes: bytes,
      filename: filename,
    );

    final secureUrl = body['secure_url'] as String?;
    final publicId = body['public_id'] as String?;
    if (secureUrl == null || publicId == null) {
      throw const UploadFailure('Cloudinary response was missing the video URL.');
    }

    return UploadResult(
      secureUrl: secureUrl,
      publicId: publicId,
      durationSeconds: (body['duration'] as num?)?.round() ?? 0,
      thumbnailUrl: thumbnailFor(secureUrl),
    );
  }

  /// Uploads a still image — used for the optional picture on a quiz question —
  /// and returns its delivery URL. Images carry none of the probed metadata a
  /// video does, so the URL is all there is to report.
  Future<String> uploadImage({
    required Uint8List bytes,
    required String filename,
  }) async {
    final body = await _post(
      resourceType: 'image',
      bytes: bytes,
      filename: filename,
    );

    final secureUrl = body['secure_url'] as String?;
    if (secureUrl == null) {
      throw const UploadFailure('Cloudinary response was missing the image URL.');
    }
    return secureUrl;
  }

  /// The multipart POST both uploads share, including the configuration guard
  /// and Cloudinary's error shape.
  Future<Map<String, dynamic>> _post({
    required String resourceType,
    required Uint8List bytes,
    required String filename,
  }) async {
    if (!isConfigured) {
      throw const UploadFailure(
        'Cloudinary isn\'t configured yet. See docs/02-cloudinary-setup.md.',
      );
    }

    final request = http.MultipartRequest('POST', _endpointFor(resourceType))
      ..fields['upload_preset'] = AppConfig.cloudinaryUploadPreset
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));

    late http.Response response;
    try {
      final streamed = await _client.send(request);
      response = await http.Response.fromStream(streamed);
    } catch (e) {
      throw UploadFailure('Upload failed: $e');
    }

    final body = _decode(response.body);
    if (response.statusCode >= 400) {
      final message = (body?['error'] as Map?)?['message'] as String?;
      throw UploadFailure(message ?? 'Cloudinary rejected the upload '
          '(HTTP ${response.statusCode}).');
    }
    if (body == null) {
      throw const UploadFailure('Cloudinary returned an unreadable response.');
    }
    return body;
  }

  /// Cloudinary renders a poster frame from the video asset itself: keep the
  /// `/video/upload/` delivery type and just ask for a jpg extension.
  ///
  /// Swapping in `/image/upload/` instead looks plausible but 404s — that path
  /// addresses the *image* namespace, where an uploaded video has no asset.
  static String? thumbnailFor(String videoUrl) {
    if (!videoUrl.contains('/video/upload/')) return null;
    final dot = videoUrl.lastIndexOf('.');
    final slash = videoUrl.lastIndexOf('/');
    final base = dot > slash ? videoUrl.substring(0, dot) : videoUrl;
    return '$base.jpg';
  }

  Map<String, dynamic>? _decode(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  void dispose() => _client.close();
}
