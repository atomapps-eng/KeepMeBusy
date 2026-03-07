class ReceiptConfidenceCalculator {

  static double calculate({
    required double? amount,
    required String currency,
    required String text,
  }) {

    double score = 0;

    if (amount != null) {
      score += 0.5;
    }

    if (currency.isNotEmpty) {
      score += 0.2;
    }

    if (text.length > 50) {
      score += 0.3;
    }

    return score;
  }

}