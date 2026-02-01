import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/attendance_service.dart';
import '../services/attendance_summary_helper.dart';
import '../models/attendance_day.dart';
import 'attendance_input_page.dart';
import '../../pages/common/app_background_wrapper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'activity_list_page.dart';
import 'attendance_list_page.dart';
import 'add_overnight_page.dart';
import 'overnight_detail_page.dart';
import '../attendance_summary/attendance_summary_page.dart';



class AttendancePage extends StatefulWidget {
  final String employeeId;
  final String period;

  const AttendancePage({
    super.key,
    required this.employeeId,
    required this.period,
  });

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {

void _exportAttendanceToPdf() {
  // TODO:
  // 1. Ambil data attendance by employeeId & period
  // 2. Generate PDF
  // 3. Share / save file

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Export PDF clicked'),
    ),
  );
}


  AttendanceStatus? _activeStatus;

  Stream<List<Map<String, dynamic>>> _activityPreviewStream() {
  return FirebaseFirestore.instance
      .collection('attendance')
      .doc(widget.employeeId)
      .collection('days')
      .snapshots()
      .asyncMap((daySnap) async {
    final List<Map<String, dynamic>> activities = [];

    for (final day in daySnap.docs) {
      final actSnap = await day.reference
          .collection('activities')
          .orderBy('createdAt', descending: true)
          .get();

      for (final a in actSnap.docs) {
        activities.add(a.data());
      }
    }

    activities.sort((a, b) {
      final aTime = a['createdAt'] as Timestamp?;
      final bTime = b['createdAt'] as Timestamp?;
      return (bTime?.millisecondsSinceEpoch ?? 0)
          .compareTo(aTime?.millisecondsSinceEpoch ?? 0);
    });

    return activities.take(3).toList();
  });
}

Stream<List<Map<String, dynamic>>> _overnightPreviewStream() {
  return FirebaseFirestore.instance
      .collection('attendance')
      .doc(widget.employeeId) // <-- Basuki Rahmat
      .collection('overnight')
      .orderBy('startDate', descending: true)
      .limit(3)
      .snapshots()
      .map((snap) {
        print('OVERNIGHT DOC COUNT: ${snap.docs.length}');
        return snap.docs.map((d) => d.data()).toList();
      });
}

Stream<Map<String, int>> _overnightSummaryStream() {
  return FirebaseFirestore.instance
      .collection('attendance')
      .doc(widget.employeeId)
      .collection('overnight')
      .snapshots()
      .map((snap) {
        int domestic = 0;
        int overseas = 0;

        for (final d in snap.docs) {
          final data = d.data();
          final nights = (data['totalNights'] ?? 0) as int;
          final category = data['customerCategory'];

          if (category == 'domestic') {
            domestic += nights;
          } else if (category == 'overseas') {
            overseas += nights;
          }
        }

        return {
          'domestic': domestic,
          'overseas': overseas,
        };
      });
}

// ================= SUMMARY =================
void _openAttendanceSummary() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Attendance Summary',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text('• Total days'),
            Text('• Present / Off / Leave'),
            Text('• Overtime count'),
          ],
        ),
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    final service = AttendanceService();

    return Scaffold(
  extendBodyBehindAppBar: true,
 appBar: AppBar(
  title: Text('Attendance • ${widget.period}'),
  backgroundColor: Colors.transparent,
  elevation: 0,
  actions: [
    // ===== EXPORT PDF =====
    IconButton(
      tooltip: 'Export to PDF',
      icon: const Icon(Icons.picture_as_pdf),
      onPressed: () {
        _exportAttendanceToPdf();
      },
    ),

    // ===== SUMMARY =====
    IconButton(
  tooltip: 'Summary',
  icon: const Icon(Icons.bar_chart),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AttendanceSummaryPage(
          employeeId: widget.employeeId,
          period: widget.period,
        ),
      ),
    );
  },
),

  ],
),

  body: AppBackgroundWrapper(
    padding: const EdgeInsets.fromLTRB(
      16,
      16,
      16,
      16,
    ),
        child: StreamBuilder<List<AttendanceDay>>(
          stream: service.streamAttendanceDays(widget.employeeId),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
  debugPrint('ATTENDANCE STREAM ERROR: ${snapshot.error}');
  return Center(
    child: Text(
      'Attendance stream error',
      style: TextStyle(color: Colors.red),
    ),
  );
}

            final allDays = (snapshot.data ?? []);              

            // ===== SORT TERBARU =====
            allDays.sort((a, b) => b.date.compareTo(a.date));

            // ===== SUMMARY =====
            final summary =
                AttendanceSummaryHelper.calculateStatusSummary(allDays);

            // ===== FILTER =====
            final filtered = _activeStatus == null
                ? allDays
                : allDays
                    .where((d) => d.status == _activeStatus)
                    .toList();

            // ===== PREVIEW MAKS 3 =====
            final previewDays = filtered.take(3).toList();

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // =================================================
                  // SECTION 1: DAILY ATTENDANCE
                  // =================================================
                  _glass(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Daily Attendance',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ===== SUMMARY CHIPS =====
                        _StatusChips(
                          summary: summary,
                          active: _activeStatus,
                          onTap: (s) {
                            setState(() {
                              _activeStatus =
                                  _activeStatus == s ? null : s;
                            });
                          },
                        ),

                        const Divider(height: 24),

                        // ===== PREVIEW LIST =====
                        if (previewDays.isEmpty)
                          const Text(
                            'No attendance data',
                            style:
                                TextStyle(color: Colors.black54),
                          ),

                        for (final d in previewDays)
                          ListTile(
                            dense: true,
                            title: Text(
                              '${d.date.day}/${d.date.month}/${d.date.year}',
                            ),
                            subtitle: Text(d.status.label),
                            trailing: const Icon(
                              Icons.chevron_right,
                              size: 18,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AttendanceInputPage(
                                    employeeId:
                                        widget.employeeId,
                                    date: d.date,
                                    existingDay: d,
                                  ),
                                ),
                              );
                            },
                          ),

                        const SizedBox(height: 12),

                        // ===== ACTION BUTTONS =====
                        Column(
  children: [
    SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.add),
        label: const Text('Add Attendance'),
        onPressed: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2035),
          );

          if (picked == null) return;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AttendanceInputPage(
                employeeId: widget.employeeId,
                date: picked,
              ),
            ),
          );
        },
      ),
    ),
    const SizedBox(height: 8),
    SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueGrey.shade100,
          foregroundColor: Colors.black87,
        ),
        onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AttendanceListPage(
          employeeId: widget.employeeId,
          period: widget.period,
        ),
      ),
    );
  },
        child: const Text('View Attendance'),
      ),
    ),
  ],
),

                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // =================================================
                  // SECTION 2: OVERNIGHT (RESTORED STRUCTURE)
                  // =================================================
                  _glass(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Overnight',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ===== SUMMARY CHIPS PLACEHOLDER =====
                        StreamBuilder<Map<String, int>>(
  stream: _overnightSummaryStream(),
  builder: (context, snapshot) {
    final summary = snapshot.data ?? {
      'domestic': 0,
      'overseas': 0,
    };

    return Wrap(
      spacing: 8,
      children: [
        _StaticChip(
          label: 'Domestic ${summary['domestic']}',
          color: Colors.blue,
        ),
        _StaticChip(
          label: 'Overseas ${summary['overseas']}',
          color: Colors.purple,
        ),
      ],
    );
  },
),


                        const Divider(height: 24),

StreamBuilder<List<Map<String, dynamic>>>(
  stream: _overnightPreviewStream(),
  builder: (context, snapshot) {
    final data = snapshot.data ?? [];

    if (data.isEmpty) {
      return const Text(
        'No overnight data',
        style: TextStyle(color: Colors.black54),
      );
    }

    return Column(
      children: data.map((o) {
        final start = (o['startDate'] as Timestamp).toDate();
        final end = (o['endDate'] as Timestamp).toDate();

        return ListTile(
          dense: true,
          title: Text(
            o['customerName'] ?? '-',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${o['customerCategory']} • '
            '${start.day}/${start.month} → ${end.day}/${end.month} '
            '(${o['totalNights']} nights)',
          ),
          trailing: const Icon(Icons.chevron_right, size: 18),
        );
      }).toList(),
    );
  },
),



                        const SizedBox(height: 12),

                        Column(
  children: [
    SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.add),
        label: const Text('Add Overnight'),
        onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => AddOvernightPage(
        employeeId: widget.employeeId,
      ),
    ),
  );
},

      ),
    ),
    const SizedBox(height: 8),
    SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueGrey.shade100,
          foregroundColor: Colors.black87,
        ),
        onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => OvernightDetailPage(
        employeeId: widget.employeeId,
        period: widget.period,
      ),
    ),
  );
},

        child: const Text('View Overnight'),
      ),
    ),
  ],
),

                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
// =================================================
// SECTION 3: ACTIVITIES
// =================================================
_glass(
  Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Activities',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 12),

      StreamBuilder<List<Map<String, dynamic>>>(
        stream: _activityPreviewStream(),
        builder: (context, snapshot) {
          final activities = snapshot.data ?? [];

          if (activities.isEmpty) {
            return const Text(
              'No activity data',
              style: TextStyle(color: Colors.black54),
            );
          }

          return Column(
            children: activities.map((a) {
              return ListTile(
                dense: true,
                title: Text(a['activityType']),
                subtitle: Text(
                  '${a['factoryClient']} • ${a['machine']}',
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  size: 18,
                ),
              );
            }).toList(),
          );
        },
      ),

      const SizedBox(height: 12),

      Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ActivityListPage(
        employeeId: widget.employeeId,
        period: widget.period,
      ),
    ),
  );
},

          child: const Text('View Activities'),
        ),
      ),
    ],
  ),
),

                 
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// =======================================================
// UI HELPERS
// =======================================================

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
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.4)),
        ),
        child: child,
      ),
    ),
  );
}

class _StaticChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StaticChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _StatusChips extends StatelessWidget {
  final Map<String, int> summary;
  final AttendanceStatus? active;
  final Function(AttendanceStatus) onTap;

  const _StatusChips({
    required this.summary,
    required this.active,
    required this.onTap,
  });

  Widget _chip(
    String label,
    int value,
    Color color,
    AttendanceStatus status,
  ) {
    return InkWell(
      onTap: () => onTap(status),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(
              alpha: active == status ? 0.25 : 0.15),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Text(
          '$label $value',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        _chip('Present', summary['present'] ?? 0,
            Colors.green, AttendanceStatus.present),
        _chip('Off', summary['off'] ?? 0, Colors.grey,
            AttendanceStatus.off),
        _chip('Sick', summary['sickLeave'] ?? 0,
            Colors.orange, AttendanceStatus.sickLeave),
        _chip('Annual Leave', summary['annualLeave'] ?? 0,
            Colors.blue, AttendanceStatus.annualLeave),
        _chip('Travel', summary['traveling'] ?? 0,
            Colors.deepPurple, AttendanceStatus.traveling),
        _chip('Join Holiday', summary['joinHoliday'] ?? 0,
            Colors.pink, AttendanceStatus.joinHoliday),
        Container(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  decoration: BoxDecoration(
    color: Colors.red.withValues(alpha: 0.15),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: Colors.red.withValues(alpha: 0.45)),
  ),
  child: Text(
    'Overtime ${summary['overtime'] ?? 0}',
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Colors.red,
    ),
  ),
),
      ],
    );
  }
}
