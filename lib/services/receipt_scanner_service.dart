import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ReceiptScannerService {

  final ImagePicker _picker = ImagePicker();

  /// SCAN RECEIPT (CAMERA)
  Future<File?> scanReceipt() async {

    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (picked == null) return null;

    return File(picked.path);
  }

  /// OCR TEXT
  Future<String> recognizeText(File imageFile) async {

    final inputImage = InputImage.fromFile(imageFile);

    final textRecognizer =
        TextRecognizer(script: TextRecognitionScript.latin);

    final RecognizedText recognizedText =
        await textRecognizer.processImage(inputImage);

    await textRecognizer.close();

    return recognizedText.text;
  }

  Future<RecognizedText> recognizeLayout(File imageFile) async {

  final inputImage = InputImage.fromFile(imageFile);

  final textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  final recognizedText =
      await textRecognizer.processImage(inputImage);

  textRecognizer.close();

  return recognizedText;
}

}