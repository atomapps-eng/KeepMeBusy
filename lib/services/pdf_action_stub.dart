import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart'; // ✅ tambahin ini
import 'dart:io';

Future<void> openPdf(Uint8List bytes, String fileName) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$fileName');

  await file.writeAsBytes(bytes);

  await OpenFilex.open(file.path); // 🔥 INI YANG BENAR
}