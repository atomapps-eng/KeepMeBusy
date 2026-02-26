import 'package:cloud_firestore/cloud_firestore.dart';
import '../session/company_session.dart';

class CompanyFirestore {

  static bool get _isRootCompany =>
    CompanySession.selectedCompanyId == "atomIndonesia";

  static CollectionReference<Map<String, dynamic>> collection(String name) {
    final companyId = CompanySession.selectedCompanyId;

    if (companyId == null) {
      throw Exception("Company not selected");
    }

    if (_isRootCompany) {
      // 🇮🇩 ROOT STRUCTURE
      return FirebaseFirestore.instance.collection(name);
    }

    // 🇮🇳 🇻🇳 MULTI COMPANY STRUCTURE
    return FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection(name);
  }

  static DocumentReference<Map<String, dynamic>> doc(
      String collection,
      String docId,
  ) {
    final companyId = CompanySession.selectedCompanyId;

    if (companyId == null) {
      throw Exception("Company not selected");
    }

    if (_isRootCompany) {
      // 🇮🇩 ROOT STRUCTURE
      return FirebaseFirestore.instance
          .collection(collection)
          .doc(docId);
    }

    // 🇮🇳 🇻🇳 MULTI COMPANY STRUCTURE
    return FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection(collection)
        .doc(docId);
  }
}