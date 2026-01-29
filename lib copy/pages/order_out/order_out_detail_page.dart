import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:printing/printing.dart';
import '../../utils/order_out_pdf.dart';


class OrderOutDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const OrderOutDetailPage({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final items = data['items'] as List<dynamic>? ?? [];

    final totalItem = items.length;
    final totalQty = items.fold<int>(
      0,
      (sum, item) => sum + (item['qty'] as int),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFE0B2),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF607D8B)),
        titleTextStyle: const TextStyle(
          color: Color(0xFF607D8B),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        title: const Text('Order Out Detail'),
      ),

      body: Stack(
        children: [
          // ===== BACKGROUND =====
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFE0B2),
                  Color(0xFFFFFFFF),
                ],
              ),
            ),
          ),

          // ===== CONTENT =====
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= HEADER & INFO =================
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'PO: ${data['poNumber']}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Builder(
                      builder: (_) {
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

                    Text('Client : ${data['client'] ?? '-'}'),

                    if (data['createdBy'] != null)
                      Text(
                        'Created By : ${data['createdBy']}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),

                    const SizedBox(height: 8),
                    const Divider(),

                    const Text(
                      'Items',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              // ================= ITEM LIST (SCROLLABLE) =================
              Expanded(
                child: items.isEmpty
                    ? const Center(child: Text('Tidak ada item'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        itemCount: items.length,
                        itemBuilder: (_, i) {
                          final item = items[i];
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
                        },
                      ),
              ),

              // ================= SUMMARY + ACTIONS (FIXED BOTTOM) =================
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  border: const Border(
                    top: BorderSide(color: Colors.black12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Summary',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text('Total Item : $totalItem'),
                    Text('Total Qty  : $totalQty'),

                    const SizedBox(height: 16),

                    FutureBuilder<bool>(
                      future: isAdminUser(),
                      builder: (context, snapshot) {
                        final isAdmin = snapshot.data == true;

                        return Column(
                          children: [
                            Row(
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
                                        final confirmed =
                                            await _confirmDelete(context);
                                        if (!confirmed) return;

                                        await _deleteOrderOut(
                                          context,
                                          data['id'],
                                        );
                                      },
                                      child: const Text('Delete'),
                                    ),
                                  ),
                                ],
                              ],
                            ),

                            const SizedBox(height: 10),

                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.picture_as_pdf),
                                label: const Text('Download PDF'),
                                onPressed: () async {
  final pdfData = await OrderOutPdfGenerator.generate(
    data: data,
  );

  await Printing.layoutPdf(
    onLayout: (_) => pdfData,
    name: 'OrderOut-${data['poNumber']}.pdf',
  );
},

                              ),
                            ),
                          ],
                        );
                      },
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

/// ================= DELETE ORDER (SAFE TRANSACTION) =================
Future<void> _deleteOrderOut(
  BuildContext context,
  String orderId,
) async {
  final firestore = FirebaseFirestore.instance;

  await firestore.runTransaction((tx) async {
    final orderRef = firestore.collection('order_out').doc(orderId);
    final orderSnap = await tx.get(orderRef);
    if (!orderSnap.exists) return;

    final items = orderSnap['items'] as List<dynamic>;

    final Map<String, DocumentSnapshot> partSnaps = {};
    for (final item in items) {
      final partRef =
          firestore.collection('spare_parts').doc(item['partId']);
      partSnaps[item['partId']] = await tx.get(partRef);
    }

    for (final item in items) {
      final partSnap = partSnaps[item['partId']]!;
      final currentStock =
          (partSnap['currentStock'] as num).toInt();

      tx.update(
        partSnap.reference,
        {'currentStock': currentStock + (item['qty'] as int)},
      );
    }

    tx.delete(orderRef);
  });

  if (!context.mounted) return;

  Navigator.pop(context);
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Order Out berhasil dihapus'),
      backgroundColor: Colors.redAccent,
    ),
  );
}

/// ================= CONFIRM DELETE =================
Future<bool> _confirmDelete(BuildContext context) async {
  final result = await showDialog<bool>(
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
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Hapus'),
        ),
      ],
    ),
  );

  return result == true;
}

/// ================= ADMIN CHECK =================
Future<bool> isAdminUser() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;

  final doc = await FirebaseFirestore.instance
      .collection('admin_whitelist')
      .doc(user.email!.toLowerCase())
      .get();

  return doc.exists && doc.data()?['active'] == true;
}
