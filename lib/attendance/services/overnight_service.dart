import '../models/overnight_entry.dart';
import '../../core/services/company_firestore.dart';

class OvernightService {

  Future<void> addOvernight({
    required String employeeId,
    required OvernightEntry entry,
  }) async {
    await CompanyFirestore
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
  await CompanyFirestore
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
  await CompanyFirestore
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
