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
      'overtime': calculateTotalOvertime(days),
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

  static bool isOvertimeDay(AttendanceDay d) {
  if (d.status != AttendanceStatus.present) return false;

  if (d.checkOutHour == null) return false;

  if (d.checkOutHour! > 18) return true;

  if (d.checkOutHour == 18 && (d.checkOutMinute ?? 0) > 0) {
    return true;
  }

  return false;
}
static int calculateTotalOvertime(List<AttendanceDay> days) {
  int total = 0;

  for (final d in days) {
    if (isOvertimeDay(d)) {
      total++;
    }
  }

  return total;
}


}
