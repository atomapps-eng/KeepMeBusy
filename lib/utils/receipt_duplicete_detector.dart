import 'package:cloud_firestore/cloud_firestore.dart';

class ReceiptDuplicateDetector {

  static Future<bool> isDuplicate({
    required CollectionReference expenseCollection,
    required double amount,
    required String currency,
    required String employeeId,
  }) async {

    final snapshot = await expenseCollection
        .where('employeeId', isEqualTo: employeeId)
        .where('currency', isEqualTo: currency)
        .where('amount', isEqualTo: amount)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

}