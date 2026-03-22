// lib/services/cloudinary_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data' show Uint8List;

class CloudinaryService {
  static const String cloudName = 'djl2sukor';
  static const String uploadPreset = 'spare_parts_images';

  static final ImagePicker _picker = ImagePicker();

  // Pilih gambar dari gallery (works for web & mobile)
  static Future<XFile?> pickImageFromGallery() async {
    return await _picker.pickImage(source: ImageSource.gallery);
  }

  static Future<XFile?> pickImageFromCamera() async {
    return await _picker.pickImage(source: ImageSource.camera);
  }

  static Future<XFile?> pickVideoFromGallery() async {
    return await _picker.pickVideo(source: ImageSource.gallery);
  }

  // =========================
  // UPLOAD IMAGE (works for web & mobile)
  // =========================
  static Future<String?> uploadImage({
  required dynamic file, // Gunakan dynamic atau overloading
  required String folder,
  String? publicId,
}) async {
  try {
    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', url);

    request.fields['upload_preset'] = uploadPreset;
    request.fields['folder'] = folder;

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final finalPublicId = publicId ??
        '${folder.replaceAll('/', '_')}_$timestamp';
    request.fields['public_id'] = finalPublicId;

    // Handle file untuk web vs mobile
    if (kIsWeb) {
      // Untuk web: file harus XFile
      if (file is XFile) {
        final bytes = await file.readAsBytes();
        final multipartFile = http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: file.name,
        );
        request.files.add(multipartFile);
      } else {
        throw Exception("Web requires XFile type");
      }
    } else {
      // Untuk mobile/desktop: bisa File atau XFile
      if (file is File) {
        request.files.add(
          await http.MultipartFile.fromPath('file', file.path),
        );
      } else if (file is XFile) {
        request.files.add(
          await http.MultipartFile.fromPath('file', file.path),
        );
      }
    }

    final response = await request.send();
    final body = await response.stream.bytesToString();
    final data = json.decode(body);

    if (response.statusCode == 200) {
      return data['secure_url'];
    } else {
      return null;
    }
  } catch (e) {
    return null;
  }
}

  // =========================
  // UPLOAD VIDEO
  // =========================
  static Future<String?> uploadVideo({
    required XFile file,
    required String folder,
    String? publicId,
  }) async {
    try {
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/video/upload',
      );

      final request = http.MultipartRequest('POST', url);

      request.fields['upload_preset'] = uploadPreset;
      request.fields['folder'] = folder;

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final finalPublicId = publicId ??
          '${folder.replaceAll('/', '_')}_$timestamp';

      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        final multipartFile = http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: file.name,
        );
        request.files.add(multipartFile);
      } else {
        request.files.add(
          await http.MultipartFile.fromPath('file', file.path),
        );
      }

      final response = await request.send();
      final body = await response.stream.bytesToString();
      final data = json.decode(body);

      if (response.statusCode == 200) {
        return data['secure_url'];
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // =========================
  // GENERIC UPLOAD
  // =========================
  static Future<String?> uploadFile({
    required XFile file,
    required String folder,
    String? publicId,
  }) async {
    final fileName = file.name.toLowerCase();
    
    if (fileName.endsWith('.jpg') || 
        fileName.endsWith('.jpeg') || 
        fileName.endsWith('.png') || 
        fileName.endsWith('.gif') || 
        fileName.endsWith('.bmp') ||
        fileName.endsWith('.webp')) {
      return await uploadImage(
        file: file,
        folder: folder,
        publicId: publicId,
      );
    } else if (fileName.endsWith('.mp4') || 
               fileName.endsWith('.mov') || 
               fileName.endsWith('.avi') || 
               fileName.endsWith('.mkv') ||
               fileName.endsWith('.3gp') ||
               fileName.endsWith('.webm')) {
      return await uploadVideo(
        file: file,
        folder: folder,
        publicId: publicId,
      );
    } else {
      throw Exception("Unsupported file type: $fileName. Please upload JPG, PNG, MP4, or MOV files.");
    }
  }

  // Di cloudinary_service.dart, tambahkan method ini:

static Future<String?> uploadBytes({
  required Uint8List bytes,
  required String fileName,
  required String folder,
}) async {
  try {
    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', url);

    request.fields['upload_preset'] = uploadPreset;
    request.fields['folder'] = folder;

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final publicId = '${folder.replaceAll('/', '_')}_$timestamp';
    request.fields['public_id'] = publicId;

    // Upload bytes langsung
    final multipartFile = http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: fileName,
    );
    request.files.add(multipartFile);

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    final data = json.decode(responseBody);

    if (response.statusCode == 200) {
      return data['secure_url'];
    } else {
      return null;
    }
  } catch (e) {
    return null;
  }
}

}