import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ReceiptLayout {

  final List<String> header;
  final List<String> items;
  final List<String> totals;

  ReceiptLayout({
    required this.header,
    required this.items,
    required this.totals,
  });
}

class ReceiptLayoutAnalyzer {

  static ReceiptLayout analyze(RecognizedText recognizedText) {

    final lines = <String>[];

    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        lines.add(line.text);
      }
    }

    final header = <String>[];
    final items = <String>[];
    final totals = <String>[];

    for (int i = 0; i < lines.length; i++) {

      final line = lines[i].toLowerCase();

      if (line.contains('total') ||
          line.contains('amount') ||
          line.contains('grand')) {

        totals.add(lines[i]);

      } else if (RegExp(r'\d+[.,]\d{2}').hasMatch(line)) {

        items.add(lines[i]);

      } else {

        header.add(lines[i]);

      }

    }

    return ReceiptLayout(
      header: header,
      items: items,
      totals: totals,
    );
  }
}