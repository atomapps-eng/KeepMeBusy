import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/partner.dart';

class PartnerService {
  final _collection =
      FirebaseFirestore.instance.collection('partners');

  // =========================
  // STREAM ALL PARTNERS
  // =========================
  Stream<List<Partner>> getPartners() {
    return _collection
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Partner.fromDoc(doc))
          .toList();
    });
  }

  // =========================
  // CREATE PARTNER
  // =========================
  Future<void> addPartner({
    required String name,
    required String address,
    required double lat,
    required double lng,
    required String logoUrl,
  }) async {
    final now = Timestamp.now();

    await _collection.add({
      'name': name.trim(),
      'address': address.trim(),
      'geo': {
        'lat': lat,
        'lng': lng,
      },
      'logoUrl': logoUrl,
      'createdAt': now,
      'updatedAt': now,
    });
  }

  // =========================
  // UPDATE PARTNER
  // =========================
  Future<void> updatePartner({
    required String id,
    required String name,
    required String address,
    required double lat,
    required double lng,
    required String logoUrl,
  }) async {
    await _collection.doc(id).update({
      'name': name.trim(),
      'address': address.trim(),
      'geo': {
        'lat': lat,
        'lng': lng,
      },
      'logoUrl': logoUrl,
      'updatedAt': Timestamp.now(),
    });
  }

  // =========================
  // DELETE PARTNER
  // =========================
  Future<void> deletePartner(String id) async {
    await _collection.doc(id).delete();
  }
}
