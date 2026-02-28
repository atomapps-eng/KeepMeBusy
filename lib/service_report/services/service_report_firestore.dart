// lib/services/service_report_firestore.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/session/company_session.dart';
import '../../models/user_model.dart';
import 'company_collection_resolver.dart';

class ServiceReportFirestore {
  
  // Stream untuk SUPER ADMIN - menggunakan collectionGroup
  static Stream<QuerySnapshot<Map<String, dynamic>>> streamAllCompaniesReports({
    required List<String> companyIds,
  }) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.error('User not authenticated');
    }

    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collectionGroup('service_reports')
        .orderBy("createdAt", descending: true);

    // SUPER ADMIN bisa lihat semua company dalam companyIds mereka
    if (companyIds.isNotEmpty) {
      query = query.where('companyId', whereIn: companyIds);
    }

    return query.snapshots();
  }

  // Stream untuk REGULAR USER - berdasarkan company terpilih
  static Stream<QuerySnapshot<Map<String, dynamic>>> streamCompanyReports() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.error('User not authenticated');
    }

    return CompanyCollectionResolver
        .serviceReports()
        .orderBy("createdAt", descending: true)
        .snapshots();
  }

  // Method utama - dipanggil UI
  static Stream<QuerySnapshot<Map<String, dynamic>>> streamReports({
    required UserModel user,
  }) {
    if (user.role == 'super_admin') {
      // SUPER ADMIN: Gunakan collectionGroup dengan filter companyIds
      return streamAllCompaniesReports(companyIds: user.companyIds);
    } else {
      // REGULAR USER: Hanya bisa lihat company yang dipilih
      return streamCompanyReports();
    }
  }

  // CREATE
static Future<String> createServiceReport({
  required Map<String, dynamic> data,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw Exception("User not authenticated");

  final companyId = CompanySession.selectedCompanyId;
  if (companyId == null) throw Exception("Company not selected.");
  
  print("Creating report for company: $companyId");
  
  final sheetId = await generateSheetId();

  // Buat document reference TERLEBIH DAHULU
  final docRef = FirebaseFirestore.instance
      .collection('companies')
      .doc(companyId)
      .collection('service_reports')
      .doc(); // Auto-generate ID

  final reportData = {
    ...data,
    "sheetId": sheetId,
    "status": "Draft",
    "createdAt": FieldValue.serverTimestamp(),
    "createdBy": user.uid,
    "companyId": companyId,
  };

  print("Saving report with ID: ${docRef.id}");
  print("Data: $reportData");
  
  // Simpan dengan ID yang sudah digenerate
  await docRef.set(reportData);
  
  // Return ID dokumen
  return docRef.id;
}

  // UPDATE
  static Future<void> updateServiceReport({
    required String companyId,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not authenticated");

    await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('service_reports')
        .doc(docId)
        .update({
      ...data,
      "updatedAt": FieldValue.serverTimestamp(),
      "updatedBy": user.uid,
    });
  }

  // SUBMIT
  static Future<void> submitServiceReport({
    required String companyId,
    required String docId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not authenticated");

    await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('service_reports')
        .doc(docId)
        .update({
      "status": "Submitted",
      "submittedAt": FieldValue.serverTimestamp(),
      "submittedBy": user.uid,
    });
  }

  // DELETE
  static Future<void> deleteServiceReport({
    required String companyId,
    required String docId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not authenticated");

    // Verifikasi kepemilikan
    final doc = await getReport(companyId: companyId, docId: docId);
    if (doc.data()?['createdBy'] != user.uid) {
      throw Exception("You can only delete your own reports");
    }

    await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('service_reports')
        .doc(docId)
        .delete();
  }

  // GET SINGLE
  static Future<DocumentSnapshot<Map<String, dynamic>>> getReport({
    required String companyId,
    required String docId,
  }) async {
    print("Getting report from: companies/$companyId/service_reports/$docId");
    return await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('service_reports')
        .doc(docId)
        .get();
  }

  // GENERATE SHEET ID
  static Future<String> generateSheetId() async {
    final companyId = CompanySession.selectedCompanyId;
    if (companyId == null) throw Exception("Company not selected.");

    final year = DateTime.now().year;
    final counterRef = FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('counters')
        .doc('service_report_$year');

    // Run in transaction untuk keamanan
    return await FirebaseFirestore.instance.runTransaction<String>(
      (transaction) async {
        final snapshot = await transaction.get(counterRef);
        final current = (snapshot.data()?['current'] ?? 0) + 1;
        
        transaction.set(counterRef, {'current': current});
        
        return "SR-$year-${current.toString().padLeft(4, '0')}";
      },
    );
  }
}