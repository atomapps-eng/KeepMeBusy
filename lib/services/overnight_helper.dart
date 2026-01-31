class OvernightHelper {
  static int calculateTotalNights(
    DateTime start,
    DateTime end,
  ) {
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);

    final diff = endDate.difference(startDate).inDays;
    return diff < 0 ? 0 : diff;
  }
}
