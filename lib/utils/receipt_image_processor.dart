import 'dart:io';
import 'package:image/image.dart' as img;

class ReceiptImageProcessor {

  static Future<File> enhanceForOCR(File originalFile) async {

    final bytes = await originalFile.readAsBytes();

    img.Image? image = img.decodeImage(bytes);

    if (image == null) return originalFile;

    /// resize supaya OCR lebih stabil
    image = img.copyResize(image, width: 1400);

    /// grayscale untuk OCR saja
    image = img.grayscale(image);

    /// contrast
    image = img.adjustColor(
      image,
      contrast: 1.8,
      brightness: 0.05,
    );

    /// sharpen
    image = img.convolution(image, filter: [
      0,-1,0,
     -1,5,-1,
      0,-1,0
    ]);

    /// blur ringan
    image = img.gaussianBlur(image, radius: 1);

    final processedBytes = img.encodeJpg(image, quality: 90);

    final processedFile =
        File(originalFile.path.replaceAll('.jpg', '_ocr.jpg'));

    await processedFile.writeAsBytes(processedBytes);

    return processedFile;
  }
}