import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/spare_part.dart';
import '../core/services/company_firestore.dart';

class SparePartService {
  Future<QuerySnapshot> fetchSpareParts({
    DocumentSnapshot? lastDoc,
    int limit = 50,
  }) async {

    Query query = CompanyFirestore
        .collection('spare_parts')
        .orderBy('partCode')
        .limit(limit);

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    return await query.get();
  }
  String normalizeLocation(String location) {
  return location
      .trim()
      .toUpperCase()
      .replaceAll(' ', '')
      .replaceAll('.', '-');
}

Stream<List<SparePart>> getSpareParts() {
  final ref = CompanyFirestore.collection('spare_parts');

  return ref.snapshots().map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return SparePart.fromMap(data, doc.id);
    }).toList();
  });
}

  Future<void> addSparePart(String id, Map<String, dynamic> data) async {
  await CompanyFirestore.doc('spare_parts', id).set(data);
}

Future<void> updateSparePart(String id, Map<String, dynamic> data) async {
  await CompanyFirestore.doc('spare_parts', id).update(data);
}

 Future<void> deleteSparePart(String partCode, String location) async {
  final locationKey = normalizeLocation(location);

  final batch = FirebaseFirestore.instance.batch();

  final partRef =
      CompanyFirestore.doc('spare_parts', partCode);

  final locationRef =
      CompanyFirestore.doc('locations', locationKey);

  batch.delete(partRef);

  // 🔥 HAPUS location JIKA ADA (legacy support)
  final locationSnap = await locationRef.get();
  if (locationSnap.exists) {
    batch.delete(locationRef);
  }

  await batch.commit();
}

}
