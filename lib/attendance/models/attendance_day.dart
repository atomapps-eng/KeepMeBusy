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

AttendanceStatus parseAttendanceStatus(String raw) {
  switch (raw) {
    case 'present':
      return AttendanceStatus.present;
    case 'off':
      return AttendanceStatus.off;
    case 'sickLeave':
    case 'sick_leave':
      return AttendanceStatus.sickLeave;
    case 'annualLeave':        // ⬅ DATA KAMU SAAT INI
    case 'annual_leave':
      return AttendanceStatus.annualLeave;
    case 'traveling':
      return AttendanceStatus.traveling;
    case 'joinHoliday':
    case 'join_holiday':
      return AttendanceStatus.joinHoliday;
    default:
      throw Exception('Unknown attendance status: $raw');
  }
}

String serializeAttendanceStatus(AttendanceStatus status) {
  switch (status) {
    case AttendanceStatus.present:
      return 'present';
    case AttendanceStatus.off:
      return 'off';
    case AttendanceStatus.sickLeave:
      return 'sick_leave';
    case AttendanceStatus.annualLeave:
      return 'annual_leave';
    case AttendanceStatus.traveling:
      return 'traveling';
    case AttendanceStatus.joinHoliday:
      return 'join_holiday';
  }
}

extension AttendanceStatusLabel on AttendanceStatus {
  String get label {
    switch (this) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.off:
        return 'Off';
      case AttendanceStatus.sickLeave:
        return 'Sick Leave';
      case AttendanceStatus.annualLeave:
        return 'Annual Leave';
      case AttendanceStatus.traveling:
        return 'Travel';
      case AttendanceStatus.joinHoliday:
        return 'Join Holiday';
    }
  }
}


String serializeAttendanceLocation(AttendanceLocation location) {
  switch (location) {
    case AttendanceLocation.office:
      return 'office';
    case AttendanceLocation.outstation:
      return 'outstation';
  }
}

AttendanceLocation parseAttendanceLocation(String? raw) {
  if (raw == null) {
    // default aman
    return AttendanceLocation.office;
  }

  switch (raw) {
    case 'office':
    case 'Office':
      return AttendanceLocation.office;
    case 'outstation':
    case 'Outstation':
      return AttendanceLocation.outstation;
    default:
      throw Exception('Unknown attendance location: $raw');
  }
}

AttendanceStatus parseAttendanceStatusSafe(String raw) {
  return AttendanceStatus.values.firstWhere(
    (e) => e.name == raw,
    orElse: () => AttendanceStatus.off,
  );
}


class AttendanceDay {
  final String id;
  final String employeeId;
  final DateTime date;
  final String period;

  final AttendanceStatus status;
  final AttendanceLocation location;

  final String? customerId;
  final String? customerName;
  final String? note;

  final bool overnightEnabled;
  final String? overnightLocation; // domestic | overseas
  final String? overnightCustomerId;
  final DateTime? overnightStartDate;
  final DateTime? overnightEndDate;

  final String? customer;
final int? checkInHour;
final int? checkInMinute;
final int? checkOutHour;
final int? checkOutMinute;



  final bool approved;

  AttendanceDay({
    required this.id,
    required this.employeeId,
    required this.date,
    required this.period,
    required this.status,
    required this.location,
    this.customer,
    this.checkInHour,
this.checkInMinute,
this.checkOutHour,
this.checkOutMinute,
    this.note,
    this.customerId,
    this.customerName,
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
      status: parseAttendanceStatus(data['status']),
      location: parseAttendanceLocation(data['location']),
      customerId: data['customerId'],
      customerName: data['customerName'],
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
          customer: data['customer'],
checkInHour: data['checkInHour'],
checkInMinute: data['checkInMinute'],
checkOutHour: data['checkOutHour'],
checkOutMinute: data['checkOutMinute'],


      approved: data['approved'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'employeeId': employeeId,
      'date': Timestamp.fromDate(date),
      'period': period,
      'status': serializeAttendanceStatus(status),
      'location': serializeAttendanceLocation(location),
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
      'checkInHour': checkInHour,
'checkInMinute': checkInMinute,
'checkOutHour': checkOutHour,
'checkOutMinute': checkOutMinute,

      'approved': approved,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
