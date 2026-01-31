import 'package:cloud_firestore/cloud_firestore.dart';

class Overnight {
  final String id;
  final DateTime startDate;
  final DateTime endDate;
  final int totalNights;
  final String partnerName;
  final String partnerCategory; // domestic | overseas
  final Timestamp createdAt;

  Overnight({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.totalNights,
    required this.partnerName,
    required this.partnerCategory,
    required this.createdAt,
  });

  factory Overnight.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Overnight(
      id: doc.id,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      totalNights: data['totalNights'] ?? 0,
      partnerName: data['partnerName'] ?? '',
      partnerCategory: data['partnerCategory'] ?? 'domestic',
      createdAt: data['createdAt'] as Timestamp,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'totalNights': totalNights,
      'partnerName': partnerName,
      'partnerCategory': partnerCategory,
      'createdAt': createdAt,
    };
  }
}
