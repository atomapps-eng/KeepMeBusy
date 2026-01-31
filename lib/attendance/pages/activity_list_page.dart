import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../pages/common/app_background_wrapper.dart';
import 'activity_detail_page.dart';

class ActivityListPage extends StatelessWidget {
  final String employeeId;
  final String period;

  const ActivityListPage({
    super.key,
    required this.employeeId,
    required this.period,
  });

  Stream<List<Map<String, dynamic>>> _activityStream() async* {
    final daysSnap = await FirebaseFirestore.instance
        .collection('attendance')
        .doc(employeeId)
        .collection('days')
        .get();

    final List<Map<String, dynamic>> all = [];

    for (final day in daysSnap.docs) {
      if (day['period'] != period) continue;

      final actSnap = await day.reference
          .collection('activities')
          .orderBy('createdAt', descending: true)
          .get();

      for (final a in actSnap.docs) {
        final data = a.data();
        data['dayDocId'] = day.id;
        data['activityId'] = a.id;
        all.add(data);
      }
    }

    yield all;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Activities'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: AppBackgroundWrapper(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _activityStream(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final activities = snapshot.data!;

            if (activities.isEmpty) {
              return const Center(
                child: Text(
                  'No activity data',
                  style: TextStyle(color: Colors.black54),
                ),
              );
            }

            return ListView.builder(
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final a = activities[index];

                return _glass(
                  ListTile(
                    title: Text(a['activityType']),
                    subtitle:
                        Text('${a['factoryClient']} • ${a['machine']}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ActivityDetailPage(
                            employeeId: employeeId,
                            dayDocId: a['dayDocId'],
                            activityId: a['activityId'],
                            activity: a,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

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
