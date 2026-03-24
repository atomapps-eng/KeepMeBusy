import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_filex/open_filex.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../quotation/create_quotation_page.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import 'quotation_detail_page_desktop.dart';

class QuotationDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isSuperAdmin;

  const QuotationDetailPage({
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
    final isDesktop = MediaQuery.of(context).size.width > 900;

if (isDesktop) {
  return QuotationDetailPageDesktop(
    data: data,
    isSuperAdmin: isSuperAdmin,
  );
}
    return Scaffold(
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
                Icons.request_quote,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              data['quotationNumber'] ?? 'Quotation Detail',
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
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
              onPressed: data['status'] == 'approved' ? () => _generatePdf(context) : null,
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
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

              final rawData = snapshot.data!.data();
              if (rawData == null) {
                Future.microtask(() => Navigator.pop(context));
                return const SizedBox();
              }

              final newData = rawData as Map<String, dynamic>;
              final format = NumberFormat.currency(
                locale: 'id',
                symbol: '${newData['currency']} ',
                decimalDigits: 0,
              );

              final validUntil = newData['validUntil'];
              bool isExpired = false;
              if (validUntil != null) {
                final expiryDate = (validUntil as Timestamp).toDate();
                isExpired = DateTime.now().isAfter(expiryDate);
              }

              final status = newData['status'] ?? 'draft';
              final isDraft = status == 'draft';
              final statusColor = _getStatusColor(status);
              final items = newData['items'] as List? ?? [];

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: statusColor.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _getStatusIcon(status),
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                                if (isExpired) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'EXPIRED',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Quotation Info Card
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
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              newData['partnerName'] ?? 'Unknown Partner',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF0F172A),
                                              ),
                                            ),
                                            if (newData['partnerAddress'] != null) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                newData['partnerAddress'],
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF64748B),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 24),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _infoRow(
                                          'Currency',
                                          newData['currency'] ?? '-',
                                          Icons.attach_money,
                                        ),
                                      ),
                                      Expanded(
                                        child: _infoRow(
                                          'Exchange Rate',
                                          '1 EUR = ${NumberFormat('#,###').format(newData['exchangeRate'] ?? 0)}',
                                          Icons.currency_exchange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Items Section
                          if (items.isNotEmpty) ...[
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
                                    const SizedBox(height: 12),
                                    ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: items.length,
                                      separatorBuilder: (_, __) => const Divider(height: 12),
                                      itemBuilder: (context, index) {
                                        final item = items[index];
                                        return Row(
                                          children: [
                                            Expanded(
                                              flex: 3,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item['partName'] ?? '-',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w500,
                                                      color: Color(0xFF0F172A),
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  Text(
                                                    'Qty: ${item['qty']}',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Color(0xFF64748B),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                format.format(item['total'] ?? 0),
                                                textAlign: TextAlign.end,
                                                style: const TextStyle(
                                                  fontSize: 14,
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
                          ],

                          // Pricing Summary Card
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
                                    format.format(newData['subtotal'] ?? 0),
                                  ),
                                  if ((newData['discountPercent'] ?? 0) > 0)
                                    _summaryRow(
                                      'Discount (${newData['discountPercent']}%)',
                                      '-${format.format(newData['discountAmount'] ?? 0)}',
                                      isNegative: true,
                                    ),
                                  if ((newData['vatPercent'] ?? 0) > 0)
                                    _summaryRow(
                                      'VAT (${newData['vatPercent']}%)',
                                      '+${format.format(newData['vatAmount'] ?? 0)}',
                                    ),
                                  const Divider(height: 20),
                                  _summaryRow(
                                    'Total',
                                    format.format(newData['totalAmount'] ?? 0),
                                    isBold: true,
                                    isTotal: true,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Additional Info Card
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
                                          Icons.info_outline,
                                          size: 16,
                                          color: Color(0xFF2563EB),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Additional Information',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  if (newData['validUntil'] != null)
                                    _infoRow(
                                      'Valid Until',
                                      _formatDate(newData['validUntil']),
                                      Icons.calendar_today,
                                    ),
                                  _infoRow(
                                    'Created By',
                                    newData['createdByName'] ?? '-',
                                    Icons.person,
                                  ),
                                  if (newData['createdAt'] != null)
                                    _infoRow(
                                      'Created At',
                                      _formatDate(newData['createdAt']),
                                      Icons.access_time,
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
                  if (isSuperAdmin && (isDraft && !isExpired))
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
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.edit, size: 18),
                                  label: const Text('Edit'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3B82F6),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        title: const Text('Edit Quotation'),
                                        content: const Text('Do you want to edit this quotation?'),
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

                                    if (confirm == true) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => CreateQuotationPage(
                                            initialData: data,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.delete, size: 18),
                                  label: const Text('Delete'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFEF4444),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        title: const Text('Delete Quotation'),
                                        content: const Text(
                                          'Are you sure you want to delete this quotation?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                            ),
                                            onPressed: () => Navigator.pop(context, true),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      await FirebaseFirestore.instance
                                          .collection('companies')
                                          .doc(data['companyId'])
                                          .collection('quotations')
                                          .doc(data['id'])
                                          .delete();

                                      if (context.mounted) Navigator.pop(context);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, IconData icon) {
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
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0F172A),
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

  // PDF methods tetap sama seperti sebelumnya
  Future<void> _generatePdf(BuildContext context) async {
    final pdf = pw.Document();
    final items = data['items'] as List? ?? [];

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(16),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "QUOTATION",
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text("Number: ${data['quotationNumber']}"),
                pw.Text("Status: ${data['status']}"),
                pw.SizedBox(height: 20),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text("Part"),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text("Qty"),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text("Price"),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text("Total"),
                        ),
                      ],
                    ),
                    ...items.map((item) {
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(item['partName'] ?? ''),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text((item['qty'] ?? 0).toString()),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text((item['priceLocal'] ?? 0).toString()),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text((item['total'] ?? 0).toString()),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    "TOTAL: ${data['currency']} ${data['totalAmount']}",
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/${data['quotationNumber']}.pdf");
    await file.writeAsBytes(await pdf.save());
    await OpenFilex.open(file.path);
  }
}