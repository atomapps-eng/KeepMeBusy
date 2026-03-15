import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GithubStorageService {

  static String owner = dotenv.env['GITHUB_OWNER']!;
  static String repo = dotenv.env['GITHUB_REPO']!;
  static String token = dotenv.env['GITHUB_TOKEN']!;

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