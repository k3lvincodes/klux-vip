import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kenick_vip/config/env_config.dart';

class CloudinaryService {
  static String get _cloudName => EnvConfig.cloudinaryCloudName;
  static String get _uploadPreset => EnvConfig.cloudinaryUploadPreset;

  /// Uploads an image file to Cloudinary and returns the secure URL.
  /// Returns `null` on failure.
  static Future<String?> uploadImage(File imageFile) async {
    if (_cloudName.isEmpty || _uploadPreset.isEmpty) {
      debugPrint('CloudinaryService: Missing CLOUDINARY_CLOUD_NAME or CLOUDINARY_UPLOAD_PRESET in .env');
      return null;
    }

    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');

    try {
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonData = json.decode(responseData);
        return jsonData['secure_url'] as String?;
      } else {
        debugPrint('CloudinaryService: Upload failed with status ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('CloudinaryService: Upload error: $e');
      return null;
    }
  }
}
