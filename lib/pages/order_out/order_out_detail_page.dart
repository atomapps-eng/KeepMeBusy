import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';




class OrderOutDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const OrderOutDetailPage({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Out Detail'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER CARD
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
  'PO: ${data['poNumber']}',
  style: Theme.of(context).textTheme.titleLarge,
),

              ),
            ),

            const SizedBox(height: 16),

            // INFO SECTION
            Builder(
  builder: (context) {
    final ts = data['orderDate'];
    if (ts == null) return const Text('Date : -');

    final date = (ts as Timestamp).toDate();
    return Text(
      'Date : ${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}',
    );
  },
),

            const Text('Location : -'),
            Text('Client : ${data['client'] ?? '-'}'),
            const Text('Status : -'),

            const SizedBox(height: 16),
            const Divider(),

            // ITEM LIST PLACEHOLDER
            // ITEMS
const Text(
  'Items',
  style: TextStyle(fontWeight: FontWeight.bold),
),
const SizedBox(height: 8),

Builder(
  builder: (context) {
    final items = data['items'] as List<dynamic>?;

    if (items == null || items.isEmpty) {
      return const Text('Tidak ada item');
    }

    return Column(
      children: items.map((item) {
        return ListTile(
          title: Text(item['partCode'] ?? '-'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item['nameEn'] ?? '-'),
              Text(
                'Location: ${item['location'] ?? '-'}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          trailing: Text('Qty: ${item['qty']}'),
        );
      }).toList(),
    );
  },
),

const SizedBox(height: 8),

Builder(
  builder: (context) {
    final items = data['items'] as List<dynamic>? ?? [];

    final totalItem = items.length;
    final totalQty = items.fold<int>(
      0,
      (sum, item) => sum + (item['qty'] as int),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Total Item : $totalItem'),
        Text('Total Qty  : $totalQty'),
      ],
    );
  },
),

            const SizedBox(height: 24),

            // ACTION BUTTON PLACEHOLDER
           FutureBuilder<bool>(
  future: isAdminUser(),
  builder: (context, snapshot) {
    final isAdmin = snapshot.data == true;

    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context, data);
            },
            child: const Text('Edit'),
          ),
        ),

        if (isAdmin) ...[
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Hapus Order Out'),
      content: const Text(
        'Order ini akan dihapus dan stock akan dikembalikan.\nLanjutkan?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Hapus'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  final firestore = FirebaseFirestore.instance;
  final orderId = data['id'];

  try {
    await firestore.runTransaction((tx) async {
  final orderRef = firestore.collection('order_out').doc(orderId);

  // =====================
  // 1. READ SEMUA DATA
  // =====================
  final orderSnap = await tx.get(orderRef);
  if (!orderSnap.exists) return;

  final items = orderSnap['items'] as List<dynamic>;

  final Map<String, int> stockMap = {};

  // baca semua stock part
  for (final item in items) {
    final partRef =
        firestore.collection('spare_parts').doc(item['partId']);
    final partSnap = await tx.get(partRef);

    stockMap[item['partId']] =
        (partSnap['currentStock'] as num).toInt();
  }

  // =====================
  // 2. WRITE (SETELAH SEMUA READ)
  // =====================
  for (final item in items) {
    final partRef =
        firestore.collection('spare_parts').doc(item['partId']);

    tx.update(partRef, {
      'currentStock':
          stockMap[item['partId']]! + (item['qty'] as int),
    });
  }

  tx.delete(orderRef);
});


    if (!context.mounted) return;

    Navigator.pop(context); // keluar dari detail
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order Out berhasil dihapus'),
        backgroundColor: Colors.redAccent,
        duration: Duration(seconds: 2),
      ),
    );
  } catch (e) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(e.toString()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
},

              child: const Text('Delete'),
            ),
          ),
        ],
      ],
    );
  },
),

          ],
        ),
      ),
    );
  }
}
Future<bool> isAdminUser() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;

  final doc = await FirebaseFirestore.instance
      .collection('admin_whitelist')
      .doc(user.email!.toLowerCase())
      .get();

  return doc.exists && doc.data()?['active'] == true;
}
