import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/spare_part.dart';

class SparePartService {
  final _db = FirebaseFirestore.instance;

  String normalizeLocation(String location) {
  return location
      .trim()
      .toUpperCase()
      .replaceAll(' ', '')
      .replaceAll('.', '-');
}

  Stream<List<SparePart>> getSpareParts() {
    return _db.collection('spare_parts').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return SparePart.fromMap(data, doc.id);
      }).toList();
    });
  }

  Future<void> addSparePart(String id, Map<String, dynamic> data) async {
    await _db.collection('spare_parts').doc(id).set(data);
  }

  Future<void> updateSparePart(String id, Map<String, dynamic> data) async {
    await _db.collection('spare_parts').doc(id).update(data);
  }

  Future<void> deleteSparePart(String partCode, String location) async {
  final locationKey = normalizeLocation(location);

  final batch = FirebaseFirestore.instance.batch();

  final partRef = FirebaseFirestore.instance
      .collection('spare_parts')
      .doc(partCode);

  final locationRef = FirebaseFirestore.instance
      .collection('locations')
      .doc(locationKey);

  batch.delete(partRef);

  // 🔥 HAPUS location JIKA ADA (legacy support)
  final locationSnap = await locationRef.get();
  if (locationSnap.exists) {
    batch.delete(locationRef);
  }

  await batch.commit();
}

}
