import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/session/company_session.dart';

class CompanyCollectionResolver {
  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static String _getCompanyId() {
    final companyId = CompanySession.selectedCompanyId;

    if (companyId == null) {
      throw Exception("Company not selected");
    }

    return companyId;
  }

  /// ================= PARTNERS =================
  static CollectionReference<Map<String, dynamic>> partners() {
  final companyId = _getCompanyId();

  return _firestore
      .collection('companies')
      .doc(companyId)
      .collection('partners');
}

  /// ================= SPARE PARTS =================
  static CollectionReference<Map<String, dynamic>> spareParts() {
    final companyId = _getCompanyId();

    if (companyId == 'atomIndonesia') {
      return _firestore.collection('spare_parts');
    }

    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('spare_parts');
  }

  /// ================= SERVICE REPORTS =================
  static CollectionReference<Map<String, dynamic>> serviceReports() {
    final companyId = _getCompanyId();

    if (companyId == 'atomIndonesia') {
      return _firestore.collection('service_reports');
    }

    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('service_reports');
  }

  /// ================= COUNTERS =================
static CollectionReference<Map<String, dynamic>> counters() {
  final companyId = _getCompanyId();

  if (companyId == 'atomIndonesia') {
    return _firestore.collection('counters');
  }

  return _firestore
      .collection('companies')
      .doc(companyId)
      .collection('counters');
}

}