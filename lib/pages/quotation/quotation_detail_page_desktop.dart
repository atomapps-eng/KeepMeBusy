// 🔽 ANCHOR CODE: quotation_detail_page_desktop.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../quotation/create_quotation_page.dart';

class QuotationDetailPageDesktop extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isSuperAdmin;

  const QuotationDetailPageDesktop({
    super.key,
    required this.data,
    required this.isSuperAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

            final raw = snapshot.data!.data();
            if (raw == null) {
              return const Center(child: Text("Data not found"));
            }

            final newData = raw as Map<String, dynamic>;

            return Row(
              children: [

                // 🔽 LEFT PANEL (SUMMARY)
                Expanded(
                  flex: 3,
                  child: _buildLeft(newData),
                ),

                // 🔽 RIGHT PANEL (DETAIL)
                Expanded(
                  flex: 5,
                  child: _buildRight(newData),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // =========================
  // 🔽 LEFT PANEL
  // =========================
Widget _buildLeft(Map<String, dynamic> data) {

  final format = NumberFormat.currency(
    locale: 'id',
    symbol: '${data['currency']} ',
    decimalDigits: 0,
  );

  final status = data['status'] ?? 'draft';

  Color getStatusColor(String status) {
    switch (status) {
      case 'draft': return Colors.orange;
      case 'submitted': return Colors.blue;
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }

  return Container(
    margin: const EdgeInsets.all(16),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // 🔽 HEADER
        Text(
          data['quotationNumber'] ?? '-',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 10),

        // 🔽 STATUS BADGE
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: getStatusColor(status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            status.toUpperCase(),
            style: TextStyle(
              color: getStatusColor(status),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 20),

        // 🔽 PARTNER
        Text("Partner", style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Text(
          data['partnerName'] ?? '-',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),

        if (data['partnerAddress'] != null)
          Text(
            data['partnerAddress'],
            style: const TextStyle(fontSize: 12),
          ),

        const SizedBox(height: 20),

        // 🔽 CREATED / APPROVED
        Text("Created: ${data['createdByName'] ?? '-'}"),
        if (data['approvedBy'] != null)
          Text("Approved: ${data['approvedByName'] ?? '-'}"),

        const Spacer(),

        // 🔽 TOTAL
        Text(
          format.format(data['totalAmount'] ?? 0),
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),

const SizedBox(height: 20),

Builder(
  builder: (context) {
    final status = data['status'] ?? 'draft';
    final isDraft = status == 'draft';
    final isSubmitted = status == 'submitted';
    final isApproved = status == 'approved';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [

        // 🔽 SUBMIT
        if (isDraft)
          ElevatedButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser!;
              await FirebaseFirestore.instance
                  .collection('companies')
                  .doc(data['companyId'])
                  .collection('quotations')
                  .doc(data['id'])
                  .update({
                'status': 'submitted',
                'submittedBy': user.uid,
                'submittedAt': Timestamp.now(),
              });
            },
            child: const Text("Submit"),
          ),

        // 🔽 APPROVE
        if (isSubmitted && isSuperAdmin)
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser!;

              await FirebaseFirestore.instance
                  .collection('companies')
                  .doc(data['companyId'])
                  .collection('quotations')
                  .doc(data['id'])
                  .update({
                'status': 'approved',
                'approvedBy': user.uid,
                'approvedAt': Timestamp.now(),
              });
            },
            child: const Text("Approve"),
          ),

        // 🔽 REJECT
        if (isSubmitted && isSuperAdmin)
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {

              final controller = TextEditingController();

              final reason = await showDialog<String>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Reject Reason"),
                  content: TextField(controller: controller),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, controller.text);
                      },
                      child: const Text("Submit"),
                    ),
                  ],
                ),
              );

              if (reason == null || reason.isEmpty) return;

              await FirebaseFirestore.instance
                  .collection('companies')
                  .doc(data['companyId'])
                  .collection('quotations')
                  .doc(data['id'])
                  .update({
                'status': 'rejected',
                'rejectedReason': reason,
              });
            },
            child: const Text("Reject"),
          ),

        const SizedBox(height: 10),

        // 🔽 EDIT
        if (isDraft)
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateQuotationPage(
                    initialData: data,
                  ),
                ),
              );
            },
            child: const Text("Edit"),
          ),

        // 🔽 DELETE
        if (isDraft)
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('companies')
                  .doc(data['companyId'])
                  .collection('quotations')
                  .doc(data['id'])
                  .delete();

              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Delete"),
          ),
      ],
    );
  },
),
      ],
    ),
  );
}

  // =========================
  // 🔽 RIGHT PANEL
  // =========================
 Widget _buildRight(Map<String, dynamic> data) {

  final items = data['items'] as List? ?? [];

  final format = NumberFormat.currency(
    locale: 'id',
    symbol: '${data['currency']} ',
    decimalDigits: 0,
  );

  return Container(
    margin: const EdgeInsets.only(right: 16, top: 16, bottom: 16),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // 🔽 ITEMS TABLE
        const Text(
          "Items",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),

        Expanded(
          child: SingleChildScrollView(
            child: DataTable(
              columns: const [
                DataColumn(label: Text("Part")),
                DataColumn(label: Text("Qty")),
                DataColumn(label: Text("Price")),
                DataColumn(label: Text("Total")),
              ],
              rows: items.map<DataRow>((item) {
                return DataRow(
                  cells: [
                    DataCell(Text(item['partName'] ?? '-')),
                    DataCell(Text('${item['qty']}')),
                    DataCell(Text(format.format(item['priceLocal'] ?? 0))),
                    DataCell(Text(format.format(item['total'] ?? 0))),
                  ],
                );
              }).toList(),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // 🔽 SUMMARY
        const Text(
          "Summary",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),

        _row("Subtotal", format.format(data['subtotal'] ?? 0)),

        if ((data['discountPercent'] ?? 0) > 0)
          _row(
            "Discount (${data['discountPercent']}%)",
            "-${format.format(data['discountAmount'] ?? 0)}",
            color: Colors.red,
          ),

        if ((data['vatPercent'] ?? 0) > 0)
          _row(
            "VAT (${data['vatPercent']}%)",
            format.format(data['vatAmount'] ?? 0),
          ),

        const Divider(),

        _row(
          "TOTAL",
          format.format(data['totalAmount'] ?? 0),
          isBold: true,
        ),

        const SizedBox(height: 20),

        // 🔽 ADDITIONAL INFO
        const Text(
          "Additional Info",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),

        _row("Currency", data['currency'] ?? '-'),
        _row("Exchange Rate", "${data['exchangeRate'] ?? 0}"),
        _row("Valid Until", data['validUntil']?.toDate().toString() ?? '-'),
      ],
    ),
  );
}

Widget _row(String label, String value,
    {bool isBold = false, Color? color}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
      ],
    ),
  );
}

}