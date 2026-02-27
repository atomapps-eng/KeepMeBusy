import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import 'attendance_summary_calculator.dart';
import 'attendance_summary_model.dart';
import '../../pages/common/app_background_wrapper.dart';
import '../../theme/app_theme.dart';

class AttendanceSummaryPage extends StatefulWidget {
  final String employeeId;
  final String period;

  const AttendanceSummaryPage({
    super.key,
    required this.employeeId,
    required this.period,
  });

  @override
  State<AttendanceSummaryPage> createState() => _AttendanceSummaryPageState();
}

class _AttendanceSummaryPageState extends State<AttendanceSummaryPage> {
  late Future<AttendanceSummaryModel> _future;
  String _selectedView = 'overview'; // overview, details, charts
  late String _selectedPeriod;
  late List<String> _availablePeriods;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedPeriod = widget.period;
    _generateAvailablePeriods(widget.period);
    _future = AttendanceSummaryCalculator.calculate(
      employeeId: widget.employeeId,
      period: _selectedPeriod,
    );
  }

  void _generateAvailablePeriods(String currentPeriod) {
    // Parse current period (format: YYYY-MM)
    final parts = currentPeriod.split('-');
    if (parts.length != 2) {
      _availablePeriods = [currentPeriod];
      return;
    }

    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);

    // Generate 3 periods before and 3 after (total 7 periods)
    _availablePeriods = [];
    
    // Add 3 periods before
    for (int i = 3; i >= 1; i--) {
      int newMonth = month - i;
      int newYear = year;
      
      while (newMonth < 1) {
        newMonth += 12;
        newYear -= 1;
      }
      
      _availablePeriods.add('$newYear-${newMonth.toString().padLeft(2, '0')}');
    }
    
    // Add current period
    _availablePeriods.add(currentPeriod);
    
    // Add 3 periods after
    for (int i = 1; i <= 3; i++) {
      int newMonth = month + i;
      int newYear = year;
      
      while (newMonth > 12) {
        newMonth -= 12;
        newYear += 1;
      }
      
      _availablePeriods.add('$newYear-${newMonth.toString().padLeft(2, '0')}');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _changePeriod(String newPeriod) {
    if (newPeriod != _selectedPeriod) {
      setState(() {
        _selectedPeriod = newPeriod;
        _future = AttendanceSummaryCalculator.calculate(
          employeeId: widget.employeeId,
          period: _selectedPeriod,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.bar_chart,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Attendance Summary',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: isDesktop
            ? [
                // PERIOD SELECTOR TOGGLE - DYNAMIC
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Previous period arrow
                      if (_availablePeriods.indexOf(_selectedPeriod) > 0)
                        InkWell(
                          onTap: () => _changePeriod(
                            _availablePeriods[_availablePeriods.indexOf(_selectedPeriod) - 1]
                          ),
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            child: Icon(
                              Icons.chevron_left,
                              size: 20,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      
                      // Current period display with dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _selectedPeriod,
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 4),
                            PopupMenuButton<String>(
                              offset: const Offset(0, 40),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              onSelected: _changePeriod,
                              itemBuilder: (context) {
                                return _availablePeriods.map((period) {
                                  return PopupMenuItem<String>(
                                    value: period,
                                    child: Text(
                                      period,
                                      style: TextStyle(
                                        fontWeight: period == _selectedPeriod 
                                            ? FontWeight.bold 
                                            : FontWeight.normal,
                                        color: period == _selectedPeriod 
                                            ? AppTheme.primaryColor 
                                            : null,
                                      ),
                                    ),
                                  );
                                }).toList();
                              },
                              child: Icon(
                                Icons.arrow_drop_down,
                                size: 20,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Next period arrow
                      if (_availablePeriods.indexOf(_selectedPeriod) < _availablePeriods.length - 1)
                        InkWell(
                          onTap: () => _changePeriod(
                            _availablePeriods[_availablePeriods.indexOf(_selectedPeriod) + 1]
                          ),
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            child: Icon(
                              Icons.chevron_right,
                              size: 20,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // VIEW TOGGLE
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      _buildViewToggle('Overview', 'overview'),
                      _buildViewToggle('Details', 'details'),
                      _buildViewToggle('Charts', 'charts'),
                    ],
                  ),
                ),
              ]
            : null,
      ),
      body: AppBackgroundWrapper(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<AttendanceSummaryModel>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading summary data...'),
                  ],
                ),
              );
            }

            final s = snapshot.data!;

            if (isDesktop) {
              return _buildDesktopLayout(s);
            } else {
              return _buildMobileLayout(s);
            }
          },
        ),
      ),
    );
  }

  // ================= DESKTOP LAYOUT =================
  Widget _buildDesktopLayout(AttendanceSummaryModel s) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEFT SIDEBAR - EMPLOYEE INFO & STATS
        Container(
          width: 320,
          margin: const EdgeInsets.only(right: 16),
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                _buildEmployeeCard(s),
                const SizedBox(height: 16),
                _buildStatsCard(s),
                const SizedBox(height: 16),
                _buildQuickActionsCard(),
              ],
            ),
          ),
        ),

        // RIGHT CONTENT - MAIN CONTENT
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                if (_selectedView == 'overview') _buildOverviewView(s),
                if (_selectedView == 'details') _buildDetailsView(s),
                if (_selectedView == 'charts') _buildChartsView(s),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildViewToggle(String label, String value) {
    final isSelected = _selectedView == value;
    return InkWell(
      onTap: () => setState(() => _selectedView = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade600,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(AttendanceSummaryModel s) {
    return _glass(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: AppTheme.primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Employee',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.employeeId,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _infoRow('Period', s.period),
          _infoRow('Total Days', '${s.present + s.off + s.sickLeave + s.annualLeave + s.traveling + s.joinHoliday} days'),
          _infoRow('Work Days', '${s.present} days'),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(AttendanceSummaryModel s) {
    return _glass(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Key Statistics',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatProgress('Present', s.present, Colors.green, s.present.toDouble()),
          _buildStatProgress('Overtime', s.overtime, Colors.red, s.overtime.toDouble()),
          _buildStatProgress('Sick Leave', s.sickLeave, Colors.orange, s.sickLeave.toDouble()),
          _buildStatProgress('Annual Leave', s.annualLeave, Colors.blue, s.annualLeave.toDouble()),
          _buildStatProgress('Travel', s.traveling, Colors.purple, s.traveling.toDouble()),
          _buildStatProgress('Join Holiday', s.joinHoliday, Colors.pink, s.joinHoliday.toDouble()),
        ],
      ),
    );
  }

  Widget _buildStatProgress(String label, int value, Color color, double total) {
    final maxValue = 30.0; // Asumsi maksimum 30 hari
    final progress = (value / maxValue).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                '$value days',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return _glass(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildActionTile(
            icon: Icons.picture_as_pdf,
            label: 'Export as PDF',
            color: Colors.red,
            onTap: () {
              // Implement export PDF
            },
          ),
          _buildActionTile(
            icon: Icons.share,
            label: 'Share Report',
            color: Colors.blue,
            onTap: () {
              // Implement share
            },
          ),
          _buildActionTile(
            icon: Icons.print,
            label: 'Print',
            color: Colors.grey,
            onTap: () {
              // Implement print
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 12),
            Text(label),
            const Spacer(),
            Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  // ================= OVERVIEW VIEW =================
  Widget _buildOverviewView(AttendanceSummaryModel s) {
    return Column(
      children: [
        // KPI CARDS
        _buildKpiGrid(s),
        const SizedBox(height: 24),

        // CHARTS GRID
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildChartCard(
                title: 'Attendance Status',
                chart: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 30,
                    sections: _sections({
                      'Present': s.present,
                      'Off': s.off,
                      'Leave': s.annualLeave + s.sickLeave,
                      'Traveling': s.traveling,
                      'Join Holiday': s.joinHoliday,
                    }),
                  ),
                ),
                legend: _buildLegend({
                  'Present': s.present,
                  'Off': s.off,
                  'Leave': s.annualLeave + s.sickLeave,
                  'Traveling': s.traveling,
                  'Join Holiday': s.joinHoliday,
                }),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildChartCard(
                title: 'Work Location',
                chart: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 30,
                    sections: _sections({
                      'Office': s.office,
                      'Outstation': s.outstation,
                    }),
                  ),
                ),
                legend: _buildLegend({
                  'Office': s.office,
                  'Outstation': s.outstation,
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildChartCard(
                title: 'Activity Type',
                chart: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 30,
                    sections: _sections(s.activityByType),
                  ),
                ),
                legend: _buildLegend(s.activityByType),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildChartCard(
                title: 'Overnight',
                chart: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 30,
                    sections: _sections({
                      'Domestic': s.domesticNights,
                      'Overseas': s.internationalNights,
                    }),
                  ),
                ),
                legend: _buildLegend({
                  'Domestic': s.domesticNights,
                  'Overseas': s.internationalNights,
                }),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiGrid(AttendanceSummaryModel s) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(child: _buildKpiItem('Present', s.present, Icons.check_circle, Colors.green)),
          Expanded(child: _buildKpiItem('Overtime', s.overtime, Icons.access_time, Colors.red)),
          Expanded(child: _buildKpiItem('Sick', s.sickLeave, Icons.healing, Colors.orange)),
          Expanded(child: _buildKpiItem('Annual', s.annualLeave, Icons.beach_access, Colors.blue)),
          Expanded(child: _buildKpiItem('Travel', s.traveling, Icons.flight, Colors.purple)),
          Expanded(child: _buildKpiItem('Holiday', s.joinHoliday, Icons.celebration, Colors.pink)),
        ],
      ),
    );
  }

  Widget _buildKpiItem(String label, int value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard({
    required String title,
    required Widget chart,
    required Widget legend,
  }) {
    return _glass(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: chart,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: legend),
            ],
          ),
        ],
      ),
    );
  }

  // ================= DETAILS VIEW =================
  Widget _buildDetailsView(AttendanceSummaryModel s) {
    return Column(
      children: [
        _buildDetailsTable(s),
        const SizedBox(height: 24),
        _buildActivityBreakdown(s),
      ],
    );
  }

  Widget _buildDetailsTable(AttendanceSummaryModel s) {
    return _glass(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detailed Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1),
            },
            children: [
              const TableRow(
                decoration: BoxDecoration(
                  color: Colors.black12,
                ),
                children: [
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('Category', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('Count', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('Percentage', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              _buildDetailRow('Present', s.present, _getTotalDays(s), Colors.green),
              _buildDetailRow('Off', s.off, _getTotalDays(s), Colors.grey),
              _buildDetailRow('Sick Leave', s.sickLeave, _getTotalDays(s), Colors.orange),
              _buildDetailRow('Annual Leave', s.annualLeave, _getTotalDays(s), Colors.blue),
              _buildDetailRow('Travel', s.traveling, _getTotalDays(s), Colors.purple),
              _buildDetailRow('Join Holiday', s.joinHoliday, _getTotalDays(s), Colors.pink),
              _buildDetailRow('Overtime', s.overtime, _getTotalDays(s), Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  TableRow _buildDetailRow(String label, int value, int total, Color color) {
    final percentage = total > 0 ? (value / total * 100).toStringAsFixed(1) : '0';
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(label),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(value.toString()),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text('$percentage%'),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: color.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value / total,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityBreakdown(AttendanceSummaryModel s) {
    if (s.activityByType.isEmpty) {
      return const SizedBox.shrink();
    }

    return _glass(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activity Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...s.activityByType.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _colorForKey(entry.key),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(entry.key),
                  ),
                  Text(
                    '${entry.value} times',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // ================= CHARTS VIEW =================
  Widget _buildChartsView(AttendanceSummaryModel s) {
    return Column(
      children: [
        _buildLargeChartCard(
          title: 'Attendance Distribution',
          chart: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: _sections({
                'Present': s.present,
                'Off': s.off,
                'Sick Leave': s.sickLeave,
                'Annual Leave': s.annualLeave,
                'Travel': s.traveling,
                'Join Holiday': s.joinHoliday,
              }),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildLargeChartCard(
                title: 'Work Location',
                chart: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: _sections({
                      'Office': s.office,
                      'Outstation': s.outstation,
                    }),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildLargeChartCard(
                title: 'Overnight Distribution',
                chart: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: _sections({
                      'Domestic': s.domesticNights,
                      'Overseas': s.internationalNights,
                    }),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLargeChartCard({
    required String title,
    required Widget chart,
  }) {
    return _glass(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: chart,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= MOBILE LAYOUT (TETAP SAMA) =================
  Widget _buildMobileLayout(AttendanceSummaryModel s) {
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
          const SizedBox(height: 24),
          _donutSection(
            title: 'Overnight',
            data: {
              'Domestic': s.domesticNights,
              'Overseas': s.internationalNights,
            },
          ),
        ],
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
    return _glass(
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.5,
        children: [
          _kpiMini('Present', s.present, Icons.check_circle, Colors.green),
          _kpiMini('Overtime', s.overtime, Icons.access_time, Colors.red),
          _kpiMini('Sick', s.sickLeave, Icons.healing, Colors.orange),
          _kpiMini('Annual', s.annualLeave, Icons.beach_access, Colors.blue),
          _kpiMini('Travel', s.traveling, Icons.flight, Colors.purple),
          _kpiMini('Holiday', s.joinHoliday, Icons.celebration, Colors.pink),
        ],
      ),
    );
  }

  Widget _kpiMini(String label, int value, IconData icon, Color color) {
    return _glass(
      Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value.toString(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: chart,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: _legend(data)),
            ],
          ),
        ],
      ),
    );
  }

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

  Widget _buildLegend(Map<String, int> data) {
    final total = data.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: data.entries.map((e) {
        final percent = (e.value / total * 100).toStringAsFixed(0);
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _colorForKey(e.key),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  e.key,
                  style: const TextStyle(fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$percent%',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  int _getTotalDays(AttendanceSummaryModel s) {
    return s.present + s.off + s.sickLeave + s.annualLeave + s.traveling + s.joinHoliday;
  }
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
    case 'domestic':
      return Colors.teal;
    case 'overseas':
      return Colors.redAccent;
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