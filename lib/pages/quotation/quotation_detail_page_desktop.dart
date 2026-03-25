// 🔽 ANCHOR CODE: quotation_detail_page_desktop.dart

import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../quotation/create_quotation_page.dart';
import '../quotation/create_quotation_page_desktop.dart';

class QuotationDetailPageDesktop extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isSuperAdmin;

  const QuotationDetailPageDesktop({
    super.key,
    required this.data,
    required this.isSuperAdmin,
  });

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '-';
    return DateFormat('dd MMM yyyy').format(timestamp.toDate());
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'draft':
        return const Color(0xFFF59E0B);
      case 'submitted':
        return const Color(0xFF3B82F6);
      case 'approved':
        return const Color(0xFF10B981);
      case 'rejected':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _getStatusIcon(String status) {
    switch (status) {
      case 'draft':
        return '📝';
      case 'submitted':
        return '📤';
      case 'approved':
        return '✅';
      case 'rejected':
        return '❌';
      default:
        return '📄';
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = data['status'] ?? 'draft';
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          children: [
            const SizedBox(width: 12),
            Text(
  (status == 'draft' || status == 'submitted')
      ? ''
      : (data['quotationNumber'] ?? 'Quotation Detail'),
              style: const TextStyle(
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
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('companies')
              .doc(data['companyId'])
              .collection('quotations')
              .doc(data['id'])
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

final doc = snapshot.data!;
final raw = doc.data();

if (raw == null) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (context.mounted) Navigator.pop(context);
  });
  return const SizedBox();
}

final newData = raw as Map<String, dynamic>;
final docId = doc.id;

            if (raw == null) {
  Future.microtask(() => Navigator.pop(context));
  return const SizedBox();
}

            return Row(
              children: [
                // LEFT PANEL - Summary
                Expanded(
                  flex: 3,
                  child: _buildLeftPanel(newData, context, docId),
                ),
                // RIGHT PANEL - Detail
                Expanded(
                  flex: 5,
                  child: _buildRightPanel(newData),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // =========================
  // LEFT PANEL - Modern
  // =========================
  Widget _buildLeftPanel(Map<String, dynamic> data, BuildContext context, String docId) {
    final format = NumberFormat.currency(
      locale: 'id',
      symbol: '${data['currency']} ',
      decimalDigits: 0,
    );

    final status = data['status'] ?? 'draft';
    final statusColor = _getStatusColor(status);
    final isDraft = status == 'draft';
    final isSubmitted = status == 'submitted';
    final validUntil = data['validUntil'];
    bool isExpired = false;

    if (validUntil != null) {
      final expiryDate = (validUntil as Timestamp).toDate();
      isExpired = DateTime.now().isAfter(expiryDate);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [statusColor, statusColor.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusIcon(status),
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['quotationNumber'] ?? '-',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (isExpired) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'EXPIRED',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Partner Info Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(16),
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
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.business,
                          size: 18,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Partner Information',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    data['partnerName'] ?? '-',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data['partnerAddress'] ?? '-',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Amount Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(16),
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
                  const Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    format.format(data['totalAmount'] ?? 0),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  const Divider(height: 24),
                  _infoRow(
                    'Currency',
                    data['currency'] ?? '-',
                    Icons.attach_money,
                  ),
                  _infoRow(
                    'Exchange Rate',
                    '1 EUR = ${NumberFormat('#,###').format(data['exchangeRate'] ?? 0)}',
                    Icons.currency_exchange,
                  ),
                  if (data['validUntil'] != null)
                    _infoRow(
                      'Valid Until',
                      _formatDate(data['validUntil']),
                      Icons.calendar_today,
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Details Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(16),
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
                  const Text(
                    'Details',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _infoRow(
                    'Created By',
                    data['createdByName'] ?? '-',
                    Icons.person,
                  ),
                  _infoRow(
                    'Created At',
                    data['createdAt'] != null
                        ? _formatDate(data['createdAt'])
                        : '-',
                    Icons.calendar_today,
                  ),
                  if (data['approvedByName'] != null) ...[
                    const SizedBox(height: 8),
                    _infoRow(
                      'Approved By',
                      data['approvedByName'],
                      Icons.verified,
                      color: Colors.green,
                    ),
                  ],
                  if (data['submittedByName'] != null) ...[
                    const SizedBox(height: 8),
                    _infoRow(
                      'Submitted By',
                      data['submittedByName'],
                      Icons.send,
                    ),
                  ],
                  if (data['rejectedReason'] != null) ...[
                    const SizedBox(height: 8),
                    _infoRow(
                      'Rejection Reason',
                      data['rejectedReason'],
                      Icons.info_outline,
                      color: Colors.red,
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Action Buttons
          if ((isDraft && !isExpired) || (isSubmitted && isSuperAdmin))
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200.withOpacity(0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (isDraft && !isExpired) ...[
                      _buildActionButton(
                        icon: Icons.send,
                        label: 'Submit',
                        color: Colors.blue,
                        onPressed: () async {
                          final user = FirebaseAuth.instance.currentUser!;
                          await FirebaseFirestore.instance
                              .collection('companies')
                              .doc(data['companyId'])
                              .collection('quotations')
                              .doc(docId)
                              .update({
                            'status': 'submitted',
                            'submittedBy': user.uid,
                            'submittedByName': user.displayName ?? user.email,
                            'submittedAt': Timestamp.now(),
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildActionButton(
  icon: Icons.edit,
  label: 'Edit',
  color: Colors.orange,
  onPressed: () async {
    final safeData = Map<String, dynamic>.from(data);
    safeData['id'] = docId;

    // 🔽 pastikan semua string tidak null
    safeData['quotationNumber'] = safeData['quotationNumber'] ?? '';
    safeData['partnerName'] = safeData['partnerName'] ?? '';
    safeData['partnerAddress'] = safeData['partnerAddress'] ?? '';
    safeData['currency'] = safeData['currency'] ?? 'IDR';

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateQuotationPageDesktop(
          initialData: safeData,
        ),
      ),
    );

    if (result == true) {
      if (context.mounted) {
        Navigator.pop(context, true);
      }
    }
  },
),
                      const SizedBox(height: 8),
                      _buildActionButton(
                        icon: Icons.delete,
                        label: 'Delete',
                        color: Colors.red,
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              title: const Text("Delete Quotation"),
                              content: const Text(
                                "Are you sure you want to delete this quotation?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text("Cancel"),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text("Delete"),
                                ),
                              ],
                            ),
                          );

                         if (confirm == true) {
  await FirebaseFirestore.instance
      .collection('companies')
      .doc(data['companyId'])
      .collection('quotations')
     .doc(docId)
      .delete();

  if (context.mounted) {
    Navigator.pop(context, true); // ← kirim signal ke list
  }
}
                        },
                      ),
                    ],
                    if (isSubmitted && isSuperAdmin) ...[
                      _buildActionButton(
                        icon: Icons.check,
                        label: 'Approve',
                        color: Colors.green,
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              title: const Text("Approve Quotation"),
                              content: const Text(
                                "Are you sure you want to approve this quotation?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text("Cancel"),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text("Approve"),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            final user = FirebaseAuth.instance.currentUser!;
                            await FirebaseFirestore.instance
                                .collection('companies')
                                .doc(data['companyId'])
                                .collection('quotations')
                                .doc(data['id'])
                                .update({
                              'status': 'approved',
                              'approvedBy': user.uid,
                              'approvedByName': user.displayName ?? user.email,
                              'approvedAt': Timestamp.now(),
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildActionButton(
                        icon: Icons.close,
                        label: 'Reject',
                        color: Colors.red,
                        onPressed: () async {
                          final controller = TextEditingController();

                          final reason = await showDialog<String>(
                            context: context,
                            builder: (_) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              title: const Text("Reject Quotation"),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    "Please provide a reason for rejection:",
                                  ),
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: controller,
                                    maxLines: 3,
                                    decoration: const InputDecoration(
                                      hintText: "Enter rejection reason...",
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Cancel"),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    if (controller.text.trim().isEmpty) return;
                                    Navigator.pop(context, controller.text.trim());
                                  },
                                  child: const Text("Continue"),
                                ),
                              ],
                            ),
                          );

                          if (reason == null) return;

                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              title: const Text("Confirm Rejection"),
                              content: Text(
                                "Are you sure you want to reject this quotation?\n\nReason:\n$reason",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text("Back"),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text("Reject"),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            final user = FirebaseAuth.instance.currentUser!;
                            await FirebaseFirestore.instance
                                .collection('companies')
                                .doc(data['companyId'])
                                .collection('quotations')
                                .doc(data['id'])
                                .update({
                              'status': 'rejected',
                              'rejectedBy': user.uid,
                              'rejectedByName': user.displayName ?? user.email,
                              'rejectedAt': Timestamp.now(),
                              'rejectedReason': reason,
                            });
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // =========================
  // RIGHT PANEL - Modern
  // =========================
  Widget _buildRightPanel(Map<String, dynamic> data) {
    final items = data['items'] as List? ?? [];
    final format = NumberFormat.currency(
      locale: 'id',
      symbol: '${data['currency']} ',
      decimalDigits: 0,
    );

    return Container(
      margin: const EdgeInsets.all(24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.inventory,
                    size: 18,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Items',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${items.length} items',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Items Table
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(
                  const Color(0xFFF8FAFC),
                ),
                columnSpacing: 24,
                columns: const [
                  DataColumn(
                    label: Text(
                      "Part Name",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "Qty",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "Price",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "Total",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
                rows: items.map<DataRow>((item) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Flexible(
                               child: Text(
                                item['partName'] ?? '-',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              ),
                              if (item['partCode'] != null)
                                Text(
                                  item['partCode'],
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          '${item['qty']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          format.format(item['priceLocal'] ?? 0),
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          format.format(item['total'] ?? 0),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),

          const Divider(height: 1),

          // Summary Section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Summary',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _summaryRow(
                  'Subtotal',
                  format.format(data['subtotal'] ?? 0),
                ),
                if ((data['discountPercent'] ?? 0) > 0)
                  _summaryRow(
                    'Discount (${data['discountPercent']}%)',
                    '-${format.format(data['discountAmount'] ?? 0)}',
                    isNegative: true,
                  ),
                if ((data['vatPercent'] ?? 0) > 0)
                  _summaryRow(
                    'VAT (${data['vatPercent']}%)',
                    '+${format.format(data['vatAmount'] ?? 0)}',
                  ),
                const Divider(height: 20),
                _summaryRow(
                  'TOTAL',
                  format.format(data['totalAmount'] ?? 0),
                  isBold: true,
                  isTotal: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, IconData icon, {Color color = const Color(0xFF64748B)}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
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
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isNegative = false, bool isBold = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 14 : 12,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              color: isNegative ? Colors.red : const Color(0xFF64748B),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? const Color(0xFF2563EB) : (isNegative ? Colors.red : const Color(0xFF0F172A)),
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
    VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        onPressed: onPressed,
      ),
    );
  }
}