import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderOutDesktopHistory extends StatelessWidget {
  final String searchKeyword;
  final DateTime? filterDate;
  final void Function(BuildContext, Map<String, dynamic>) onTap;

  const OrderOutDesktopHistory({
    super.key, // 🔥 TAMBAHKAN INI
    required this.searchKeyword,
    required this.filterDate,
    required this.onTap,
  });


  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('order_out')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (_, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final keyword = searchKeyword.toLowerCase();
          if (keyword.isNotEmpty &&
              !data['poNumber']
                  .toString()
                  .toLowerCase()
                  .contains(keyword) &&
              !data['client']
                  .toString()
                  .toLowerCase()
                  .contains(keyword)) {
            return false;
          }

          if (filterDate != null) {
            final date =
                (data['orderDate'] as Timestamp).toDate();
            if (date.year != filterDate!.year ||
                date.month != filterDate!.month ||
                date.day != filterDate!.day) {
              return false;
            }
          }
          return true;
        }).toList();

        if (docs.isEmpty) {
          return const Center(child: Text('Belum ada Order'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (_, i) {
  final data = docs[i].data() as Map<String, dynamic>;
  final orderId = docs[i].id;

  return InkWell(
  onTap: () => onTap(
    context,
    {
      ...data,
      'id': orderId,
    },
  ),
  child: _OrderHistoryCard(
    data: {
      ...data,
      'id': orderId,
    },
    // ⛔ JANGAN kirim isFullscreen = true
    // ⛔ JANGAN kirim onEdit
    // ⛔ JANGAN kirim onDelete
  ),
);

},



        );
      },
    );
  }
}

class _OrderHistoryCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _OrderHistoryCard({
  required this.data,
});


  @override
Widget build(BuildContext context) {
  final date =
      (data['orderDate'] as Timestamp?)?.toDate();

  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.25),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.35),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PO: ${data['poNumber']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('Client: ${data['client']}'),

                  if (data['createdBy'] != null)
  Text(
    'Created By: ${data['createdBy']}',
    style: const TextStyle(
      fontSize: 12,
      color: Colors.black54,
    ),
  ),


                  if (date != null)
                    Text(
                      '${date.day}/${date.month}/${date.year}',
                      style: const TextStyle(fontSize: 12),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

}