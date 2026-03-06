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

  final firebaseUser = FirebaseAuth.instance.currentUser;

  print("========== SERVICE REPORT STREAM ==========");
  print("Firebase UID: ${firebaseUser?.uid}");
  print("Firebase Email: ${firebaseUser?.email}");
  print("UserModel role: ${user.role}");
  print("UserModel companyIds: ${user.companyIds}");
  print("Selected company session: ${CompanySession.selectedCompanyId}");
  print("===========================================");

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
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw Exception("User not authenticated");

  final companyId = CompanySession.selectedCompanyId;
  if (companyId == null) throw Exception("Company not selected.");

  final sheetId = await generateSheetId();

  // 🔹 Ambil user document dari root users
  final userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();

  final username =
      userDoc.data()?['username'] ?? user.email ?? user.uid;

  final docRef = FirebaseFirestore.instance
      .collection('companies')
      .doc(companyId)
      .collection('service_reports')
      .doc();

  final reportData = {
    ...data,
    "sheetId": sheetId,
    "status": "Draft",
    "createdAt": FieldValue.serverTimestamp(),
    "createdBy": user.uid,
    "createdByName": username,   // 🔥 SNAPSHOT NAME
    "companyId": companyId,
  };

  await docRef.set(reportData);

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
 // SUBMIT (HYBRID SNAPSHOT)
static Future<void> submitServiceReport({
  required String companyId,
  required String docId,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw Exception("User not authenticated");

  final firestore = FirebaseFirestore.instance;

  final userDoc = await firestore
    .collection('users')
    .doc(user.uid)
    .get();

  final username =
    userDoc.data()?['username'] ?? user.email ?? user.uid;

  final reportRef = firestore
      .collection('companies')
      .doc(companyId)
      .collection('service_reports')
      .doc(docId);

  // 1️⃣ Ambil report dulu
  final reportSnap = await reportRef.get();
  if (!reportSnap.exists) {
    throw Exception("Report not found");
  }

  final reportData = reportSnap.data()!;

 Map<String, dynamic> updateData = {
  "status": "Submitted",
  "submittedAt": FieldValue.serverTimestamp(),
  "submittedBy": user.uid,
  "submittedByName": username,   // 🔥 SNAPSHOT NAME
};

  // 2️⃣ SNAPSHOT FACTORY
  if (reportData['factoryId'] != null) {
    final factoryDoc = await firestore
        .collection('companies')
        .doc(companyId)
        .collection('partners')
        .doc(reportData['factoryId'])
        .get();

    final factoryData = factoryDoc.data();

    updateData.addAll({
      "factoryCity": factoryData?['city'],
      "factoryCountry": factoryData?['country'],
      "factoryAddress": factoryData?['address'],
    });
  }

  // 3️⃣ SNAPSHOT END CUSTOMER (optional)
  if (reportData['endCustomerId'] != null) {
    final endCustomerDoc = await firestore
        .collection('companies')
        .doc(companyId)
        .collection('partners')
        .doc(reportData['endCustomerId'])
        .get();

    final endCustomerData = endCustomerDoc.data();

    updateData.addAll({
      "endCustomerCity": endCustomerData?['city'],
      "endCustomerCountry": endCustomerData?['country'],
    });
  }

  // 4️⃣ Update report sekali saja
  await reportRef.update(updateData);
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