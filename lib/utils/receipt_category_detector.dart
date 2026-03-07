class ReceiptCategoryDetector {

  static String detectCategory(String text) {

    final lower = text.toLowerCase();

    if (
      lower.contains('hotel') ||
      lower.contains('inn') ||
      lower.contains('resort')
    ) {
      return 'Hotel';
    }

    if (
      lower.contains('restaurant') ||
      lower.contains('cafe') ||
      lower.contains('coffee') ||
      lower.contains('food') ||
      lower.contains('meal')
    ) {
      return 'Meal';
    }

    if (
      lower.contains('taxi') ||
      lower.contains('grab') ||
      lower.contains('uber') ||
      lower.contains('bus') ||
      lower.contains('train')
    ) {
      return 'Transportation';
    }

    return 'Other';
  }

}