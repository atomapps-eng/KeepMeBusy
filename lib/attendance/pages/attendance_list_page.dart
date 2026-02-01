import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/attendance_day.dart';
import '../../pages/common/app_background_wrapper.dart';
import '../pages/attendance_input_page.dart';

class AttendanceListPage extends StatefulWidget {
  final String employeeId;
  final String period;

  const AttendanceListPage({
    super.key,
    required this.employeeId,
    required this.period,
  });

  @override
  State<AttendanceListPage> createState() => _AttendanceListPageState();
}

class _AttendanceListPageState extends State<AttendanceListPage> {
  DateTime? fromDate;
  DateTime? toDate;

  Stream<List<AttendanceDay>> _attendanceStream() {
    return FirebaseFirestore.instance
        .collection('attendance')
        .doc(widget.employeeId)
        .collection('days')
        .orderBy('date', descending: false)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => AttendanceDay.fromFirestore(d)).toList(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Attendance Detail • ${widget.period}'),
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
            _filterHeader(context),
            const SizedBox(height: 12),
            Expanded(child: _attendanceList()),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // FILTER HEADER
  // =====================================================
  Widget _filterHeader(BuildContext context) {
    return _glass(
      Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: fromDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                );
                if (d != null) setState(() => fromDate = d);
              },
              child: _dateBox(
                fromDate == null ? 'From Date' : _fmt(fromDate!),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: toDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                );
                if (d != null) setState(() => toDate = d);
              },
              child: _dateBox(
                toDate == null ? 'To Date' : _fmt(toDate!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateBox(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black26),
      ),
      child: Text(text),
    );
  }

  // =====================================================
  // LIST
  // =====================================================
  Widget _attendanceList() {
    return StreamBuilder<List<AttendanceDay>>(
      stream: _attendanceStream(),
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

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final days = snapshot.data!
            .where((d) => d.period == widget.period)
            .where((d) {
              if (fromDate != null && d.date.isBefore(fromDate!)) {
                return false;
              }
              if (toDate != null && d.date.isAfter(toDate!)) {
                return false;
              }
              return true;
            })
            .toList();

        if (days.isEmpty) {
          return const Center(
            child: Text(
              'No attendance data',
              style: TextStyle(color: Colors.black54),
            ),
          );
        }

        return ListView.builder(
          itemCount: days.length,
          itemBuilder: (context, index) {
            return _attendanceCard(days[index]);
          },
        );
      },
    );
  }

  // =====================================================
  // CARD
  // =====================================================
 Widget _attendanceCard(AttendanceDay d) {
  return InkWell(
    borderRadius: BorderRadius.circular(20), // 🔥 wajib sama dengan _glass
    splashColor: Colors.black12,
    highlightColor: Colors.black.withOpacity(0.05),
    onTap: () {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AttendanceInputPage(
            employeeId: widget.employeeId,
            date: d.date,
            existingDay: d, // 👉 masuk EDIT mode
          ),
        ),
      );
    },
    child: _glass(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _fmt(d.date),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),

          Text('${d.status.name} • ${d.location.name}'),

          if (d.location == AttendanceLocation.outstation)
            Text('Customer: ${d.customerName ?? '-'}'),

          const SizedBox(height: 6),

          Row(
            children: [
              Text('In: ${_time(d.checkInHour, d.checkInMinute)}'),
              const SizedBox(width: 12),
              Text('Out: ${_time(d.checkOutHour, d.checkOutMinute)}'),
            ],
          ),

          if (isOvertime(d))
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Overtime',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          if (d.note?.isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Text('Note: ${d.note}'),
          ],
        ],
      ),
    ),
  );
}



  // =====================================================
  // HELPERS
  // =====================================================
  static String _fmt(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';

  static String _time(int? h, int? m) {
    if (h == null) return '-';
    return '${h.toString().padLeft(2, '0')}:${(m ?? 0).toString().padLeft(2, '0')}';
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
        margin: const EdgeInsets.only(bottom: 12),
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

bool isOvertime(AttendanceDay d) {
  if (d.status != AttendanceStatus.present) return false;
  if (d.checkOutHour == null) return false;

  if (d.checkOutHour! > 18) return true;
  if (d.checkOutHour == 18 && (d.checkOutMinute ?? 0) > 0) return true;

  return false;
}
