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

  @override
void initState() {
  super.initState();
  _selectedPeriod = widget.period;
  _isAllPeriod = false;
}

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

Future<void> _exportAttendanceToPdf() async {
  try {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final service = AttendanceService();

    List<AttendanceDay> days = [];
    await for (var snapshot in service.streamAttendanceDays(widget.employeeId)) {
      days = snapshot;
      break;
    }

    // 🔥 APPLY PERIOD FILTER
    final filteredDays = _applyPeriodFilter(days);

    // 🔥 PERIOD YANG DIPILIH USER
    final period = _isAllPeriod ? 'ALL' : _selectedPeriod;

    // 🔥 SUMMARY DARI DATA YANG SUDAH DIFILTER
    final summary = await AttendanceSummaryCalculator.calculate(
  employeeId: widget.employeeId,
  period: _isAllPeriod ? 'ALL' : _selectedPeriod,
);

    if (mounted) Navigator.pop(context);

    final bytes = await PdfReportService.generatePdf(
      employeeId: widget.employeeId,
      employeeName: 'Employee ${widget.employeeId}',
      period: period,
      attendanceDays: filteredDays,
      summary: summary,
    );

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

      final dateParts = day.id.split('-');
      if (dateParts.length != 3) continue;

      final year = dateParts[0];
      final month = dateParts[1];

      final period = '$year-$month';

      if (!_isAllPeriod && period != _selectedPeriod) continue;

      final factorySnap = await day.reference.collection('factories').get();

      for (final factory in factorySnap.docs) {

        final actSnap = await factory.reference
            .collection('activities')
            .orderBy('createdAt', descending: true)
            .get();

        for (final a in actSnap.docs) {
          activities.add(a.data());
        }

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
  centerTitle: false, // 🔥 penting untuk mobile
  backgroundColor: Colors.transparent,
  elevation: 0,

  title: Row(
    mainAxisSize: MainAxisSize.min, // 🔥 jangan max
    children: [
      Container(
        padding: const EdgeInsets.all(6), // sedikit kecil biar aman
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.calendar_month,
          color: AppTheme.primaryColor,
          size: 20, // 🔥 kecilkan sedikit
        ),
      ),

      const SizedBox(width: 8),

      Flexible( // 🔥 WAJIB
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Attendance',
              style: TextStyle(
                fontSize: 18, // 🔥 kecilkan sedikit
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            Text(
              widget.period,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
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
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
          ),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: InputDecoration(
            hintText: 'Search attendance...',
            hintStyle: TextStyle(color: Colors.grey.shade600),
            prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ),

    IconButton(
      tooltip: 'Export to PDF',
      icon: const Icon(Icons.picture_as_pdf, color: Colors.green),
      onPressed: _exportAttendanceToPdf,
    ),

    IconButton(
      tooltip: 'Summary',
      icon: Icon(
        Icons.bar_chart,
        color: AppTheme.primaryColor,
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

    IconButton(
      tooltip: 'View Activities',
      icon: const Icon(
        Icons.bolt,
        color: Colors.blue,
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
  ],
),
      body: AppBackgroundWrapper(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: StreamBuilder<List<AttendanceDay>>(
          stream: service.streamAttendanceDays(widget.employeeId),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text(
                        'Error loading attendance',
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ],
                  ),
                ),
              );
            }

            final allDays = (snapshot.data ?? []);
            print("EMPLOYEE ID = ${widget.employeeId}");
print("ATTENDANCE COUNT = ${allDays.length}");
allDays.sort((a, b) => b.date.compareTo(a.date));

// 🔥 APPLY PERIOD FILTER DI SINI
final periodFilteredDays = _applyPeriodFilter(allDays);

// 🔥 SUMMARY BERDASARKAN PERIOD
final summary =
    AttendanceSummaryHelper.calculateStatusSummary(periodFilteredDays);

// 🔥 STATUS + SEARCH FILTER
final filtered = periodFilteredDays.where((day) {
  if (_activeStatus != null && day.status != _activeStatus) {
    return false;
  }
  if (_searchQuery.isNotEmpty) {
    final dateStr =
        '${day.date.day}/${day.date.month}/${day.date.year}';
    return dateStr.contains(_searchQuery);
  }
  return true;
}).toList();

            // DESKTOP LAYOUT
            if (isDesktop) {
  return _buildDesktopLayout(
    filtered,
    summary,
    allDays,
  );
} else {
              return _buildMobileLayout(
  filtered,
  summary,
  allDays,
);
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
        width: 300,
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
              child: _buildDesktopAttendanceList(filtered), // PASTIKAN Expanded DI SINI
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
      mainAxisSize: MainAxisSize.min, // TAMBAHKAN INI
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
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
          ],
        ),
        const SizedBox(height: 16),

        // STATS GRID
        GridView.count(
          shrinkWrap: true, // PENTING!
          physics: const NeverScrollableScrollPhysics(), // PENTING!
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2,
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
        const Text(
          'Filter by Status',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _buildFilterChip('All', null, Colors.grey),
            _buildFilterChip('Present', AttendanceStatus.present, Colors.green),
            _buildFilterChip('Off', AttendanceStatus.off, Colors.grey),
            _buildFilterChip('Sick', AttendanceStatus.sickLeave, Colors.orange),
            _buildFilterChip('Annual', AttendanceStatus.annualLeave, Colors.blue),
            _buildFilterChip('Travel', AttendanceStatus.traveling, Colors.purple),
            _buildFilterChip('Holiday', AttendanceStatus.joinHoliday, Colors.pink),
          ],
        ),
      ],
    ),
  );
}

  Widget _buildStatItem(String label, int value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 10),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isSelected ? color : Colors.grey.shade600,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopFilterCard() {
    return _glass(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.filter_list,
                  color: Colors.blue,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Quick Filters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildQuickFilterTile(
            'Today',
            Icons.today,
            () => _filterByDate(DateTime.now()),
          ),
          _buildQuickFilterTile(
            'This Week',
            Icons.date_range,
            () => _filterByWeek(),
          ),
          _buildQuickFilterTile(
            'This Month',
            Icons.calendar_month,
            () => _filterByMonth(),
          ),
          const SizedBox(height: 16),
const Divider(),
const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildQuickFilterTile(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }

 Widget _buildDesktopOvernightSummary() {
  return _glass(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // TAMBAHKAN INI
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
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
          ],
        ),
        const SizedBox(height: 12),

        StreamBuilder<Map<String, int>>(
          stream: _overnightSummaryStream(),
          builder: (context, snapshot) {
            final summary = snapshot.data ?? {'domestic': 0, 'overseas': 0};

            return Column(
              mainAxisSize: MainAxisSize.min, // TAMBAHKAN INI
              children: [
                LinearProgressIndicator(
                  value: summary['domestic']! + summary['overseas']! > 0
                      ? summary['domestic']! / (summary['domestic']! + summary['overseas']!)
                      : 0,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildOvernightStat('Domestic', summary['domestic']!, Colors.teal),
                    _buildOvernightStat('Overseas', summary['overseas']!, Colors.purple),
                  ],
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),

        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple.shade50,
            foregroundColor: Colors.purple,
            minimumSize: const Size(double.infinity, 36),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Add Overnight'),
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
        const SizedBox(height: 8),

ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.blueGrey.shade100,
    foregroundColor: Colors.black87,
    minimumSize: const Size(double.infinity, 36),
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
  child: const Text('View Overnight'),
),
      ],
    ),
  );
}

  Widget _buildOvernightStat(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
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
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopActionButtons() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add Attendance'),
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
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey.shade100,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.list),
              label: const Text('View All'),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${filtered.length} records',
                  style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
                ),
              ),
            ],
          ),
        ),

        // TABLE - BUNGKUS DENGAN CONTAINER YANG MEMILIKI TINGGI MAKSIMUM
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white.withOpacity(0.3),
          ),
          height: 500, // Tentukan tinggi maksimum
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Column(
              children: [
                // HEADER ROW (FIXED)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  color: Colors.grey.shade200,
                  child: Row(
                    children: [
                      const SizedBox(width: 12), // Untuk color bar
                      const Expanded(flex: 2, child: Text('Date / Location', style: TextStyle(fontWeight: FontWeight.w600))),
                      const Expanded(flex: 2, child: Center(child: Text('Status', style: TextStyle(fontWeight: FontWeight.w600)))),
                      const Expanded(flex: 2, child: Center(child: Text('Check In/Out', style: TextStyle(fontWeight: FontWeight.w600)))),
                      const Expanded(flex: 2, child: Center(child: Text('Notes', style: TextStyle(fontWeight: FontWeight.w600)))),
                      const SizedBox(width: 24),
                    ],
                  ),
                ),
                
                // LIST VIEW UNTUK SCROLL (Expanded)
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text('No attendance records', style: TextStyle(color: Colors.grey.shade600)),
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
  
  // Format jam
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
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            
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
          margin: const EdgeInsets.only(left: 4, right: 2),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.access_time,
                size: 10,
                color: Colors.red.shade700,
              ),
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
        
                      // INDICATOR ACTIVITY
                      StreamBuilder<bool>(
                        stream: _hasActivities(day.date),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data == true) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.bolt,
                                    size: 10,
                                    color: Colors.blue.shade700,
                                  ),
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
                  const SizedBox(height: 2),
                  Text(
                    locationText,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Status
            Expanded(
              flex: 2,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
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
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          checkInTime,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (checkInTime.isNotEmpty && checkOutTime.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          '•',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                    if (checkOutTime.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          checkOutTime,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (checkInTime.isEmpty && checkOutTime.isEmpty)
                      Text(
                        '-',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade400,
                        ),
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
                  // Notes
                  Expanded(
                    child: Text(
                      day.note ?? '-',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  // Activity Button
                  StreamBuilder<bool>(
                    stream: _hasActivities(day.date),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data == true) {
                        return Container(
                          margin: const EdgeInsets.only(left: 4),
                          child: IconButton(
                            icon: Icon(
                              Icons.bolt,
                              size: 16,
                              color: Colors.blue.shade700,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 24,
                              minHeight: 24,
                            ),
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              _openActivityDetail(day.date);
                            },
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
            const SizedBox(width: 24),
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

  // ================= MOBILE LAYOUT (TETAP SAMA) =================
  Widget _buildMobileLayout(List<AttendanceDay> 
  filtered, Map<String, int> summary,List<AttendanceDay> allDays,) {
    // ... (Kode mobile layout tetap sama seperti sebelumnya)
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Daily Attendance Section
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
                const SizedBox(height: 8),
_buildMobilePeriodDropdown(allDays),
                const SizedBox(height: 12),
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
                  const Text(
                    'No attendance data',
                    style: TextStyle(color: Colors.black54),
                  ),
                for (final d in filtered.take(3))
                  ListTile(
                    dense: true,
                    title: Text('${d.date.day}/${d.date.month}/${d.date.year}'),
                    subtitle: Text(d.status.label),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AttendanceInputPage(
                            employeeId: widget.employeeId,
                            date: d.date,
                            existingDay: d,
                          ),
                        ),
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
                        label: const Text('Add Attendance'),
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
                                period: _isAllPeriod ? 'ALL' : _selectedPeriod,
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

          // Overnight Section
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
                StreamBuilder<Map<String, int>>(
                  stream: _overnightSummaryStream(),
                  builder: (context, snapshot) {
                    final summary = snapshot.data ?? {'domestic': 0, 'overseas': 0};
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
                                period: widget.period,
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
                                period: _isAllPeriod ? 'ALL' : _selectedPeriod,
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

          // Activities Section
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
                          trailing: const Icon(Icons.chevron_right, size: 18),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 12),
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
  }

  // Helper functions
  void _filterByDate(DateTime date) {
    // Implementasi filter by date
    setState(() {
      _activeStatus = null;
      // Filter logic akan di-handle oleh stream
    });
  }

  void _filterByWeek() {
    // Implementasi filter by week
    setState(() {
      _activeStatus = null;
    });
  }

  void _filterByMonth() {
    // Implementasi filter by month
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

    final actSnap =
        await factory.reference.collection('activities').limit(1).get();

    if (actSnap.docs.isNotEmpty) {
      yield true;
      return;
    }
  }

  yield false;
}
void _openActivityDetail(DateTime date) {
  // Navigasi ke ActivityListPage dan setelah kembali, refresh jika perlu
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ActivityListPage(
        employeeId: widget.employeeId,
        period: widget.period,
      ),
    ),
  ).then((_) {
    // Optional: refresh data setelah kembali
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
  print("ALL DAYS COUNT = ${allDays.length}");
print("AVAILABLE PERIODS = $availablePeriods");
print("SELECTED PERIOD = $_selectedPeriod");

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
        const Text(
          'Period',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentValue,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
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

List<String> _extractAvailablePeriods(List<AttendanceDay> days) {
  final Set<String> uniquePeriods = {};

  for (final day in days) {
    uniquePeriods.add(
      AttendancePeriodHelper.resolvePeriod(day.date),
    );
  }

  // jika tidak ada attendance, pakai period sekarang
  if (uniquePeriods.isEmpty) {
    uniquePeriods.add(
      AttendancePeriodHelper.resolvePeriod(DateTime.now()),
    );
  }

  final periods = uniquePeriods.toList();
  periods.sort((a, b) => b.compareTo(a));

  return periods;
}

Widget _buildMobilePeriodDropdown(List<AttendanceDay> allDays) {
  final availablePeriods = _extractAvailablePeriods(allDays);
  print("AVAILABLE PERIODS = $availablePeriods");
print("IS ALL PERIOD = $_isAllPeriod");
print("SELECTED PERIOD = $_selectedPeriod");

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
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.9),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: AppTheme.primaryColor.withOpacity(0.3),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.calendar_month,
            size: 18,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 12),

        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentValue,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
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
          color: Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.4)),
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
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4)),
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
            color: Colors.red.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.red.withOpacity(0.45)),
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

  Widget _chip(String label, int value, Color color, AttendanceStatus status) {
    return InkWell(
      onTap: () => onTap(status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(active == status ? 0.25 : 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.45)),
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
}