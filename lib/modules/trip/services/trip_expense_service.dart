import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip_expense_model.dart';
import 'trip_service.dart';

class TripExpenseService {

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TripService tripService = TripService();
  final firestore = FirebaseFirestore.instance;

  Future<void> createExpense(
    String tripId,
    TripExpense expense,
  ) async {

    final companyId = await tripService.getCompanyId();

    await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('trips')
        .doc(tripId)
        .collection('expenses')
        .add(expense.toMap());
  }

  Stream<List<TripExpense>> streamExpenses(String tripId) async* {

  final companyId = await tripService.getCompanyId();

  yield* _firestore
      .collection('companies')
      .doc(companyId)
      .collection('trips')
      .doc(tripId)
      .collection('expenses')
      .orderBy('date', descending: true)
      .snapshots()
      .map((snapshot) {

    return snapshot.docs.map((doc) {
      return TripExpense.fromMap(doc.id, doc.data());
    }).toList();

  });
}

Future<void> deleteExpense(String tripId, String expenseId) async {

  await FirebaseFirestore.instance
      .collection('companies')
      .doc('atomIndonesia')
      .collection('trips')
      .doc(tripId)
      .collection('expenses')
      .doc(expenseId)
      .delete();

}

Future<void> updateExpense(
  String tripId,
  String expenseId,
  TripExpense expense,
) async {

  final companyId = await TripService().getCompanyId();

  await FirebaseFirestore.instance
      .collection('companies')
      .doc(companyId)
      .collection('trips')
      .doc(tripId)
      .collection('expenses')
      .doc(expenseId)
      .update(expense.toMap());

}

Future<List<TripExpense>> getExpenses(String tripId) async {

  final companyId = await tripService.getCompanyId();

  final snapshot = await _firestore
      .collection('companies')
      .doc(companyId)
      .collection('trips')
      .doc(tripId)
      .collection('expenses')
      .orderBy('date', descending: true)
      .get();

  return snapshot.docs.map((doc) {
    return TripExpense.fromMap(doc.id, doc.data());
  }).toList();

}

}