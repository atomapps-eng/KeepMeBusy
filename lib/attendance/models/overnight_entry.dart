import 'package:cloud_firestore/cloud_firestore.dart';

class OvernightEntry {
  final String id;
  final DateTime startDate;
  final DateTime endDate;
  final int totalNights;
  final String customerName;
  final String customerCategory;

  OvernightEntry({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.totalNights,
    required this.customerName,
    required this.customerCategory,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'totalNights': totalNights,
      'customerName': customerName,
      'customerCategory': customerCategory,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
