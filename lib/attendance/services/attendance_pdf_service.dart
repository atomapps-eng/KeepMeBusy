import '../models/attendance_day.dart';
import '../models/attendance_period.dart';

class AttendancePdfService {
  Future<void> generatePdf({
    required AttendancePeriod period,
    required List<AttendanceDay> days,
  }) async {
    // TODO:
    // 1. Copy engine PDF dari Order Out
    // 2. Ganti header → Attendance Report
    // 3. Table harian
    // 4. Table overnight
    // 5. Summary
  }
}
