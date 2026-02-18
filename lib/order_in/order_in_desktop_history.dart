import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class OrderInDesktopHistory extends StatelessWidget {
  const OrderInDesktopHistory({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
  padding: const EdgeInsets.all(32),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Order In History',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 32),
      Expanded(
  child: StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('order_in')
        .orderBy('createdAt', descending: true)
        .snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }

      final docs = snapshot.data!.docs;

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
  DataColumn(label: Text('Date')),
  DataColumn(label: Text('PO Number')),
  DataColumn(label: Text('Client')),
  DataColumn(label: Text('Created By')),
  DataColumn(label: Text('Total Qty')),
  DataColumn(label: Text('Action')),
],

          rows: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;

            final date =
                (data['orderDate'] as Timestamp?)?.toDate();

            final items = data['items'] as List<dynamic>? ?? [];

            int totalQty = 0;
            for (var item in items) {
              totalQty += (item['qty'] as num).toInt();
            }

            return DataRow(
              cells: [
                DataCell(Text(
                  date == null
                      ? '-'
                      : '${date.day}/${date.month}/${date.year}',
                )),
                DataCell(Text(data['poNumber'] ?? '-')),
                DataCell(Text(data['client'] ?? '-')),
                DataCell(Text(data['createdBy'] ?? '-')),
                DataCell(Text(totalQty.toString())),

                DataCell(
  IconButton(
    icon: const Icon(Icons.visibility),
    onPressed: () {
      showDialog(
  context: context,
  builder: (_) {
    final items = data['items'] as List<dynamic>? ?? [];

    return AlertDialog(
      title: Text('PO: ${data['poNumber']}'),
      content: SizedBox(
  width: 500,
  height: 400, // batasi tinggi
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Client: ${data['client'] ?? '-'}'),
      const SizedBox(height: 16),
      const Text(
        'Items',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      Expanded(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '${item['partCode']}  |  Qty: ${item['qty']}',
                ),
              );
            }).toList(),
          ),
        ),
      ),
    ],
  ),
),

      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  },
);

    },
  ),
),

              ],
            );
          }).toList(),
        ),
      );
    },
  ),
),
    ],
  ),
),

    );
  }
}
