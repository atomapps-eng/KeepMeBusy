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
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) {
          return snap.docs
              .map((d) => AttendanceDay.fromFirestore(d))
              .where((d) => d.period == period) // FILTER CLIENT
              .toList();
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Attendance • $period'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: AppBackgroundWrapper(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<List<AttendanceDay>>(
          stream: _attendanceStream(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final days = snapshot.data!;

            if (days.isEmpty) {
              return const Center(
                child: Text(
                  'No attendance data',
                  style: TextStyle(color: Colors.black54),
                ),
              );
            }

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Location')),
                  DataColumn(label: Text('Customer')),
                  DataColumn(label: Text('Note')),
                ],
                rows: days.map((d) {
                  return DataRow(
                    cells: [
                      DataCell(Text(
                          '${d.date.day}/${d.date.month}/${d.date.year}')),
                      DataCell(Text(d.status.name)),
                      DataCell(Text(d.location.name)),
                      DataCell(Text(d.customerId ?? '-')),
                      DataCell(Text(d.note ?? '-')),
                    ],
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }
}
