class ReceiptAmountExtractor {

  static double? extractAmount(String text) {

    final lines = text.split('\n');

    double? bestAmount;
    int bestScore = -999;

    for (int i = 0; i < lines.length; i++) {

      final line = lines[i].toLowerCase();

      final numberMatch =
          RegExp(r'(\d+[.,]\d{2})').firstMatch(line);

      if (numberMatch == null) continue;

      final rawNumber = numberMatch.group(0)!;

      final normalized =
          rawNumber.replaceAll(',', '.');

      final amount = double.tryParse(normalized);

      if (amount == null) continue;

      int score = 0;

      /// KEYWORD BOOST
      if (line.contains('total')) score += 100;
      if (line.contains('amount')) score += 60;
      if (line.contains('grand')) score += 60;

      /// NEGATIVE KEYWORDS
      if (line.contains('subtotal')) score -= 30;
      if (line.contains('tax')) score -= 20;
      if (line.contains('service')) score -= 20;
      if (line.contains('change')) score -= 20;

      /// POSITION BOOST (receipt biasanya total di bawah)
      if (i > lines.length * 0.6) {
        score += 20;
      }

      /// AMOUNT SIZE BOOST
      if (amount > 1) {
        score += 5;
      }

      if (score > bestScore) {
        bestScore = score;
        bestAmount = amount;
      }

    }

    return bestAmount;
  }
}