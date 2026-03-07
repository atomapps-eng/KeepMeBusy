import 'dart:io';
import 'package:image/image.dart' as img;

class ReceiptImageProcessor {

  static Future<File> enhance(File file) async {

    final bytes = await file.readAsBytes();

    img.Image? image = img.decodeImage(bytes);

    if (image == null) return file;

    /// resize supaya OCR lebih stabil
    image = img.copyResize(image, width: 1400);

    /// grayscale
    image = img.grayscale(image);

    /// increase contrast
    image = img.adjustColor(image, contrast: 1.5);

    image = img.gaussianBlur(image, radius: 1);

    /// threshold manual
    image = _applyThreshold(image, 140);

    final processedBytes = img.encodeJpg(image, quality: 90);

    final processedFile =
        File(file.path.replaceAll('.jpg', '_processed.jpg'));

    await processedFile.writeAsBytes(processedBytes);

    return processedFile;
  }

  static img.Image _applyThreshold(img.Image src, int threshold) {

    for (final pixel in src) {

      final luminance =
          (pixel.r + pixel.g + pixel.b) ~/ 3;

      if (luminance < threshold) {

        pixel
          ..r = 0
          ..g = 0
          ..b = 0;

      } else {

        pixel
          ..r = 255
          ..g = 255
          ..b = 255;

      }
    }

    return src;
  }
}