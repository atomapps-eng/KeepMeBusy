import 'dart:typed_data';
import 'package:printing/printing.dart';

Future<void> openPdf(Uint8List bytes, String fileName) async {
  await Printing.layoutPdf(
    onLayout: (_) async => bytes,
  );
}