import 'dart:typed_data';
import 'dart:html' as html;

Future<void> openPdf(Uint8List bytes, String fileName) async {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);

  html.window.open(url, "_blank");
}