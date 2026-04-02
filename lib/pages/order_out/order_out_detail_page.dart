import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/order_out_pdf.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../../core/services/company_firestore.dart';
import '../../theme/app_theme.dart';
import '../../core/services/firestore_tracker.dart';

class OrderOutDetailPage extends StatefulWidget {
  final Map<String, dynamic> data;
  final bool isWindow;
final Function(Map<String, dynamic>)? onEdit;

  const OrderOutDetailPage({
  super.key,
  required this.data,
  this.isWindow = false,
  this.onEdit,
});

  @override
  State<OrderOutDetailPage> createState() => _OrderOutDetailPageState();
}

class _OrderOutDetailPageState extends State<OrderOutDetailPage> {
  Map<String, dynamic>? freshData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final doc = await FirestoreTracker.getDoc(
        docRef: CompanyFirestore
            .collection('order_out')
            .doc(widget.data['id']),
        page: 'OrderOutDetailPage',
        collection: 'order_out',
      );

      if (!doc.exists) {
        if (mounted) Navigator.pop(context);
        return;
      }

      setState(() {
        freshData = doc.data() as Map<String, dynamic>;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final data = freshData ?? widget.data;
    final items = data['items'] as List<dynamic>? ?? [];
    final totalItem = items.length;
    final totalQty = items.fold<int>(0, (total, item) => total + (item['qty'] as int));
    final totalWeight = (data['totalWeight'] ?? 0).toDouble();
    final date = data['orderDate'] != null ? (data['orderDate'] as Timestamp).toDate() : null;

    final scaffold = Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                size: 20,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Order Out Detail',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        leading: Container(
          margin: const EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade200.withOpacity(0.5),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.receipt,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data['poNumber'] ?? '-',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Order Out',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              _infoRow('Order Date', date != null ? _formatDate(date) : '-', Icons.calendar_today),
                              const SizedBox(height: 12),
                              _infoRow('Client', data['client'] ?? '-', Icons.business),
                              const SizedBox(height: 12),
                              if (data['createdBy'] != null)
                                _infoRow('Created By', data['createdBy'], Icons.person),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Items Section
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade200.withOpacity(0.5),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.inventory,
                                      size: 16,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Items',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${items.length} items',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (items.isEmpty)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(32),
                                    child: Text('No items in this order'),
                                  ),
                                )
                              else
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: items.length,
                                  separatorBuilder: (_, __) => const Divider(height: 16),
                                  itemBuilder: (_, index) {
                                    final item = items[index];
                                    return Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            Icons.inventory_2,
                                            size: 20,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item['partCode'] ?? '-',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF0F172A),
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                item['nameEn'] ?? '-',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                              if (item['location'] != null && item['location'].toString().isNotEmpty)
                                                Text(
                                                  'Location: ${item['location']}',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey.shade500,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEFF6FF),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            'Qty: ${item['qty']}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF2563EB),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Summary Card
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade200.withOpacity(0.5),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.summarize,
                                      size: 16,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Summary',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _summaryRow('Total Items', totalItem.toString()),
                              const SizedBox(height: 8),
                              _summaryRow('Total Quantity', totalQty.toString()),
                              const SizedBox(height: 8),
                              _summaryRow('Total Weight', '${totalWeight.toStringAsFixed(2)} kg'),
                              const Divider(height: 24),
                              _summaryRow(
                                'Grand Total',
                                '${totalQty} items',
                                isBold: true,
                                isTotal: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Action Buttons
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.98),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: FutureBuilder<bool>(
                      future: isAdminUser(),
                      builder: (context, snapshot) {
                        final isAdmin = snapshot.data == true;
                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildActionButton(
                                    icon: Icons.edit,
                                    label: 'Edit',
                                    color: const Color(0xFF3B82F6),
onPressed: () async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Edit Order'),
      content: const Text('Are you sure you want to edit this order?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Edit'),
        ),
      ],
    ),
  );

  if (confirm != true) return;

await _generatePdfWithLoading(context, data);

 if (widget.onEdit != null) {
  widget.onEdit!({
    ...data,
    'id': widget.data['id'],
  });
} else {
  Navigator.pop(context, {
    ...data,
    'id': widget.data['id'],
  });
}
},
                                  ),
                                ),
                                if (isAdmin) const SizedBox(width: 12),
                                if (isAdmin)
                                  Expanded(
                                    child: _buildActionButton(
                                      icon: Icons.delete,
                                      label: 'Delete',
                                      color: const Color.fromARGB(255, 243, 24, 24),
                                      onPressed: () async {
                                        final confirm = await _confirmDelete(context);
                                        if (!confirm) return;
                                        if (!context.mounted) return;
                                        await _deleteOrderOut(context, data['id']);
                                      },
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
  onTap: () async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Download PDF'),
        content: const Text('Do you want to download this PDF file?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Download'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await _generatePdfWithLoading(context, data);
  },
  child: Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [
          Color(0xFFEF4444),
          Color(0xFFDC2626),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.red.withOpacity(0.35),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.picture_as_pdf, color: Colors.white, size: 18),
        SizedBox(width: 8),
        Text(
          "Download PDF",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    ),
  ),
),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (widget.isWindow) {
  return scaffold.body!;
}

return scaffold;
  }

  Widget _infoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 13 : 12,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              color: isTotal ? const Color(0xFF0F172A) : const Color(0xFF64748B),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? const Color(0xFF2563EB) : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool isOutlined = false,
  }) {
    if (isOutlined) {
      return OutlinedButton.icon(
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
      );
    }
    return ElevatedButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      onPressed: onPressed,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _generatePdfWithLoading(BuildContext context, Map<String, dynamic> data) async {
  double progress = 0;
  Function(void Function())? updateDialog;

  try {
    showDialog(
  context: context,
  barrierDismissible: false,
  builder: (context) {
    return StatefulBuilder(
      builder: (context, setStateDialog) {
        updateDialog = setStateDialog;

        return Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 260,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Generating PDF"),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text("${(progress * 100).toStringAsFixed(0)}%"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  },
);

/// 🔥 WAJIB: kasih waktu UI render
await Future.delayed(const Duration(milliseconds: 100));

    /// STEP 1 — start progress
    progress = 0.2;
    if (updateDialog != null) updateDialog!(() {});

    final safePoNumber = (data['poNumber'] ?? 'no-po')
        .toString()
        .replaceAll(RegExp(r'[^\w\s-]'), '-')
        .replaceAll(' ', '_');

    /// STEP 2 — generate PDF
    final pdfData = await OrderOutPdfGenerator.generate(data: data);

    progress = 0.6;
    if (updateDialog != null) updateDialog!(() {});

    /// STEP 3 — save file
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/OrderOut-$safePoNumber.pdf');

    await file.writeAsBytes(pdfData, flush: true);

    progress = 1.0;
    if (updateDialog != null) updateDialog!(() {});

    Navigator.pop(context);

    /// STEP 4 — open file
    await OpenFilex.open(file.path);

  } catch (e) {
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("PDF error: $e")),
    );
  }
}

}

Future<void> _deleteOrderOut(BuildContext context, String orderId) async {
  final firestore = FirebaseFirestore.instance;

  await firestore.runTransaction((tx) async {
    final orderRef = CompanyFirestore.collection('order_out').doc(orderId);
    final orderSnap = await tx.get(orderRef);
    if (!orderSnap.exists) return;

    final items = List<Map<String, dynamic>>.from(orderSnap['items']);
    final Map<String, int> aggregatedQty = {};

    for (final item in items) {
      aggregatedQty.update(
        item['partId'],
        (value) => value + (item['qty'] as int),
        ifAbsent: () => item['qty'] as int,
      );
    }

    for (final entry in aggregatedQty.entries) {
      final partRef = CompanyFirestore.collection('spare_parts').doc(entry.key);
      final partSnap = await tx.get(partRef);
      final currentStock = (partSnap['currentStock'] as num).toInt();
      tx.update(partRef, { 'currentStock': currentStock + entry.value });
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

Future<bool> _confirmDelete(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Hapus'),
        ),
      ],
    ),
  );
  return result == true;
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