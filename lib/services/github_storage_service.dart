import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';

class GithubStorageService {

  static const owner = "atomapps-eng";
  static const repo = "receipt-storage";
  static const token = "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"; // ganti dengan token github

  static Future<String?> uploadFile(File file) async {

    final bytes = await file.readAsBytes();
    final base64File = base64Encode(bytes);

    String extension = file.path.split('.').last;

final fileName =
    "receipt_${DateTime.now().millisecondsSinceEpoch}.$extension";

    final url =
        "https://api.github.com/repos/$owner/$repo/contents/receipts/$fileName";

    final dio = Dio();

    final response = await dio.put(
      url,
      options: Options(
        headers: {
          "Authorization": "token $token",
          "Content-Type": "application/json",
        },
      ),
      data: {
        "message": "upload receipt",
        "content": base64File,
      },
    );

    if (response.statusCode == 201) {

      return "https://raw.githubusercontent.com/$owner/$repo/main/receipts/$fileName";

    }

    return null;
  }
}