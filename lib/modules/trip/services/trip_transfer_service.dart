import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip_transfer_model.dart';
import 'trip_service.dart';

class TripTransferService {

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TripService tripService = TripService();

  Future<void> createTransfer(
      String tripId,
      TripTransfer transfer,
      ) async {

    final companyId = await tripService.getCompanyId();

    await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('trips')
        .doc(tripId)
        .collection('transfers')
        .add(transfer.toMap());
  }

  Stream<List<TripTransfer>> streamTransfers(String tripId) async* {

  final companyId = await tripService.getCompanyId();

  yield* _firestore
      .collection('companies')
      .doc(companyId)
      .collection('trips')
      .doc(tripId)
      .collection('transfers')
      .orderBy('date', descending: true)
      .snapshots()
      .map((snapshot) {

    return snapshot.docs.map((doc) {
      return TripTransfer.fromMap(doc.id, doc.data());
    }).toList();

  });
}

}