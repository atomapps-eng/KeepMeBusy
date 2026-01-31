import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/overnight_entry.dart';

class OvernightService {
  final _db = FirebaseFirestore.instance;

  Future<void> addOvernight({
    required String employeeId,
    required OvernightEntry entry,
  }) async {
    await _db
        .collection('attendance')
        .doc(employeeId)
        .collection('overnight')
        .add(entry.toFirestore());
  }
  Future<void> updateOvernight({
  required String employeeId,
  required String docId,
  required OvernightEntry entry,
}) async {
  await FirebaseFirestore.instance
      .collection('attendance')
      .doc(employeeId)
      .collection('overnight')
      .doc(docId)
      .update({
    'startDate': entry.startDate,
    'endDate': entry.endDate,
    'totalNights': entry.totalNights,
    'customerName': entry.customerName,
    'customerCategory': entry.customerCategory,
  });
}

}
Future<void> updateOvernight({
  required String employeeId,
  required String docId,
  required OvernightEntry entry,
}) async {
  await FirebaseFirestore.instance
      .collection('attendance')
      .doc(employeeId)
      .collection('overnight')
      .doc(docId)
      .update({
    'startDate': entry.startDate,
    'endDate': entry.endDate,
    'totalNights': entry.totalNights,
    'customerName': entry.customerName,
    'customerCategory': entry.customerCategory,
  });
}
