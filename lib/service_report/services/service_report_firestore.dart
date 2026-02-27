// lib/services/service_report_firestore.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/session/company_session.dart';
import '../../models/user_model.dart';
import 'company_collection_resolver.dart';

class ServiceReportFirestore {
  // Method untuk super_admin - PERBAIKI INI
  static Stream<QuerySnapshot<Map<String, dynamic>>> streamAllCompaniesReports({
    required List<String> companyIds,
  }) {
    // Tambahkan .withConverter untuk menentukan tipe data
    return FirebaseFirestore.instance
    .collectionGroup('service_reports')
    .withConverter<Map<String, dynamic>>(
      fromFirestore: (snapshot, _) => snapshot.data()!,
      toFirestore: (data, _) => data,
    )
    .where('companyId', whereIn: companyIds)
    .orderBy("createdAt", descending: true)
    .snapshots();
  }

  // Method untuk stream berdasarkan selected company (untuk admin/user)
  static Stream<QuerySnapshot<Map<String, dynamic>>> streamCompanyReports() {

   return CompanyCollectionResolver
    .serviceReports()
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (snapshot, _) => snapshot.data()!,
          toFirestore: (data, _) => data,
        )
        .orderBy("createdAt", descending: true)
        .snapshots();
  }

  // Method utama yang akan dipanggil UI
  static Stream<QuerySnapshot<Map<String, dynamic>>> streamReports({
    required UserModel user,
  }) {
    if (user.role == 'super_admin') {
      return streamAllCompaniesReports(companyIds: user.companyIds);
    } else {
      return streamCompanyReports();
    }
  }

  // CREATE
static Future<String> createServiceReport({
  required Map<String, dynamic> data,
}) async {
  final companyId = CompanySession.selectedCompanyId;

  if (companyId == null) {
    throw Exception("Company not selected.");
  }

  // Generate sheetId TERLEBIH DAHULU sebelum save
  final sheetId = await generateSheetId();

  final docRef = CompanyCollectionResolver
    .serviceReports()
    .doc();

  // Data yang akan disimpan
  final reportData = {
    ...data, // Data dari form
    "sheetId": sheetId,
    "status": "Draft", // Default status
    "createdAt": FieldValue.serverTimestamp(),
    "createdBy": "user-id-here", // TODO: ambil dari auth
    "companyId": companyId, // Simpan companyId untuk memudahkan filtering
  };

  await docRef.set(reportData);
  
  // Return sheetId untuk keperluan UI (optional)
  return sheetId;
}

  // UPDATE
  static Future<void> updateServiceReport(
    String docId,
    Map<String, dynamic> data,
  ) async {
    final companyId = CompanySession.selectedCompanyId;

    if (companyId == null) {
      throw Exception("Company not selected.");
    }

    await CompanyCollectionResolver
    .serviceReports()
    .doc(docId)
    .update(data);
  }

  // GET SINGLE
  static Future<DocumentSnapshot<Map<String, dynamic>>> getReport(
      String docId) async {
    final companyId = CompanySession.selectedCompanyId;

    if (companyId == null) {
      throw Exception("Company not selected.");
    }

    return await CompanyCollectionResolver
    .serviceReports()
    .doc(docId)
    .withConverter<Map<String, dynamic>>(
      fromFirestore: (snapshot, _) => snapshot.data()!,
      toFirestore: (data, _) => data,
    )
    .get();
  }

  // GENERATE SHEET ID
  static Future<String> generateSheetId() async {
    final companyId = CompanySession.selectedCompanyId;

    if (companyId == null) {
      throw Exception("Company not selected.");
    }

    final year = DateTime.now().year;
    final counterRef = CompanyCollectionResolver
    .counters()
    .doc('service_report_$year');

    return FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(counterRef);

      int newNumber = 1;

      if (snapshot.exists) {
        final data = snapshot.data();
        final current = data?['current'] ?? 0;
        newNumber = current + 1;
      }

      transaction.set(counterRef, {
        'current': newNumber,
      });

      final padded = newNumber.toString().padLeft(4, '0');
      return "SR-$year-$padded";
    });
  }

  // Private getter untuk collection (hanya dipakai admin/user)
  static CollectionReference<Map<String, dynamic>> get _collection {
    final companyId = CompanySession.selectedCompanyId;

    if (companyId == null) {
      throw Exception("Company not selected.");
    }

    return FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('service_reports')
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (snapshot, _) => snapshot.data()!,
          toFirestore: (data, _) => data,
        );
  }

// Tambahkan method ini setelah updateServiceReport
static Future<void> submitServiceReport(String docId) async {
  final companyId = CompanySession.selectedCompanyId;

  if (companyId == null) {
    throw Exception("Company not selected.");
  }

  await CompanyCollectionResolver
    .serviceReports()
    .doc(docId)
    .update({
        "status": "Submitted",
        "submittedAt": FieldValue.serverTimestamp(),
        "submittedBy": "user-id-here", // TODO: ambil dari auth
      });
}

}