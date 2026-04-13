import 'package:flutter/material.dart';
import 'dart:ui';
import '../models/trip_transfer_model.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../pages/common/app_background_wrapper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/trip_transfer_service.dart';
import 'add_transfer_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TransferDetailPage extends StatelessWidget {
  final TripTransfer transfer;
  final String tripId;

  const TransferDetailPage({
    super.key,
    required this.transfer,
    required this.tripId,
  });

  Future<void> downloadFile(String url) async {
    final uri = Uri.parse(url);

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isPdf = transfer.receiptUrl.contains(".pdf");

    /// 🔥 ANCHOR CODE
    /// ini penting → ambil data dari transfer.transfers[0]
    final data = transfer.transfers.first;

    final amount = data['amount'] ?? 0;
    final currency = data['currency'] ?? '';
    final employeeId = data['employeeId'] ?? '';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        actions: [
  /// EDIT
  IconButton(
    icon: const Icon(Icons.edit),
    onPressed: () async {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Edit Transfer"),
          content: const Text("Do you want to edit this transfer?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Edit"),
            ),
          ],
        ),
      );

      if (confirm == true) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddTransferPage(
              tripId: tripId,
              transferId: transfer.id,
            ),
          ),
        );
      }
    },
  ),

  /// DELETE
  IconButton(
    icon: const Icon(Icons.delete, color: Colors.red),
    onPressed: () async {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Delete Transfer"),
          content: const Text(
              "Are you sure you want to delete this transfer?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete"),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await TripTransferService().deleteTransfer(tripId, transfer.id);

        if (context.mounted) {
          Navigator.pop(context);
        }
      }
    },
  ),
],
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.withValues(alpha: 0.2),
                    Colors.green.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.arrow_downward,
                color: Colors.green,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Transfer Detail',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.2),
                Colors.white.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: AppBackgroundWrapper(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              /// ======================
              /// INFO CARD
              /// ======================
              _glass(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.withValues(alpha: 0.2),
                                Colors.green.withValues(alpha: 0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.info_outline,
                            color: Colors.green,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Transfer Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    /// Amount
                    _buildInfoTile(
                      icon: Icons.attach_money,
                      label: 'Amount',
                      value: '$currency ${formatCurrency(amount)}',
                      color: Colors.green,
                    ),

                    /// Date
                    _buildInfoTile(
                      icon: Icons.calendar_today,
                      label: 'Date',
                      value: _formatDate(transfer.date),
                      color: Colors.blue,
                    ),

                    /// Employee
                    FutureBuilder<String>(
  future: _getTripCreatorName(),
  builder: (context, snapshot) {
    final name = snapshot.data ?? 'Loading...';

    return _buildInfoTile(
      icon: Icons.person,
      label: 'Employee',
      value: name,
      color: Colors.purple,
    );
  },
),
                    const Divider(height: 24),

                    /// Note
                    const Text(
                      'Note',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        transfer.note.isEmpty
                            ? 'No note'
                            : transfer.note,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              /// ======================
              /// RECEIPT CARD
              /// ======================
              if (transfer.receiptUrl.isNotEmpty)
                _glass(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.orange.withValues(alpha: 0.2),
                                  Colors.orange.withValues(alpha: 0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.receipt,
                              color: Colors.orange,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Receipt',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Center(
                        child: Container(
                          constraints: const BoxConstraints(maxHeight: 300),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            children: [
                              if (!isPdf)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: GestureDetector(
  onTap: () {
    _openImagePreview(context, transfer.receiptUrl);
  },
  child: ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Image.network(
      transfer.receiptUrl,
      height: 200,
      fit: BoxFit.contain,
    ),
  ),
),
                                ),

                              if (isPdf)
                                Container(
                                  height: 150,
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.picture_as_pdf,
                                      size: 50,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 12),

                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                                icon: const Icon(Icons.download),
                                label: const Text('Download Receipt'),
                                onPressed: () {
                                  downloadFile(transfer.receiptUrl);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openImagePreview(BuildContext context, String imageUrl) {
  showDialog(
    context: context,
    barrierColor: Colors.black,
    builder: (_) {
      return GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: InteractiveViewer(
              child: Image.network(imageUrl),
            ),
          ),
        ),
      );
    },
  );
}

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<String> _getTripCreatorName() async {
  try {
    final tripDoc = await FirebaseFirestore.instance
        .collection('companies')
        .doc(await _getCompanyId())
        .collection('trips')
        .doc(tripId)
        .get();

    final createdBy = tripDoc.data()?['createdBy'];

    if (createdBy == null) return '-';

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(createdBy)
        .get();

    return userDoc.data()?['username'] ?? '-';
  } catch (e) {
    return '-';
  }
}

Future<String> _getCompanyId() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) return '';

  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();

  final companyIds = List<String>.from(doc.data()?['companyIds'] ?? []);

  return companyIds.isNotEmpty ? companyIds.first : '';
}

  String formatCurrency(double value) {
    final number = value.toInt().toString();

    return number.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
  }

  Future<String> _getUserName(String uid) async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (doc.exists) {
      return doc.data()?['username'] ?? uid;
    }

    return uid;
  } catch (e) {
    return uid;
  }
}

}

/// GLASS HELPER (copy dari expense)
Widget _glass(Widget child) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
        ),
        child: child,
      ),
    ),
  );
}