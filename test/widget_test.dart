import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_app/attendance/services/attendance_period_helper.dart';
import 'package:inventory_app/attendance/services/overnight_helper.dart';

void main() {
  group('Attendance helpers', () {
    test('resolvePeriod follows the 26th cut-off', () {
      expect(
        AttendancePeriodHelper.resolvePeriod(DateTime(2026, 2, 25)),
        '2026-02',
      );
      expect(
        AttendancePeriodHelper.resolvePeriod(DateTime(2026, 2, 26)),
        '2026-03',
      );
    });

    test('calculateTotalNights counts calendar nights', () {
      expect(
        OvernightHelper.calculateTotalNights(
          DateTime(2026, 1, 1, 20),
          DateTime(2026, 1, 3, 8),
        ),
        2,
      );
      expect(
        OvernightHelper.calculateTotalNights(
          DateTime(2026, 1, 3),
          DateTime(2026, 1, 1),
        ),
        0,
      );
    });
  });
}
