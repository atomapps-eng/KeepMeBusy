import 'package:flutter/material.dart';
import '../../pages/common/app_background_wrapper.dart';
import 'activity_detail_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/session/company_session.dart';

class ActivityListPage extends StatelessWidget {
  final String employeeId;
  final String period;
  final DateTime? initialDate;

  const ActivityListPage({
    super.key,
    required this.employeeId,
    required this.period,
     this.initialDate,
  });

 Stream<List<Map<String, dynamic>>> _activityStream() {
  final companyId = CompanySession.selectedCompanyId;

  return FirebaseFirestore.instance
      .collectionGroup('activities')
      .where('companyId', isEqualTo: companyId)
      .where('employeeId', isEqualTo: employeeId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
        print("Activity docs: ${snapshot.docs.length}");
        return snapshot.docs.map((doc) {
          final data = doc.data();
          data['activityId'] = doc.id;
          return data;
        }).toList();
      });
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
