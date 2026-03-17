import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/order_out_pdf.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../../core/services/company_firestore.dart';
import '../../theme/app_theme.dart';



class OrderOutDetailPage extends StatefulWidget {
  final Map<String, dynamic> data;

  const OrderOutDetailPage({
    super.key,
    required this.data,
  });

  @override
  State<OrderOutDetailPage> createState() => _OrderOutDetailPageState();
}

class _OrderOutDetailPageState extends State<OrderOutDetailPage> {
  
  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final items = data['items'] as List<dynamic>? ?? [];

    final totalItem = items.length;
    final totalQty = items.fold<int>(
      0,
      (total, item) => total + (item['qty'] as int),
    );
    final totalWeight =
    (data['totalWeight'] ?? 0).toDouble();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
  backgroundColor: Colors.transparent,
  elevation: 0,
  title: const Text('Order In Detail'),
),

      body: Stack(
        children: [
          // ===== BACKGROUND =====
          Container(
            decoration: BoxDecoration(
  gradient: AppTheme.backgroundGradient,
),
          ),

          // ===== CONTENT =====
          Padding(
  padding: EdgeInsets.only(
    top: MediaQuery.of(context).padding.top + kToolbarHeight,
  ),
  child: Column(
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
                    _summaryRow('Total Item', totalItem.toString()),
_summaryRow('Total Qty', totalQty.toString()),
_summaryRow(
  'Total Weight',
  '${totalWeight.toStringAsFixed(2)} kg',
),

                    const SizedBox(height: 16),

                    FutureBuilder<bool>(
                      future: isAdminUser(),
                      builder: (context, snapshot) {
                        final isAdmin = snapshot.data == true;

                        return Column(
  children: [

    // ================= EDIT + DELETE (ROW) =================
    Row(
      children: [
        // ===== EDIT BUTTON =====
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pop(context, data);
            },
            label: const Text('Edit'),
          ),
        ),

        // Spacing hanya jika admin
        if (isAdmin) const SizedBox(width: 12),

        // ===== DELETE BUTTON (ADMIN ONLY) =====
        if (isAdmin)
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.delete),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              label: const Text('Delete'),
              onPressed: () async {
                final confirm = await _confirmDelete(context);
                if (!confirm) return;
                  if (!context.mounted) return;

                await _deleteOrderOut(
                  context,
                  data['id'], // pastikan id ada
                );
              },
            ),
          ),
      ],
    ),

    const SizedBox(height: 16),

    // ================= PDF BUTTON =================
    SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text('Download PDF'),
        onPressed: () async {
          final pdfData = await OrderOutPdfGenerator.generate(
            data: data,
          );

          final dir = await getApplicationDocumentsDirectory();
          final file = File(
            '${dir.path}/OrderOut-${data['poNumber']}.pdf',
          );

          await file.writeAsBytes(pdfData, flush: true);
          await OpenFilex.open(file.path);
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
          ),
        ],
      ),
    );
  }
}

Widget _summaryRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Row(
      children: [

        SizedBox(
          width: 100,
          child: Text(label),
        ),

        const Text(':'),

        const SizedBox(width: 6),

        Text(value),
      ],
    ),
  );
}

/// ================= DELETE ORDER (SAFE TRANSACTION) =================
Future<void> _deleteOrderOut(
  BuildContext context,
  String orderId,
) async {
  final firestore = FirebaseFirestore.instance;

  await firestore.runTransaction((tx) async {
    final orderRef =
       CompanyFirestore.collection('order_out').doc(orderId);

    final orderSnap = await tx.get(orderRef);
    if (!orderSnap.exists) return;

    final items =
        List<Map<String, dynamic>>.from(orderSnap['items']);

    // ===============================
    // 1️⃣ AGGREGATE QTY PER PART
    // ===============================
    final Map<String, int> aggregatedQty = {};

    for (final item in items) {
      aggregatedQty.update(
        item['partId'],
        (value) => value + (item['qty'] as int),
        ifAbsent: () => item['qty'] as int,
      );
    }

    // ===============================
    // 2️⃣ READ + UPDATE STOCK
    // ===============================
    for (final entry in aggregatedQty.entries) {
      final partRef =
          CompanyFirestore.collection('spare_parts').doc(entry.key);

      final partSnap = await tx.get(partRef);

      final currentStock =
          (partSnap['currentStock'] as num).toInt();

      tx.update(
        partRef,
        {'currentStock': currentStock + entry.value},
      );
    }

    // ===============================
    // 3️⃣ DELETE ORDER
    // ===============================
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
