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
import '../../core/services/company_firestore.dart';
import '../../theme/app_theme.dart';
import '../../services/pdf_report_service.dart';
import '../../services/pdf_action_service.dart';
import '../../attendance/attendance_summary/attendance_summary_calculator.dart';
import '../services/attendance_period_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/activity_entry.dart';

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
  AttendanceStatus? _activeStatus;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  late String _selectedPeriod;
  bool _isAllPeriod = false;
  String? _companyId;
  double _progress = 0.0;
  String _progressText = "Preparing...";

  @override
  void initState() {
    super.initState();
    _selectedPeriod = widget.period;
    _isAllPeriod = false;
    _loadCompanyId();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

 Future<void> _exportAttendanceToPdf() async {
  try {
    if (!mounted) return;

    _progress = 0;
    _progressText = "Preparing...";
    _showProgressDialog();

    final service = AttendanceService();

    _updateProgress(0.1, "Loading attendance data...");

    List<AttendanceDay> days = [];
    await for (var snapshot in service.streamAttendanceDays(widget.employeeId)) {
      days = snapshot;
      break;
    }

    _updateProgress(0.25, "Filtering data...");

    final filteredDays = _applyPeriodFilter(days);

    final period = _isAllPeriod ? 'ALL' : _selectedPeriod;

    _updateProgress(0.4, "Calculating summary...");

    final summary = await AttendanceSummaryCalculator.calculate(
      employeeId: widget.employeeId,
      period: period,
    );

    _updateProgress(0.55, "Loading activities...");

    final activities = await _getActivitiesForPeriod();

    _updateProgress(0.7, "Preparing employee data...");

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.employeeId)
        .get();

    final employeeName = doc.data()?['name'] ?? widget.employeeId;

    _updateProgress(0.85, "Generating PDF...");

    final bytes = await PdfReportService.generatePdf(
      employeeId: widget.employeeId,
      employeeName: employeeName,
      period: period,
      attendanceDays: filteredDays,
      summary: summary,
      activities: activities,
    );

    _updateProgress(1.0, "Opening PDF...");

    if (mounted) Navigator.pop(context);

    await openPdf(bytes, 'attendance_${widget.employeeId}_$period.pdf');

  } catch (e) {
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e')),
      );
    }
  }
}

  Stream<List<Map<String, dynamic>>> _activityPreviewStream() {
    return CompanyFirestore
        .collection('attendance')
        .doc(widget.employeeId)
        .collection('days')
        .snapshots()
        .asyncMap((daySnap) async {
      final List<Map<String, dynamic>> activities = [];

      for (final day in daySnap.docs) {
        final parts = day.id.split('-');
        if (parts.length != 3) continue;

        final date = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );

        final period = AttendancePeriodHelper.resolvePeriod(date);

        if (!_isAllPeriod && period != _selectedPeriod) continue;

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
    return CompanyFirestore
        .collection('attendance')
        .doc(widget.employeeId)
        .collection('overnight')
        .snapshots()
        .map((snap) {
      final filtered = snap.docs.where((d) {
        final data = d.data();
        final start = (data['startDate'] as Timestamp).toDate();

        final month = start.month.toString().padLeft(2, '0');
        final period = '${start.year}-$month';

        if (_isAllPeriod) return true;
        return period == _selectedPeriod;
      }).toList();

      filtered.sort((a, b) {
        final aDate = (a['startDate'] as Timestamp).millisecondsSinceEpoch;
        final bDate = (b['startDate'] as Timestamp).millisecondsSinceEpoch;
        return bDate.compareTo(aDate);
      });

      return filtered.take(3).map((d) => d.data()).toList();
    });
  }

  Stream<Map<String, int>> _overnightSummaryStream() {
    return CompanyFirestore
        .collection('attendance')
        .doc(widget.employeeId)
        .collection('overnight')
        .snapshots()
        .map((snap) {
      int domestic = 0;
      int overseas = 0;

      for (final d in snap.docs) {
        final data = d.data();
        final start = (data['startDate'] as Timestamp).toDate();

        final month = start.month.toString().padLeft(2, '0');
        final period = '${start.year}-$month';

        if (!_isAllPeriod && period != _selectedPeriod) continue;

        final nights = (data['totalNights'] ?? 0) as int;
        final category = data['customerCategory'];

        if (category == 'domestic') {
          domestic += nights;
        } else if (category == 'overseas') {
          overseas += nights;
        }
      }

      return {'domestic': domestic, 'overseas': overseas};
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = AttendanceService();
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        titleSpacing: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.white.withValues(alpha:0.2),
            ),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withValues(alpha:0.2),
                    AppTheme.primaryColor.withValues(alpha:0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha:0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.calendar_month,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Attendance',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.period,
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (isDesktop)
            Container(
              width: 250,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha:0.15),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withValues(alpha:0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search attendance...',
                  hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade600, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          Container(
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.withValues(alpha:0.2),
                  Colors.green.withValues(alpha:0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.green.withValues(alpha:0.3),
                width: 1,
              ),
            ),
            child: IconButton(
              tooltip: 'Export to PDF',
              icon: const Icon(Icons.picture_as_pdf, color: Colors.green, size: 22),
              onPressed: _exportAttendanceToPdf,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withValues(alpha:0.2),
                  AppTheme.primaryColor.withValues(alpha:0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha:0.3),
                width: 1,
              ),
            ),
            child: IconButton(
              tooltip: 'Summary',
              icon: Icon(
                Icons.bar_chart,
                color: AppTheme.primaryColor,
                size: 22,
              ),
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
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.withValues(alpha:0.2),
                  Colors.blue.withValues(alpha:0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.blue.withValues(alpha:0.3),
                width: 1,
              ),
            ),
            child: IconButton(
              tooltip: 'View Activities',
              icon: const Icon(
                Icons.bolt,
                color: Colors.blue,
                size: 22,
              ),
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
            ),
          ),
        ],
      ),
      body: AppBackgroundWrapper(
  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
  child: (_companyId == null)
      ? const Center(child: CircularProgressIndicator())
      : (_companyId == 'fallback')
          ? const Center(child: Text('Company tidak ditemukan'))
          : StreamBuilder<List<AttendanceDay>>(
              stream: service.streamAttendanceDays(widget.employeeId),
              builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.red.withValues(alpha:0.1),
                        Colors.red.withValues(alpha:0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.red.withValues(alpha:0.2),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha:0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading attendance',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final allDays = (snapshot.data ?? []);
            allDays.sort((a, b) => b.date.compareTo(a.date));

            final periodFilteredDays = _applyPeriodFilter(allDays);
            final summary = AttendanceSummaryHelper.calculateStatusSummary(periodFilteredDays);

            final filtered = periodFilteredDays.where((day) {
              if (_activeStatus != null && day.status != _activeStatus) {
                return false;
              }
              if (_searchQuery.isNotEmpty) {
                final dateStr = '${day.date.day}/${day.date.month}/${day.date.year}';
                return dateStr.contains(_searchQuery);
              }
              return true;
            }).toList();

            filtered.sort((a, b) => b.date.compareTo(a.date));

            if (isDesktop) {
              return _buildDesktopLayout(filtered, summary, allDays);
            } else {
              return _buildMobileLayout(filtered, summary, allDays);
            }
          },
        ),
      ),
    );
  }

  // ================= DESKTOP LAYOUT =================
  Widget _buildDesktopLayout(
    List<AttendanceDay> filtered,
    Map<String, int> summary,
    List<AttendanceDay> allDays,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEFT SIDEBAR - STATS & FILTERS
        Container(
          width: 320,
          margin: const EdgeInsets.only(right: 16),
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildDesktopPeriodFilter(allDays),
                const SizedBox(height: 16),
                _buildDesktopStatsCard(summary),
                const SizedBox(height: 16),
                _buildDesktopOvernightSummary(),
              ],
            ),
          ),
        ),

        // RIGHT CONTENT - ATTENDANCE LIST
        Expanded(
          child: Column(
            children: [
              _buildDesktopActionButtons(),
              const SizedBox(height: 16),
              Expanded(
                child: _buildDesktopAttendanceList(filtered),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopStatsCard(Map<String, int> summary) {
    return _glass(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withValues(alpha:0.2),
                      AppTheme.primaryColor.withValues(alpha:0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.analytics,
                  color: AppTheme.primaryColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Statistics',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${summary.values.reduce((a, b) => a + b)} total',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // STATS GRID
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.2,
            children: [
              _buildStatItem('Present', summary['present'] ?? 0, Colors.green, Icons.check_circle),
              _buildStatItem('Off', summary['off'] ?? 0, Colors.grey, Icons.block),
              _buildStatItem('Sick', summary['sickLeave'] ?? 0, Colors.orange, Icons.sick),
              _buildStatItem('Annual', summary['annualLeave'] ?? 0, Colors.blue, Icons.beach_access),
              _buildStatItem('Travel', summary['traveling'] ?? 0, Colors.purple, Icons.flight),
              _buildStatItem('Holiday', summary['joinHoliday'] ?? 0, Colors.pink, Icons.celebration),
              _buildStatItem('Overtime', summary['overtime'] ?? 0, Colors.red, Icons.access_time),
            ],
          ),

          const Divider(height: 24),

          // STATUS FILTER CHIPS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter by Status',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              if (_activeStatus != null)
                GestureDetector(
                  onTap: () => setState(() => _activeStatus = null),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Clear',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', null, Colors.grey),
                const SizedBox(width: 6),
                _buildFilterChip('Present', AttendanceStatus.present, Colors.green),
                const SizedBox(width: 6),
                _buildFilterChip('Off', AttendanceStatus.off, Colors.grey),
                const SizedBox(width: 6),
                _buildFilterChip('Sick', AttendanceStatus.sickLeave, Colors.orange),
                const SizedBox(width: 6),
                _buildFilterChip('Annual', AttendanceStatus.annualLeave, Colors.blue),
                const SizedBox(width: 6),
                _buildFilterChip('Travel', AttendanceStatus.traveling, Colors.purple),
                const SizedBox(width: 6),
                _buildFilterChip('Holiday', AttendanceStatus.joinHoliday, Colors.pink),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha:0.1),
            color.withValues(alpha:0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha:0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha:0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: Colors.black54),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, AttendanceStatus? status, Color color) {
    final isSelected = _activeStatus == status;
    return InkWell(
      onTap: () => setState(() => _activeStatus = status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    color.withValues(alpha:0.3),
                    color.withValues(alpha:0.2),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? color : Colors.grey.shade600,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopOvernightSummary() {
    return _glass(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple.withValues(alpha:0.2),
                      Colors.purple.withValues(alpha:0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.hotel,
                  color: Colors.purple,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Overnight',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, size: 16, color: Colors.grey),
                onPressed: () => setState(() {}),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          StreamBuilder<Map<String, int>>(
            stream: _overnightSummaryStream(),
            builder: (context, snapshot) {
              final summary = snapshot.data ?? {'domestic': 0, 'overseas': 0};
              final total = summary['domestic']! + summary['overseas']!;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: total > 0 ? summary['domestic']! / total : 0,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildOvernightStat('Domestic', summary['domestic']!, Colors.teal),
                      _buildOvernightStat('Overseas', summary['overseas']!, Colors.purple),
                    ],
                  ),
                  if (total > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Total: $total nights',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddOvernightPage(
                          employeeId: widget.employeeId,
                          period: widget.period,
                        ),
                      ),
                    );
                  },
                  child: const Text('+ Add Overnight'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.purple,
              minimumSize: const Size(double.infinity, 40),
              side: BorderSide(color: Colors.purple.withValues(alpha:0.5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OvernightDetailPage(
                    employeeId: widget.employeeId,
                    period: _isAllPeriod ? 'ALL' : _selectedPeriod,
                  ),
                ),
              );
            },
            child: const Text('View All Overnight'),
          ),
        ],
      ),
    );
  }

  Widget _buildOvernightStat(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha:0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha:0.3),
            Colors.white.withValues(alpha:0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha:0.4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Attendance', style: TextStyle(fontSize: 14)),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                );

                if (picked != null && mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AttendanceInputPage(
                        employeeId: widget.employeeId,
                        date: picked,
                      ),
                    ),
                  );
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: Colors.grey.shade400),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.list, size: 18),
              label: const Text('View All', style: TextStyle(fontSize: 14)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AttendanceListPage(
                      employeeId: widget.employeeId,
                      period: _isAllPeriod ? 'ALL' : _selectedPeriod,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopAttendanceList(List<AttendanceDay> filtered) {
    return _glass(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                const Text(
                  'Attendance Records',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.withValues(alpha:0.2),
                        Colors.blue.withValues(alpha:0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.blue.withValues(alpha:0.3)),
                  ),
                  child: Text(
                    '${filtered.length} records',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // TABLE
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withValues(alpha:0.3),
            ),
            height: 500,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: [
                  // HEADER ROW
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.grey.shade200,
                          Colors.grey.shade100,
                        ],
                      ),
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              const Text('Date / Location', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.info, size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                const Text('Status', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                const Text('Check In/Out', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.note, size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                const Text('Notes', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                      ],
                    ),
                  ),

                  // LIST VIEW
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withValues(alpha:0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.inbox, size: 48, color: Colors.grey.shade400),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No attendance records',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Add a new attendance record to get started',
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              return _buildTableRow(filtered[index]);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(AttendanceDay day) {
    final color = _getStatusColor(day.status);

    String checkInTime = day.checkInHour != null && day.checkInMinute != null
        ? '${day.checkInHour!.toString().padLeft(2, '0')}:${day.checkInMinute!.toString().padLeft(2, '0')}'
        : '';
    String checkOutTime = day.checkOutHour != null && day.checkOutMinute != null
        ? '${day.checkOutHour!.toString().padLeft(2, '0')}:${day.checkOutMinute!.toString().padLeft(2, '0')}'
        : '';

    String locationText = day.location == AttendanceLocation.office ? 'Office' : 'Outstation';
    if (day.customerName != null && day.customerName!.isNotEmpty) {
      locationText += ' • ${day.customerName}';
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AttendanceInputPage(
                employeeId: widget.employeeId,
                date: day.date,
                existingDay: day,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              // Color bar
              Container(
                width: 4,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha:0.5)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),

              // Date/Location
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${day.date.day}/${day.date.month}/${day.date.year}',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        const SizedBox(width: 8),
                        if (isOvertime(day))
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.red.withValues(alpha:0.2), Colors.red.withValues(alpha:0.1)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.withValues(alpha:0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.access_time, size: 10, color: Colors.red.shade700),
                                const SizedBox(width: 2),
                                Text(
                                  'OT',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        StreamBuilder<bool>(
                          stream: _hasActivities(day.date),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data == true) {
                              return Container(
                                margin: const EdgeInsets.only(left: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.blue.withValues(alpha:0.2), Colors.blue.withValues(alpha:0.1)],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.blue.withValues(alpha:0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.bolt, size: 10, color: Colors.blue.shade700),
                                    const SizedBox(width: 2),
                                    Text(
                                      'Activity',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.blue.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          day.location == AttendanceLocation.office ? Icons.business : Icons.location_on,
                          size: 10,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            locationText,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Status
              Expanded(
                flex: 2,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withValues(alpha:0.15), color.withValues(alpha:0.05)],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: color.withValues(alpha:0.3)),
                    ),
                    child: Text(
                      day.status.label,
                      style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),

              // Check In/Out
              Expanded(
                flex: 2,
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (checkInTime.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.green.withValues(alpha:0.15), Colors.green.withValues(alpha:0.05)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.withValues(alpha:0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.login, size: 10, color: Colors.green.shade700),
                              const SizedBox(width: 2),
                              Text(
                                checkInTime,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (checkInTime.isNotEmpty && checkOutTime.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade400,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      if (checkOutTime.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.red.withValues(alpha:0.15), Colors.red.withValues(alpha:0.05)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.withValues(alpha:0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.logout, size: 10, color: Colors.red.shade700),
                              const SizedBox(width: 2),
                              Text(
                                checkOutTime,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (checkInTime.isEmpty && checkOutTime.isEmpty)
                        Text(
                          '-',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                        ),
                    ],
                  ),
                ),
              ),

              // Notes + Activity Button
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        day.note ?? '-',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    StreamBuilder<bool>(
                      stream: _hasActivities(day.date),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data == true) {
                          return Container(
                            margin: const EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha:0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: Icon(Icons.bolt, size: 16, color: Colors.blue.shade700),
                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                              padding: EdgeInsets.zero,
                              onPressed: () => _openActivityDetail(day.date),
                              tooltip: 'View Activities',
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),

              // Arrow
              Container(
                margin: const EdgeInsets.only(left: 8),
                child: Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Colors.green;
      case AttendanceStatus.off:
        return Colors.grey;
      case AttendanceStatus.sickLeave:
        return Colors.orange;
      case AttendanceStatus.annualLeave:
        return Colors.blue;
      case AttendanceStatus.traveling:
        return Colors.purple;
      case AttendanceStatus.joinHoliday:
        return Colors.pink;
    }
  }

  // ================= MOBILE LAYOUT =================
  Widget _buildMobileLayout(
    List<AttendanceDay> filtered,
    Map<String, int> summary,
    List<AttendanceDay> allDays,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Daily Attendance Section
          _glass(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor.withValues(alpha:0.2),
                            AppTheme.primaryColor.withValues(alpha:0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.calendar_month, color: AppTheme.primaryColor, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Daily Attendance',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildMobilePeriodDropdown(allDays),
                const SizedBox(height: 16),
                _StatusChips(
                  summary: summary,
                  active: _activeStatus,
                  onTap: (s) {
                    setState(() {
                      _activeStatus = _activeStatus == s ? null : s;
                    });
                  },
                ),
                const Divider(height: 24),
                if (filtered.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          Icon(Icons.inbox, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'No attendance data',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...filtered.take(3).map((d) => _buildMobileAttendanceCard(d)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Attendance', style: TextStyle(fontSize: 14)),
                        onPressed: () async {
                          final navigator = Navigator.of(context);
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (picked == null) return;
                          if (!mounted) return;
                          navigator.push(
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
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey.shade400),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.list, size: 18),
                        label: const Text('View All', style: TextStyle(fontSize: 14)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AttendanceListPage(
                                employeeId: widget.employeeId,
                                period: _isAllPeriod ? 'ALL' : _selectedPeriod,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Overnight Section
          _glass(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.withValues(alpha:0.2),
                            Colors.purple.withValues(alpha:0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.hotel, color: Colors.purple, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Overnight',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                StreamBuilder<Map<String, int>>(
                  stream: _overnightSummaryStream(),
                  builder: (context, snapshot) {
                    final summary = snapshot.data ?? {'domestic': 0, 'overseas': 0};
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildMobileChip('Domestic', summary['domestic']!, Colors.teal),
                        _buildMobileChip('Overseas', summary['overseas']!, Colors.purple),
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
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'No overnight data',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: data.map((o) {
                        final start = (o['startDate'] as Timestamp).toDate();
                        final end = (o['endDate'] as Timestamp).toDate();
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha:0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.purple,
                                      Colors.purple.withValues(alpha:0.5),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      o['customerName'] ?? '-',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${o['customerCategory']} • ${start.day}/${start.month} → ${end.day}/${end.month} (${o['totalNights']} nights)',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add', style: TextStyle(fontSize: 13)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddOvernightPage(
                                employeeId: widget.employeeId,
                                period: widget.period,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.purple,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: Colors.purple.withValues(alpha:0.5)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('View', style: TextStyle(fontSize: 13)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OvernightDetailPage(
                                employeeId: widget.employeeId,
                                period: _isAllPeriod ? 'ALL' : _selectedPeriod,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Activities Section
          _glass(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.withValues(alpha:0.2),
                            Colors.blue.withValues(alpha:0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.bolt, color: Colors.blue, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Activities',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _activityPreviewStream(),
                  builder: (context, snapshot) {
                    final activities = snapshot.data ?? [];
                    if (activities.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'No activity data',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: activities.map((a) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha:0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blue,
                                      Colors.blue.withValues(alpha:0.5),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      a['activityType'] ?? '-',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${a['factoryClient']} • ${a['machine']}',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.blue.withValues(alpha:0.5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('View All Activities', style: TextStyle(fontSize: 14)),
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
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileAttendanceCard(AttendanceDay day) {
    final color = _getStatusColor(day.status);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AttendanceInputPage(
              employeeId: widget.employeeId,
              date: day.date,
              existingDay: day,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha:0.15),
              Colors.white.withValues(alpha:0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha:0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha:0.5)],
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${day.date.day}/${day.date.month}/${day.date.year}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha:0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          day.status.label,
                          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    day.location == AttendanceLocation.office ? 'Office' : (day.customerName ?? 'Outstation'),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileChip(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha:0.15), color.withValues(alpha:0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha:0.3)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  // Helper functions
  void _filterByDate(DateTime date) {
    setState(() {
      _activeStatus = null;
    });
  }

  void _filterByWeek() {
    setState(() {
      _activeStatus = null;
    });
  }

  void _filterByMonth() {
    setState(() {
      _activeStatus = null;
    });
  }

  Stream<bool> _hasActivities(DateTime date) async* {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final dayRef = CompanyFirestore
        .collection('attendance')
        .doc(widget.employeeId)
        .collection('days')
        .doc(dateStr);

    final factorySnap = await dayRef.collection('factories').get();

    for (final factory in factorySnap.docs) {
      final actSnap = await factory.reference.collection('activities').limit(1).get();
      if (actSnap.docs.isNotEmpty) {
        yield true;
        return;
      }
    }
    yield false;
  }

  void _openActivityDetail(DateTime date) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActivityListPage(
          employeeId: widget.employeeId,
          period: widget.period,
        ),
      ),
    ).then((_) {
      setState(() {});
    });
  }

  List<AttendanceDay> _applyPeriodFilter(List<AttendanceDay> days) {
    if (_isAllPeriod) return days;
    return days.where((day) {
      final period = AttendancePeriodHelper.resolvePeriod(day.date);
      return period == _selectedPeriod;
    }).toList();
  }

  Widget _buildDesktopPeriodFilter(List<AttendanceDay> allDays) {
    final availablePeriods = _extractAvailablePeriods(allDays);

    String? currentValue;
    if (_isAllPeriod) {
      currentValue = 'ALL';
    } else if (availablePeriods.contains(_selectedPeriod)) {
      currentValue = _selectedPeriod;
    } else if (availablePeriods.isNotEmpty) {
      currentValue = availablePeriods.first;
    } else {
      currentValue = 'ALL';
    }

    return _glass(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange.withValues(alpha:0.2),
                      Colors.orange.withValues(alpha:0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.filter_alt, color: Colors.orange, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Period',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha:0.4),
                  Colors.white.withValues(alpha:0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha:0.3),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: currentValue,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                items: [
                  const DropdownMenuItem(
                    value: 'ALL',
                    child: Row(
                      children: [
                        Icon(Icons.all_inclusive, size: 16, color: Colors.grey),
                        SizedBox(width: 8),
                        Text('All Period'),
                      ],
                    ),
                  ),
                  ...availablePeriods.map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Row(
                        children: [
                          Icon(Icons.calendar_month, size: 16, color: AppTheme.primaryColor),
                          SizedBox(width: 8),
                          Text(_formatPeriod(p)),
                        ],
                      ),
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    if (value == 'ALL') {
                      _isAllPeriod = true;
                    } else {
                      _isAllPeriod = false;
                      _selectedPeriod = value;
                    }
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _extractAvailablePeriods(List<AttendanceDay> days) {
    final Set<String> uniquePeriods = {};
    for (final day in days) {
      uniquePeriods.add(AttendancePeriodHelper.resolvePeriod(day.date));
    }
    if (uniquePeriods.isEmpty) {
      uniquePeriods.add(AttendancePeriodHelper.resolvePeriod(DateTime.now()));
    }
    final periods = uniquePeriods.toList();
    periods.sort((a, b) => b.compareTo(a));
    return periods;
  }

  Widget _buildMobilePeriodDropdown(List<AttendanceDay> allDays) {
    final availablePeriods = _extractAvailablePeriods(allDays);

    String? currentValue;
    if (_isAllPeriod) {
      currentValue = 'ALL';
    } else if (availablePeriods.contains(_selectedPeriod)) {
      currentValue = _selectedPeriod;
    } else if (availablePeriods.isNotEmpty) {
      currentValue = availablePeriods.first;
    } else {
      currentValue = 'ALL';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha:0.4),
            Colors.white.withValues(alpha:0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha:0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.calendar_month, size: 16, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: currentValue,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87),
                items: [
                  const DropdownMenuItem(
                    value: 'ALL',
                    child: Text('All Period'),
                  ),
                  ...availablePeriods.map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text(_formatPeriod(p)),
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    if (value == 'ALL') {
                      _isAllPeriod = true;
                    } else {
                      _isAllPeriod = false;
                      _selectedPeriod = value;
                    }
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPeriod(String period) {
    if (period == 'ALL') return 'All Period';
    final parts = period.split('-');
    if (parts.length != 2) return period;
    final year = parts[0];
    final month = int.tryParse(parts[1]) ?? 1;
    const monthNames = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${monthNames[month]} $year';
  }
  Future<void> _loadCompanyId() async {
 final currentUserId = FirebaseAuth.instance.currentUser!.uid;

  final userDoc = await FirebaseFirestore.instance
    .collection('users')
    .doc(currentUserId)
    .get();

  final data = userDoc.data();
  final companyIds = data?['companyIds'];

  String? companyId;

  if (companyIds is List && companyIds.isNotEmpty) {
    companyId = companyIds.first.toString();
  }


  setState(() {
    _companyId = companyId ?? 'fallback';
  });
}

Future<List<ActivityEntry>> _getActivitiesForPeriod() async {
  final List<ActivityEntry> activities = [];

  final daySnap = await CompanyFirestore
      .collection('attendance')
      .doc(widget.employeeId)
      .collection('days')
      .get();

  for (final day in daySnap.docs) {
    final parts = day.id.split('-');
    if (parts.length != 3) continue;

    final date = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );

    final period = AttendancePeriodHelper.resolvePeriod(date);

    if (!_isAllPeriod && period != _selectedPeriod) continue;

    final factorySnap = await day.reference.collection('factories').get();

    for (final factory in factorySnap.docs) {
      final actSnap = await factory.reference
          .collection('activities')
          .orderBy('createdAt', descending: false)
          .get();

      for (final act in actSnap.docs) {
        final data = act.data();

        final activity = ActivityEntry.fromMap(data, date);

        activities.add(activity); // ✅ sekarang benar
      }
    }
  }

  // sorting pakai model
  activities.sort((a, b) => a.date.compareTo(b.date));

  return activities;
}

void _showProgressDialog() {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(value: _progress),
                const SizedBox(height: 16),
                Text(_progressText),
              ],
            ),
          );
        },
      );
    },
  );
}

void _updateProgress(double value, String text) {
  if (!mounted) return;

  setState(() {
    _progress = value;
    _progressText = text;
  });
}

}


// ================= UI HELPERS =================
Widget _glass(Widget child) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha:0.3),
              Colors.white.withValues(alpha:0.15),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha:0.4)),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha:0.15), color.withValues(alpha:0.05)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha:0.4)),
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

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildChip('Present', summary['present'] ?? 0, Colors.green, AttendanceStatus.present),
        _buildChip('Off', summary['off'] ?? 0, Colors.grey, AttendanceStatus.off),
        _buildChip('Sick', summary['sickLeave'] ?? 0, Colors.orange, AttendanceStatus.sickLeave),
        _buildChip('Annual', summary['annualLeave'] ?? 0, Colors.blue, AttendanceStatus.annualLeave),
        _buildChip('Travel', summary['traveling'] ?? 0, Colors.purple, AttendanceStatus.traveling),
        _buildChip('Holiday', summary['joinHoliday'] ?? 0, Colors.pink, AttendanceStatus.joinHoliday),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.withValues(alpha:0.15), Colors.red.withValues(alpha:0.05)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.red.withValues(alpha:0.4)),
          ),
          child: Text(
            'Overtime ${summary['overtime'] ?? 0}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red),
          ),
        ),
      ],
    );
  }

  Widget _buildChip(String label, int value, Color color, AttendanceStatus status) {
    final isSelected = active == status;
    return InkWell(
      onTap: () => onTap(status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [color.withValues(alpha:0.3), color.withValues(alpha:0.2)],
                )
              : LinearGradient(
                  colors: [color.withValues(alpha:0.15), color.withValues(alpha:0.05)],
                ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha:0.3),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          '$label $value',
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? color : color.withValues(alpha:0.9),
          ),
        ),
      ),
    );
  }
}

bool isOvertime(AttendanceDay day) {
  if (day.checkInHour == null || day.checkOutHour == null) return false;

  final checkIn = DateTime(
    day.date.year,
    day.date.month,
    day.date.day,
    day.checkInHour!,
    day.checkInMinute ?? 0,
  );

  final checkOut = DateTime(
    day.date.year,
    day.date.month,
    day.date.day,
    day.checkOutHour!,
    day.checkOutMinute ?? 0,
  );

  final workingHours = checkOut.difference(checkIn).inHours;
  return workingHours > 9;
}