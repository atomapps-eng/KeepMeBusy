import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import 'attendance_summary_calculator.dart';
import 'attendance_summary_model.dart';
import '../../pages/common/app_background_wrapper.dart';

class AttendanceSummaryPage extends StatefulWidget {
  final String employeeId;
  final String period;

  const AttendanceSummaryPage({
    super.key,
    required this.employeeId,
    required this.period,
  });

  @override
  State<AttendanceSummaryPage> createState() =>
      _AttendanceSummaryPageState();
}

class _AttendanceSummaryPageState
    extends State<AttendanceSummaryPage> {
  late Future<AttendanceSummaryModel> _future;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _future = AttendanceSummaryCalculator.calculate(
      employeeId: widget.employeeId,
      period: widget.period,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Attendance Summary'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: AppBackgroundWrapper(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<AttendanceSummaryModel>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final s = snapshot.data!;

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(s),
                  const SizedBox(height: 20),

                  _kpiSection(s),
                  const SizedBox(height: 24),

                  _pieSection(
                    title: 'Attendance Status',
                    data: {
                      'Present': s.present,
                      'Off': s.off,
                      'Leave': s.annualLeave + s.sickLeave,
                      'Traveling': s.traveling,
                      'Join Holiday': s.joinHoliday,
                    },
                  ),
                  const SizedBox(height: 24),

                  _donutSection(
                    title: 'Work Location',
                    data: {
                      'Office': s.office,
                      'Outstation': s.outstation,
                    },
                  ),
                  const SizedBox(height: 24),

                  _donutSection(
                    title: 'Activity Type',
                    data: s.activityByType,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ================= HEADER =================
  Widget _header(AttendanceSummaryModel s) {
    return _glass(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Attendance Summary Report',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _headerItem('Employee ID', s.employeeId)),
              Expanded(child: _headerItem('Period', s.period)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: const TextStyle(fontSize: 11, color: Colors.black54)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ================= KPI =================
  Widget _kpiSection(AttendanceSummaryModel s) {
    return Row(
      children: [
        Expanded(
          child: _kpiCard(
              'Present', s.present, Icons.check_circle, Colors.green),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _kpiCard(
              'Overtime', s.overtime, Icons.access_time, Colors.red),
        ),
      ],
    );
  }

  Widget _kpiCard(
      String label, int value, IconData icon, Color color) {
    return _glass(
      Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 4),
              Text(value.toString(),
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  // ================= CHART =================
  Widget _pieSection({
    required String title,
    required Map<String, int> data,
  }) {
    return _chartContainer(
      title: title,
      data: data,
      chart: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 20,
          sections: _sections(data),
        ),
      ),
    );
  }

  Widget _donutSection({
    required String title,
    required Map<String, int> data,
  }) {
    return _chartContainer(
      title: title,
      data: data,
      chart: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 20,
          sections: _sections(data),
        ),
      ),
    );
  }

  Widget _chartContainer({
    required String title,
    required Map<String, int> data,
    required Widget chart,
  }) {
    return _glass(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(width: 180, height: 180, child: chart),
              const SizedBox(width: 16),
              Expanded(child: _legend(data)),
            ],
          ),
        ],
      ),
    );
  }
}

// ================= HELPERS =================
Widget _legend(Map<String, int> data) {
  final total = data.values.fold<int>(0, (a, b) => a + b);
  if (total == 0) return const SizedBox.shrink();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: data.entries.map((e) {
      final percent = (e.value / total * 100).toStringAsFixed(0);
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _colorForKey(e.key),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text('${e.key} ($percent%)',
                style: const TextStyle(fontSize: 12)),
          ],
        ),
      );
    }).toList(),
  );
}

List<PieChartSectionData> _sections(Map<String, int> data) {
  final total = data.values.fold<int>(0, (a, b) => a + b);
  if (total == 0) return [];

  return data.entries.map((e) {
    return PieChartSectionData(
      value: e.value.toDouble(),
      radius: 60,
      title: e.value.toString(),
      titleStyle: const TextStyle(
          fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
      color: _colorForKey(e.key),
    );
  }).toList();
}

Color _colorForKey(String key) {
  switch (key.toLowerCase()) {
    case 'present':
      return Colors.green;
    case 'off':
      return Colors.grey;
    case 'leave':
      return Colors.blue;
    case 'traveling':
      return Colors.purple;
    case 'join holiday':
      return Colors.pink;
    case 'office':
      return Colors.blue;
    case 'outstation':
      return Colors.orange;
    default:
      return Colors.grey.shade600;
  }
}

Widget _glass(Widget child) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: child,
    ),
  );
}
