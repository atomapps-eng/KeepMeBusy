class ReceiptCurrencyDetector {

  static String detectCurrency(String text) {

    final lower = text.toLowerCase();

    if (lower.contains('aud') || lower.contains('a\$')) {
      return 'AUD';
    }

    if (lower.contains('sgd')) {
      return 'SGD';
    }

    if (lower.contains('myr')) {
      return 'MYR';
    }

    if (lower.contains('jpy') || lower.contains('¥')) {
      return 'JPY';
    }

    if (lower.contains('idr') || lower.contains('rp')) {
      return 'IDR';
    }

    return ''; // fallback
  }

}