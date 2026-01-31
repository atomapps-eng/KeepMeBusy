import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../pages/common/app_background_wrapper.dart';
import 'overnight_item_detail_page.dart';

class OvernightDetailPage extends StatelessWidget {
  final String employeeId;
  final String period;

  const OvernightDetailPage({
    super.key,
    required this.employeeId,
    required this.period,
  });

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _stream() {
    return FirebaseFirestore.instance
        .collection('attendance')
        .doc(employeeId)
        .collection('overnight')
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((s) => s.docs);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Overnight • $period'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: AppBackgroundWrapper(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder(
          stream: _stream(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!;
            if (docs.isEmpty) {
              return _glass(
                const Text(
                  'No overnight data',
                  style: TextStyle(color: Colors.black54),
                ),
              );
            }

            return _glass(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Overnight List',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 24),

                  ...docs.map((doc) {
                    final o = doc.data();
                    final start =
                        (o['startDate'] as Timestamp).toDate();
                    final end =
                        (o['endDate'] as Timestamp).toDate();

                    return ListTile(
                      dense: true,
                      title: Text(o['customerName']),
                      subtitle: Text(
                        '${o['customerCategory']} • '
                        '${start.day}/${start.month} → '
                        '${end.day}/${end.month} '
                        '(${o['totalNights']} nights)',
                      ),
                      trailing:
                          const Icon(Icons.chevron_right, size: 18),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                OvernightItemDetailPage(
                              employeeId: employeeId,
                              docId: doc.id,
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// === SAME GLASS UI AS ATTENDANCE PAGE ===
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
