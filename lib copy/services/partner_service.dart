import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/partner.dart';

class PartnerService {
  final CollectionReference _ref =
      FirebaseFirestore.instance.collection('partners');

  Stream<List<Partner>> getPartners() {
    return _ref
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Partner.fromFirestore(doc))
          .toList();
    });
  }

  Future<void> addPartner({
    required String name,
    required String address,
    double? lat,
    double? lng,
    String? phone,
    String? email,
    required String logoUrl,
  }) async {
    await _ref.add({
      'name': name,
      'address': address,
      'lat': lat,
      'lng': lng,
      'phone': phone,
      'email': email,
      'logoUrl': logoUrl,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> updatePartner({
    required String id,
    required String name,
    required String address,
    double? lat,
    double? lng,
    String? phone,
    String? email,
    required String logoUrl,
  }) async {
    await _ref.doc(id).update({
      'name': name,
      'address': address,
      'lat': lat,
      'lng': lng,
      'phone': phone,
      'email': email,
      'logoUrl': logoUrl,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> deletePartner(String id) async {
    await _ref.doc(id).delete();
  }
}
