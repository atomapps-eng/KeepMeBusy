import 'package:cloud_firestore/cloud_firestore.dart';
import '../session/company_session.dart';

class CompanyFirestore {
  static CollectionReference<Map<String, dynamic>> collection(String name) {
    final companyId = CompanySession.selectedCompanyId;

    if (companyId == null) {
      throw Exception("Company not selected");
    }

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

    return FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection(collection)
        .doc(docId);
  }
}