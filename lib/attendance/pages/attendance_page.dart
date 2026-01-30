import 'dart:ui';
import 'package:flutter/material.dart';

import '../services/attendance_service.dart';
import '../services/attendance_summary_helper.dart';
import '../models/attendance_day.dart';

import 'attendance_input_page.dart';
import '../../pages/common/app_background_wrapper.dart';

/* ================= OVERNIGHT MODEL ================= */

class OvernightEntry {
  final DateTime start;
  final DateTime end;
  final String category; // domestic | overseas

  OvernightEntry({
    required this.start,
    required this.end,
    required this.category,
  });

  int get nights => end.difference(start).inDays + 1;
}

/* ================= PAGE ================= */

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
  AttendanceStatus? filter;
  final List<OvernightEntry> overnights = [];

  @override
  Widget build(BuildContext context) {
    final service = AttendanceService();

    return AppBackgroundWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(period: widget.period),
          const SizedBox(height: 16),

          Expanded(
            child: StreamBuilder<List<AttendanceDay>>(
              stream:
                  service.streamAttendanceDays(widget.employeeId),
              builder: (context, snapshot) {
                final days = (snapshot.data ?? [])
                    .where((d) => d.period == widget.period)
                    .toList()
                  ..sort((a, b) =>
                      a.date.compareTo(b.date));

                final summary =
                    AttendanceSummaryHelper.calculateStatusSummary(
                        days);

                final filteredDays = filter == null
                    ? days
                    : days
                        .where((d) => d.status == filter)
                        .toList();

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      /* ================= DAILY ATTENDANCE ================= */

                      _GlassCard(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Daily Attendance',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight.bold),
                            ),

                            const SizedBox(height: 12),

                            _StatusChips(
                              summary: summary,
                              active: filter,
                              onTap: (s) {
                                setState(() {
                                  filter =
                                      filter == s ? null : s;
                                });
                              },
                            ),

                            const Divider(height: 24),

                            if (filteredDays.isEmpty)
                              const Text(
                                'No attendance data',
                                style: TextStyle(
                                    color: Colors.black54),
                              ),

                            ListView.separated(
                              shrinkWrap: true,
                              physics:
                                  const NeverScrollableScrollPhysics(),
                              itemCount: filteredDays.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, i) {
                                final d = filteredDays[i];
                                return ListTile(
                                  dense: true,
                                  title: Text(
                                      '${d.date.day}/${d.date.month}/${d.date.year}'),
                                  subtitle:
                                      Text(d.status.name),
                                  trailing: const Icon(Icons.edit,
                                      size: 18),
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
                                );
                              },
                            ),

                            const SizedBox(height: 12),

                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.add,
                                    size: 18),
                                label: const Text(
                                  'Add Attendance',
                                  style: TextStyle(fontSize: 12),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          AttendanceInputPage(
                                        employeeId:
                                            widget.employeeId,
                                        date: DateTime.now(),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      /* ================= OVERNIGHT ================= */

                      _GlassCard(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Overnight',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight.bold),
                            ),

                            const SizedBox(height: 12),

                            _OvernightChips(overnights),

                            const Divider(height: 24),

                            if (overnights.isEmpty)
                              const Text(
                                'No overnight data',
                                style: TextStyle(
                                    color: Colors.black54),
                              ),

                            ListView.separated(
                              shrinkWrap: true,
                              physics:
                                  const NeverScrollableScrollPhysics(),
                              itemCount: overnights.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, i) {
                                final o = overnights[i];
                                return ListTile(
                                  dense: true,
                                  title: Text(
                                      '${o.start.day}/${o.start.month} → ${o.end.day}/${o.end.month}'),
                                  subtitle: Text(
                                      '${o.category} • ${o.nights} nights'),
                                );
                              },
                            ),

                            const SizedBox(height: 12),

                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.add,
                                    size: 18),
                                label: const Text(
                                  'Add Overnight',
                                  style: TextStyle(fontSize: 12),
                                ),
                                onPressed: () async {
                                  final result =
                                      await _showAddOvernight(
                                          context);
                                  if (result != null) {
                                    setState(() {
                                      overnights.add(result);
                                    });
                                  }
                                },
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
        ],
      ),
    );
  }
}

/* ================= STATUS CHIPS ================= */

class _StatusChips extends StatelessWidget {
  final Map<String, int> summary;
  final AttendanceStatus? active;
  final Function(AttendanceStatus) onTap;

  const _StatusChips({
    required this.summary,
    required this.active,
    required this.onTap,
  });

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
        _chip('Leave', summary['annualLeave'] ?? 0,
            Colors.blue, AttendanceStatus.annualLeave),
        _chip('Travel', summary['traveling'] ?? 0,
            Colors.deepPurple, AttendanceStatus.traveling),
        _chip('Holiday', summary['joinHoliday'] ?? 0,
            Colors.pink, AttendanceStatus.joinHoliday),
      ],
    );
  }

  Widget _chip(String label, int value, Color color,
      AttendanceStatus status) {
    final selected = active == status;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => onTap(status),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.25)
              : color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Text(
          '$label $value',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color),
        ),
      ),
    );
  }
}

/* ================= OVERNIGHT CHIPS ================= */

class _OvernightChips extends StatelessWidget {
  final List<OvernightEntry> data;
  const _OvernightChips(this.data);

  @override
  Widget build(BuildContext context) {
    final domestic = data
        .where((o) => o.category == 'domestic')
        .fold<int>(0, (s, o) => s + o.nights);
    final overseas = data
        .where((o) => o.category == 'overseas')
        .fold<int>(0, (s, o) => s + o.nights);

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        _chip('Domestic', domestic, Colors.green),
        _chip('Overseas', overseas, Colors.blue),
      ],
    );
  }

  Widget _chip(String label, int value, Color color) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color),
      ),
    );
  }
}

/* ================= SMALL HELPERS ================= */

class _Header extends StatelessWidget {
  final String period;
  const _Header({required this.period});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Attendance • $period',
      style:
          const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
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
                color: Colors.white.withValues(alpha: 0.4)),
          ),
          child: child,
        ),
      ),
    );
  }
}

/* ================= ADD OVERNIGHT ================= */

Future<OvernightEntry?> _showAddOvernight(
    BuildContext context) async {
  DateTime? start;
  DateTime? end;
  String category = 'domestic';

  return showDialog<OvernightEntry>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Add Overnight'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(start == null
                ? 'Start Date'
                : start.toString().split(' ').first),
            trailing: const Icon(Icons.date_range),
            onTap: () async {
              start = await showDatePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                initialDate: DateTime.now(),
              );
            },
          ),
          ListTile(
            title: Text(end == null
                ? 'End Date'
                : end.toString().split(' ').first),
            trailing: const Icon(Icons.date_range),
            onTap: () async {
              end = await showDatePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                initialDate: start ?? DateTime.now(),
              );
            },
          ),
          DropdownButton<String>(
            value: category,
            items: const [
              DropdownMenuItem(
                  value: 'domestic', child: Text('Domestic')),
              DropdownMenuItem(
                  value: 'overseas', child: Text('Overseas')),
            ],
            onChanged: (v) => category = v!,
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (start != null && end != null) {
              Navigator.pop(
                context,
                OvernightEntry(
                    start: start!,
                    end: end!,
                    category: category),
              );
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
