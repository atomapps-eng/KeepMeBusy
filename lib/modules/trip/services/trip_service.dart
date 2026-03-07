import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/trip_model.dart';

class TripService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  /// Ambil companyId dari user login
  Future<String> getCompanyId() async {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final userDoc =
      await _firestore.collection('users').doc(uid).get();
 final data = userDoc.data();
  if (data == null) {
    throw Exception("User document not found");
  }
  final List companyIds = data['companyIds'];
  return companyIds.first;
}

Future<String> _getCompanyId() async {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  final userDoc =
      await _firestore.collection('users').doc(uid).get();

  final data = userDoc.data()!;

  final List companyIds = data['companyIds'];

  return companyIds.first;
}

  /// CREATE TRIP
  Future<void> createTrip(Trip trip) async {
  final companyId = await _getCompanyId();
  final uid = FirebaseAuth.instance.currentUser!.uid;

  await _firestore
      .collection('companies')
      .doc(companyId)
      .collection('trips')
      .add({
    ...trip.toMap(),
    'createdBy': uid,
    'createdAt': FieldValue.serverTimestamp(),
  });
}

  /// STREAM TRIPS
  Stream<List<Trip>> streamTrips(String companyId) {
  return _firestore
      .collection('companies')
      .doc(companyId)
      .collection('trips')
      .orderBy('startDate', descending: true)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) {
          return Trip.fromMap(doc.id, doc.data());
        }).toList();
      });
}

  /// DELETE TRIP
  Future<void> deleteTrip(String tripId) async {
    final companyId = await _getCompanyId();

    await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('trips')
        .doc(tripId)
        .delete();
  }

Future<Map<String, dynamic>> getCurrentUserData() async {

  final uid = FirebaseAuth.instance.currentUser!.uid;

  final doc =
      await _firestore.collection('users').doc(uid).get();

  return doc.data()!;
}

Future<void> updateTrip(Trip trip) async {

  final companyId = await _getCompanyId();

  await _firestore
      .collection('companies')
      .doc(companyId)
      .collection('trips')
      .doc(trip.id)
      .update(trip.toMap());
}

}