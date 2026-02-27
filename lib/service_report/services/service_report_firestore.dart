import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/session/company_session.dart';

class ServiceReportFirestore {
  static CollectionReference<Map<String, dynamic>> get _collection {
    final companyId = CompanySession.selectedCompanyId;

    if (companyId == null) {
      throw Exception("Company not selected.");
    }

    return FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('service_reports');
  }

  // CREATE
 static Future<void> createServiceReport({
  required Map<String, dynamic> data,
}) async {
  final sheetId = await generateSheetId();

  final doc = _collection.doc();

  await doc.set({
    ...data,
    "sheetId": sheetId,
    "status": "Draft",
    "createdAt": FieldValue.serverTimestamp(),
  });
}

  // UPDATE
  static Future<void> updateServiceReport(
    String docId,
    Map<String, dynamic> data,
  ) async {
    await _collection.doc(docId).update(data);
  }

  // STREAM LIST
  static Stream<QuerySnapshot<Map<String, dynamic>>> streamReports() {
    return _collection
        .orderBy("createdAt", descending: true)
        .snapshots();
  }

  // GET SINGLE
  static Future<DocumentSnapshot<Map<String, dynamic>>> getReport(
      String docId) {
    return _collection.doc(docId).get();
  }

  static Future<String> generateSheetId() async {
  final companyId = CompanySession.selectedCompanyId;

  if (companyId == null) {
    throw Exception("Company not selected.");
  }

  final year = DateTime.now().year;
  final counterRef = FirebaseFirestore.instance
      .collection('companies')
      .doc(companyId)
      .collection('counters')
      .doc('service_report_$year');

  return FirebaseFirestore.instance.runTransaction((transaction) async {
    final snapshot = await transaction.get(counterRef);

    int newNumber = 1;

    if (snapshot.exists) {
      final current = snapshot.data()?['current'] ?? 0;
      newNumber = current + 1;
    }

    transaction.set(counterRef, {
      'current': newNumber,
    });

    final padded = newNumber.toString().padLeft(4, '0');

    return "SR-$year-$padded";
  });
}

}