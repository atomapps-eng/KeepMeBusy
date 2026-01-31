import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../pages/common/app_background_wrapper.dart';
import '../models/overnight_entry.dart';
import 'add_overnight_page.dart';

class OvernightItemDetailPage extends StatelessWidget {
  final String employeeId;
  final String docId;

Future<void> _deleteOvernight(BuildContext context) async {
  final navigator = Navigator.of(context);

  final confirm = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete Overnight'),
      content: const Text(
        'Are you sure you want to delete this overnight record?',
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(dialogContext).pop(true),
          style:
              TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (confirm != true) return;

  // ✅ STEP 1: TUTUP PAGE DETAIL DULU
  navigator.pop();

  // ✅ STEP 2: HAPUS DATA (SETELAH PAGE TERTUTUP)
  await FirebaseFirestore.instance
      .collection('attendance')
      .doc(employeeId)
      .collection('overnight')
      .doc(docId)
      .delete();
}




  const OvernightItemDetailPage({
    super.key,
    required this.employeeId,
    required this.docId,
  });

  DocumentReference<Map<String, dynamic>> _ref() {
    return FirebaseFirestore.instance
        .collection('attendance')
        .doc(employeeId)
        .collection('overnight')
        .doc(docId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Overnight Detail'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: AppBackgroundWrapper(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder(
          stream: _ref().snapshots(),
          builder: (context, snapshot) {
  if (snapshot.connectionState == ConnectionState.waiting) {
    return const Center(child: CircularProgressIndicator());
  }

  // 🔑 DOKUMEN SUDAH DIHAPUS
  if (!snapshot.hasData || !snapshot.data!.exists) {
    return _glass(
      const Center(
        child: Text(
          'Overnight data not found',
          style: TextStyle(color: Colors.black54),
        ),
      ),
    );
  }

  final data = snapshot.data!.data();
  if (data == null) {
    return _glass(
      const Center(
        child: Text(
          'Overnight data not found',
          style: TextStyle(color: Colors.black54),
        ),
      ),
    );
  }

  final start = (data['startDate'] as Timestamp).toDate();
  final end = (data['endDate'] as Timestamp).toDate();

  return _glass(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _row('Customer', data['customerName']),
        _row('Category', data['customerCategory']),
        _row(
          'Date',
          '${start.day}/${start.month}/${start.year}'
          ' → ${end.day}/${end.month}/${end.year}',
        ),
        _row(
          'Total Nights',
          '${data['totalNights']} nights',
        ),
        const Divider(height: 24),
        Row(
          children: [
            Expanded(
  child: ElevatedButton(
    onPressed: () {
      final entry = OvernightEntry(
        id: docId,
        startDate: start,
        endDate: end,
        totalNights: data['totalNights'],
        customerName: data['customerName'],
        customerCategory: data['customerCategory'],
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddOvernightPage(
            employeeId: employeeId,
            existingEntry: entry,
            docId: docId,
          ),
        ),
      );
    },
    child: const Text('Edit'),
  ),
),

            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                ),
                onPressed: () => _deleteOvernight(context),
                child: const Text('Delete'),
              ),
            ),
          ],
        ),
      ],
    ),
  );
},

        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style:
                  const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

// reuse same glass
Widget _glass(Widget child) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
        child: child,
      ),
    ),
  );
}
