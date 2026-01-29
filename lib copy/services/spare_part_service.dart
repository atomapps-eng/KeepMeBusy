import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/spare_part.dart';

class SparePartService {
  final _db = FirebaseFirestore.instance;

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

  Future<void> deleteSparePart(String id) async {
    await _db.collection('spare_parts').doc(id).delete();
  }
}
