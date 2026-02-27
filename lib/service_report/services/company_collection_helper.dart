import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/session/company_session.dart';

class CompanyCollectionHelper {
  static CollectionReference<Map<String, dynamic>> partners() {
    final companyId = CompanySession.selectedCompanyId;

    if (companyId == null) {
      throw Exception("Company not selected");
    }

    if (companyId == 'atomIndonesia') {
      return FirebaseFirestore.instance.collection('partners');
    }

    return FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('partners');
  }

  static CollectionReference<Map<String, dynamic>> spareParts() {
    final companyId = CompanySession.selectedCompanyId;

    if (companyId == null) {
      throw Exception("Company not selected");
    }

    if (companyId == 'atomIndonesia') {
      return FirebaseFirestore.instance.collection('spare_parts');
    }

    return FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('spare_parts');
  }
}