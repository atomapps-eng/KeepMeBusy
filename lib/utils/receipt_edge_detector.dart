import 'dart:io';
import 'package:image/image.dart' as img;

class ReceiptEdgeDetector {

  static Future<File> autoCrop(File file) async {

    final bytes = await file.readAsBytes();
    img.Image? image = img.decodeImage(bytes);

    if (image == null) return file;

    final width = image.width;
    final height = image.height;

    // crop sedikit dari pinggir untuk menghilangkan background
    final cropX = (width * 0.05).toInt();
    final cropY = (height * 0.05).toInt();
    final cropWidth = (width * 0.9).toInt();
    final cropHeight = (height * 0.9).toInt();

    final cropped = img.copyCrop(
      image,
      x: cropX,
      y: cropY,
      width: cropWidth,
      height: cropHeight,
    );

    final newBytes = img.encodeJpg(cropped);

    final newFile = File(file.path.replaceAll(".jpg", "_crop.jpg"));

    await newFile.writeAsBytes(newBytes);

    return newFile;
  }
}