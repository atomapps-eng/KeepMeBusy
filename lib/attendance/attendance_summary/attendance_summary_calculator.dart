import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/company_firestore.dart';
import '../models/attendance_day.dart';
import 'attendance_summary_model.dart';

class AttendanceSummaryCalculator {
  static Future<AttendanceSummaryModel> calculate({
    required String employeeId,
    required String period,
  }) async {
    // ================= ATTENDANCE =================
    var dayQuery = CompanyFirestore.collection(
      'attendance',
    ).doc(employeeId).collection('days');

    final daySnap = period == 'ALL'
        ? await dayQuery.get()
        : await dayQuery.where('period', isEqualTo: period).get();

    final days = daySnap.docs
        .map((d) => AttendanceDay.fromFirestore(d))
        .toList();

    int present = 0;
    int off = 0;
    int sickLeave = 0;
    int annualLeave = 0;
    int traveling = 0;
    int joinHoliday = 0;
    int overtime = 0;
    int office = 0;
    int outstation = 0;

    for (final d in days) {
      switch (d.status) {
        case AttendanceStatus.present:
          present++;

          if (d.location == AttendanceLocation.office) office++;
          if (d.location == AttendanceLocation.outstation) outstation++;
          if (_isOvertime(d)) overtime++;
          break;
        case AttendanceStatus.off:
          off++;
          break;
        case AttendanceStatus.sickLeave:
          sickLeave++;
          break;
        case AttendanceStatus.annualLeave:
          annualLeave++;
          break;
        case AttendanceStatus.traveling:
          traveling++;
          break;
        case AttendanceStatus.joinHoliday:
          joinHoliday++;
          break;
      }
    }

    // ================= ACTIVITY =================
    final List<ActivitySummaryItem> activities = [];
    final Map<String, int> activityByType = {};

    for (final dayDoc in daySnap.docs) {
      final factorySnap = await dayDoc.reference.collection('factories').get();

      for (final factoryDoc in factorySnap.docs) {
        final actSnap = await factoryDoc.reference
            .collection('activities')
            .orderBy('createdAt')
            .get();

        for (final a in actSnap.docs) {
          final data = a.data();
          final type = (data['activityType'] ?? 'UNKNOWN').toString();

          activityByType[type] = (activityByType[type] ?? 0) + 1;

          activities.add(
            ActivitySummaryItem(
              date: (data['date'] as Timestamp).toDate(),
              factory:
                  data['factoryClient'] ??
                  factoryDoc.data()['factoryName'] ??
                  '-',
              machine: data['machine'] ?? '-',
              serialNumber: data['serialNumber'] ?? '-',
              activityType: type,
              description: data['description'] ?? '',
            ),
          );
        }
      }
    }

    // ================= OVERNIGHT =================
    var overnightQuery = CompanyFirestore.collection(
      'attendance',
    ).doc(employeeId).collection('overnight');

    final overnightSnap = period == 'ALL'
        ? await overnightQuery.get()
        : await overnightQuery.where('period', isEqualTo: period).get();

    int domesticNights = 0;
    int internationalNights = 0;
    final List<OvernightSummaryItem> overnights = [];

    for (final d in overnightSnap.docs) {
      final data = d.data();
      final nights = (data['totalNights'] ?? 0) as int;
      final category = data['customerCategory'];

      if (category == 'domestic') {
        domesticNights += nights;
      } else if (category == 'overseas') {
        internationalNights += nights;
      }

      overnights.add(
        OvernightSummaryItem(
          location: category,
          customer: data['customerName'] ?? '-',
          startDate: (data['startDate'] as Timestamp).toDate(),
          endDate: (data['endDate'] as Timestamp).toDate(),
          nights: nights,
        ),
      );
    }

    return AttendanceSummaryModel(
      employeeId: employeeId,
      period: period,
      present: present,
      off: off,
      sickLeave: sickLeave,
      annualLeave: annualLeave,
      traveling: traveling,
      joinHoliday: joinHoliday,
      overtime: overtime,
      office: office,
      outstation: outstation,
      totalActivity: activities.length,
      activityByType: activityByType,
      domesticNights: domesticNights,
      internationalNights: internationalNights,
      attendanceDays: days,
      activities: activities,
      overnights: overnights,
    );
  }

  static bool _isOvertime(AttendanceDay d) {
    if (d.status != AttendanceStatus.present) return false;
    if (d.checkOutHour == null) return false;
    if (d.checkOutHour! > 18) return true;
    if (d.checkOutHour == 18 && (d.checkOutMinute ?? 0) > 0) return true;
    return false;
  }
}
