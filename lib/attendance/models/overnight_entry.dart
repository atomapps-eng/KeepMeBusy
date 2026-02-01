import 'package:cloud_firestore/cloud_firestore.dart';


class OvernightEntry {
  final String id;
  final DateTime startDate;
  final DateTime endDate;
  final int totalNights;
  final String customerName;
  final String customerCategory;
  final String period; // ✅ TAMBAH

  OvernightEntry({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.totalNights,
    required this.customerName,
    required this.customerCategory,
    required this.period, // ✅ TAMBAH
  });

  Map<String, dynamic> toFirestore() {
    return {
      'period': period, // ✅ SIMPAN PERIOD
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'totalNights': totalNights,
      'customerName': customerName,
      'customerCategory': customerCategory,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
