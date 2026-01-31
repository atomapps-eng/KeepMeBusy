import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/attendance_day.dart';
import '../../pages/common/app_background_wrapper.dart';

class AttendanceListPage extends StatelessWidget {
  final String employeeId;
  final String period;

  const AttendanceListPage({
    super.key,
    required this.employeeId,
    required this.period,
  });

  Stream<List<AttendanceDay>> _attendanceStream() {
    return FirebaseFirestore.instance
        .collection('attendance')
        .doc(employeeId)
        .collection('days')
        .orderBy('date', descending: false)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => AttendanceDay.fromFirestore(d))
              .toList(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Attendance Detail • $period'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: AppBackgroundWrapper(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: StreamBuilder<List<AttendanceDay>>(
          stream: _attendanceStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  'No attendance data',
                  style: TextStyle(color: Colors.black54),
                ),
              );
            }

            // ================= FILTER PERIOD DI DART =================
            final allDays = snapshot.data!;
            final days = allDays
                .where((d) => d.period == period)
                .toList();

            if (days.isEmpty) {
              return const Center(
                child: Text(
                  'No attendance data',
                  style: TextStyle(color: Colors.black54),
                ),
              );
            }

            return _glass(
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 16,
                  headingRowHeight: 44,
                  dataRowHeight: 44,
                  columns: const [
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Location')),
                    DataColumn(label: Text('Customer')),
                    DataColumn(label: Text('Check In')),
                    DataColumn(label: Text('Check Out')),
                    DataColumn(label: Text('Note')),
                  ],
                  rows: days.map((d) {
  return DataRow(
    cells: [
      // 1. DATE
      DataCell(
        Text('${d.date.day}/${d.date.month}/${d.date.year}'),
      ),

      // 2. STATUS
      DataCell(Text(d.status.name)),

      // 3. LOCATION
      DataCell(Text(d.location.name)),

      // 4. CUSTOMER  ✅ (POSISI BENAR)
      DataCell(
        Text(
          d.location == AttendanceLocation.outstation
              ? (d.customerName ?? '-')
              : '-',
        ),
      ),

      // 5. CHECK IN
      DataCell(
        Text(
          d.checkInHour != null
              ? _formatTime(
                  d.checkInHour!,
                  d.checkInMinute ?? 0,
                )
              : '-',
        ),
      ),

      // 6. CHECK OUT
      DataCell(
        Text(
          d.checkOutHour != null
              ? _formatTime(
                  d.checkOutHour!,
                  d.checkOutMinute ?? 0,
                )
              : '-',
        ),
      ),

      // 7. NOTE
      DataCell(
        Text(d.note?.isNotEmpty == true ? d.note! : '-'),
      ),
    ],
  );
}).toList(),

                ),
              ),
            );
          },
        ),
      ),
    );
  }

  static String _formatTime(int h, int m) {
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}

// =======================================================
// GLASS CONTAINER
// =======================================================
Widget _glass(Widget child) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
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
