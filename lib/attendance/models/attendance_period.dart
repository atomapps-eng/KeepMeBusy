import 'package:cloud_firestore/cloud_firestore.dart';

class AttendancePeriod {
  final String id;
  final String employeeId;
  final String employeeName;

  final String period; // YYYY-MM
  final DateTime startDate;
  final DateTime endDate;

  final Map<String, int> statusSummary;
  final int overnightCount;

  final bool submitted;
  final bool approved;
  final String? approvedBy;
  final DateTime? approvedAt;

  AttendancePeriod({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.statusSummary,
    required this.overnightCount,
    this.submitted = false,
    this.approved = false,
    this.approvedBy,
    this.approvedAt,
  });

  factory AttendancePeriod.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return AttendancePeriod(
      id: doc.id,
      employeeId: data['employeeId'],
      employeeName: data['employeeName'],
      period: data['period'],
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      statusSummary: Map<String, int>.from(data['statusSummary'] ?? {}),
      overnightCount: data['overnightCount'] ?? 0,
      submitted: data['submitted'] ?? false,
      approved: data['approved'] ?? false,
      approvedBy: data['approvedBy'],
      approvedAt: data['approvedAt'] != null
          ? (data['approvedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'period': period,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'statusSummary': statusSummary,
      'overnightCount': overnightCount,
      'submitted': submitted,
      'approved': approved,
      'approvedBy': approvedBy,
      'approvedAt':
          approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }
}
