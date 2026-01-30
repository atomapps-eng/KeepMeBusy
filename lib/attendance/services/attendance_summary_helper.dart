import '../models/attendance_day.dart';

class AttendanceSummaryHelper {
  static Map<String, int> calculateStatusSummary(
    List<AttendanceDay> days,
  ) {
    final Map<String, int> summary = {
      'off': 0,
      'present': 0,
      'sickLeave': 0,
      'annualLeave': 0,
      'traveling': 0,
      'joinHoliday': 0,
    };

    for (final day in days) {
      final key = day.status.name;
      summary[key] = (summary[key] ?? 0) + 1;
    }

    return summary;
  }

  static int calculateOvernightCount(
    List<AttendanceDay> days,
  ) {
    return days.where((d) => d.overnightEnabled).length;
  }
}
