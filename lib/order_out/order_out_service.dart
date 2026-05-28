import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/services/company_firestore.dart';

class OrderOutService {
  static final _firestore = FirebaseFirestore.instance;

  static Future<void> deleteOrder(String orderId) async {
    final orderRef = CompanyFirestore.collection('order_out').doc(orderId);

    await _firestore.runTransaction((transaction) async {
      final orderSnap = await transaction.get(orderRef);

      if (!orderSnap.exists) {
        throw Exception("Order not found");
      }

      final orderData = orderSnap.data() as Map<String, dynamic>;

      final items = List<Map<String, dynamic>>.from(orderData['items'] ?? []);

      // 🔁 Rollback stock
      for (var item in items) {
        final sparePartRef = _firestore
            .collection('companies')
            .doc(orderRef.parent.parent!.id)
            .collection('spare_parts')
            .doc(item['sparePartId']);

        final spareSnap = await transaction.get(sparePartRef);

        if (!spareSnap.exists) continue;

        final currentStock = spareSnap['currentStock'] ?? 0;
        final qty = item['qty'] ?? 0;

        transaction.update(sparePartRef, {'currentStock': currentStock + qty});
      }

      // 🗑 Delete order
      transaction.delete(orderRef);
    });
  }
}
