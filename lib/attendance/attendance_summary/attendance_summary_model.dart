import '../models/attendance_day.dart';

class AttendanceSummaryModel {
  // ===== IDENTITAS =====
  final String employeeId;
  final String period;

  // ===== ATTENDANCE COUNTS =====
  final int present;
  final int off;
  final int sickLeave;
  final int annualLeave;
  final int traveling;
  final int joinHoliday;
  final int overtime;

  // ===== LOCATION =====
  final int office;
  final int outstation;

  // ===== ACTIVITY =====
  final int totalActivity;
  final Map<String, int> activityByType;

  // ===== OVERNIGHT =====
  final int domesticNights;
  final int internationalNights;

  // ===== DETAIL DATA =====
  final List<AttendanceDay> attendanceDays;
  final List<ActivitySummaryItem> activities;
  final List<OvernightSummaryItem> overnights;

  AttendanceSummaryModel({
    required this.employeeId,
    required this.period,
    required this.present,
    required this.off,
    required this.sickLeave,
    required this.annualLeave,
    required this.traveling,
    required this.joinHoliday,
    required this.overtime,
    required this.office,
    required this.outstation,
    required this.totalActivity,
    required this.activityByType,
    required this.domesticNights,
    required this.internationalNights,
    required this.attendanceDays,
    required this.activities,
    required this.overnights,
  });
}

// =======================================================
// ACTIVITY SUMMARY ITEM
// =======================================================
class ActivitySummaryItem {
  final DateTime date;
  final String factory;
  final String machine;
  final String serialNumber;
  final String activityType;
  final String description;

  ActivitySummaryItem({
    required this.date,
    required this.factory,
    required this.machine,
    required this.serialNumber,
    required this.activityType,
    required this.description,
  });
}

// =======================================================
// OVERNIGHT SUMMARY ITEM
// =======================================================
class OvernightSummaryItem {
  final String location; // domestic / overseas
  final String customer;
  final DateTime startDate;
  final DateTime endDate;
  final int nights;

  OvernightSummaryItem({
    required this.location,
    required this.customer,
    required this.startDate,
    required this.endDate,
    required this.nights,
  });
}
