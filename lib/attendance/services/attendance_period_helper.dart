class AttendancePeriodHelper {
  /// Menghasilkan periode berdasarkan cut off tanggal 25
  /// Contoh:
  /// 2026-01-26 → 2026-02
  /// 2026-02-25 → 2026-02
  /// 2026-02-26 → 2026-03
  static String resolvePeriod(DateTime date) {
    if (date.day >= 26) {
      final nextMonth = DateTime(date.year, date.month + 1, 1);
      return _formatPeriod(nextMonth);
    } else {
      return _formatPeriod(date);
    }
  }

  /// Menghasilkan start & end date periode
  /// Contoh periode 2026-02:
  /// start = 2026-01-26
  /// end   = 2026-02-25
  static DateTimeRange resolvePeriodRange(String period) {
    final parts = period.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);

    final endDate = DateTime(year, month, 25);
    final startDate = DateTime(year, month - 1, 26);

    return DateTimeRange(start: startDate, end: endDate);
  }

  static String _formatPeriod(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    return '${date.year}-$month';
  }
}

class DateTimeRange {
  final DateTime start;
  final DateTime end;

  DateTimeRange({required this.start, required this.end});
}
