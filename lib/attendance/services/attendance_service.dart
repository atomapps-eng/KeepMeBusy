import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/attendance_day.dart';
import '../models/attendance_period.dart';

class AttendanceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // =========================
  // PATH HELPER (OPSI B)
  // attendance/{employeeId}/days/{YYYY-MM-DD}
  // =========================
  CollectionReference<Map<String, dynamic>> _daysRef(String employeeId) {
    return _db
        .collection('attendance')
        .doc(employeeId)
        .collection('days');
  }

  // =========================
  // ATTENDANCE DAY
  // =========================

  Future<void> saveAttendanceDay(AttendanceDay day) async {
    await _daysRef(day.employeeId)
        .doc(day.id)
        .set(day.toFirestore(), SetOptions(merge: true));
  }

  Stream<List<AttendanceDay>> streamAttendanceDays(String employeeId) {
    return _daysRef(employeeId).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => AttendanceDay.fromFirestore(doc))
              .toList(),
        );
  }

  // =========================
  // ATTENDANCE PERIOD (SUMMARY)
  // attendance_periods/{employeeId}_{YYYY-MM}
  // =========================

  Future<void> saveAttendancePeriod(AttendancePeriod period) async {
    await _db
        .collection('attendance_periods')
        .doc(period.id)
        .set(period.toFirestore(), SetOptions(merge: true));
  }

  Future<AttendancePeriod?> getAttendancePeriodById(
    String periodId,
  ) async {
    final doc = await _db
        .collection('attendance_periods')
        .doc(periodId)
        .get();

    if (!doc.exists) return null;
    return AttendancePeriod.fromFirestore(doc);
  }
}
