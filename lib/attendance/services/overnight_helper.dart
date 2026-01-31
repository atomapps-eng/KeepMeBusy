class OvernightHelper {
  /// Hitung jumlah malam menginap
  /// Contoh:
  /// 1 Jan → 2 Jan = 1 malam
  /// 1 Jan → 3 Jan = 2 malam
  static int calculateTotalNights(
    DateTime startDate,
    DateTime endDate,
  ) {
    final start = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );
    final end = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
    );

    final diff = end.difference(start).inDays;
    return diff < 0 ? 0 : diff;
  }
}
