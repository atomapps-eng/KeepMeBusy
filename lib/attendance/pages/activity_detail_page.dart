import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../pages/common/app_background_wrapper.dart';
import 'activity_form_page.dart';


class ActivityDetailPage extends StatelessWidget {
  final String employeeId;
  final String dayDocId;
  final String activityId;
  final Map<String, dynamic> activity;

  const ActivityDetailPage({
    super.key,
    required this.employeeId,
    required this.dayDocId,
    required this.activityId,
    required this.activity,
  });

  Future<void> _deleteActivity(BuildContext context) async {
    await FirebaseFirestore.instance
        .collection('attendance')
        .doc(employeeId)
        .collection('days')
        .doc(dayDocId)
        .collection('activities')
        .doc(activityId)
        .delete();

    if (!context.mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final Timestamp? ts = activity['date'] as Timestamp?;
    final DateTime? date = ts?.toDate();


    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Activity Detail'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: AppBackgroundWrapper(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _glass(_info('Date', date.toString().split(' ').first)),
            _glass(_info('Factory / Client', activity['factoryClient'])),
            _glass(_info('Machine', activity['machine'])),
            _glass(_info('Serial Number', activity['serialNumber'])),
            _glass(_info('Activity', activity['activityType'])),
            _glass(_info('Description', activity['description'])),
            _glass(_info('Status', activity['status'])),
            _glass(_info('Note', activity['note'] ?? '-')),

            const Spacer(),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () => _deleteActivity(context),
                    child: const Text('Delete'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final result =
                          await Navigator.push(
                        context,
                        MaterialPageRoute(
                         // EDIT ACTIVITY DISABLE SEMENTARA
builder: (_) => ActivityFormPage(
  attendanceDate: (activity['date'] as Timestamp).toDate(),
  factoryClientName: activity['factoryClient'] ?? '',
),

                        ),
                      );

                      if (result != null && context.mounted) {
                        await FirebaseFirestore.instance
                            .collection('attendance')
                            .doc(employeeId)
                            .collection('days')
                            .doc(dayDocId)
                            .collection('activities')
                            .doc(activityId)
                            .set(result, SetOptions(merge: true));

                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Edit'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =======================================================
// UI HELPERS
// =======================================================
Widget _glass(Widget child) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.25),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.35),
      ),
    ),
    child: child,
  );
}

Widget _info(String label, dynamic value) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.black54,
        ),
      ),
      const SizedBox(height: 4),
      Text(
  value?.toString().isNotEmpty == true ? value.toString() : '-',
),
    ],
  );
}
