import 'package:cloud_firestore/cloud_firestore.dart';

enum AttendanceStatus {
  off,
  present,
  sickLeave,
  annualLeave,
  traveling,
  joinHoliday,
}

enum AttendanceLocation {
  office,
  outstation,
}

class AttendanceDay {
  final String id;
  final String employeeId;
  final DateTime date;
  final String period;

  final AttendanceStatus status;
  final AttendanceLocation location;

  final String? customerId;
  final String? note;

  final bool overnightEnabled;
  final String? overnightLocation; // domestic | overseas
  final String? overnightCustomerId;
  final DateTime? overnightStartDate;
  final DateTime? overnightEndDate;

  final bool approved;

  AttendanceDay({
    required this.id,
    required this.employeeId,
    required this.date,
    required this.period,
    required this.status,
    required this.location,
    this.customerId,
    this.note,
    this.overnightEnabled = false,
    this.overnightLocation,
    this.overnightCustomerId,
    this.overnightStartDate,
    this.overnightEndDate,
    this.approved = false,
  });

  factory AttendanceDay.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return AttendanceDay(
      id: doc.id,
      employeeId: data['employeeId'],
      date: (data['date'] as Timestamp).toDate(),
      period: data['period'],
      status: AttendanceStatus.values.firstWhere(
        (e) => e.name == data['status'],
      ),
      location: AttendanceLocation.values.firstWhere(
        (e) => e.name == data['location'],
      ),
      customerId: data['customerId'],
      note: data['note'],
      overnightEnabled: data['overnight']?['enabled'] ?? false,
      overnightLocation: data['overnight']?['location'],
      overnightCustomerId: data['overnight']?['customerId'],
      overnightStartDate: data['overnight']?['startDate'] != null
          ? (data['overnight']['startDate'] as Timestamp).toDate()
          : null,
      overnightEndDate: data['overnight']?['endDate'] != null
          ? (data['overnight']['endDate'] as Timestamp).toDate()
          : null,
      approved: data['approved'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'employeeId': employeeId,
      'date': Timestamp.fromDate(date),
      'period': period,
      'status': status.name,
      'location': location.name,
      'customerId': customerId,
      'note': note,
      'overnight': {
        'enabled': overnightEnabled,
        'location': overnightLocation,
        'customerId': overnightCustomerId,
        'startDate': overnightStartDate != null
            ? Timestamp.fromDate(overnightStartDate!)
            : null,
        'endDate': overnightEndDate != null
            ? Timestamp.fromDate(overnightEndDate!)
            : null,
      },
      'approved': approved,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
