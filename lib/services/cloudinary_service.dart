import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CloudinaryService {
  // === CONFIG (SAMAKAN DENGAN EDIT SPARE PART) ===
  static const String cloudName = 'djl2sukor';
  static const String uploadPreset = 'spare_parts_images';

  // =========================
  // UPLOAD IMAGE
  // =========================
  static Future<String> uploadImage({
    required File file,
    required String folder,
    required String publicId,
  }) async {
    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', url);

    request.fields['upload_preset'] = uploadPreset;
    request.fields['folder'] = folder;
    request.fields['public_id'] =
        '${publicId}_${DateTime.now().millisecondsSinceEpoch}';

    request.files.add(
      await http.MultipartFile.fromPath('file', file.path),
    );

    final response = await request.send();
    final body = await response.stream.bytesToString();
    final data = json.decode(body);

    if (response.statusCode == 200) {
      return data['secure_url']; // ⬅️ simpan ke Firestore
    } else {
      throw Exception('Cloudinary upload failed');
    }
  }
}
