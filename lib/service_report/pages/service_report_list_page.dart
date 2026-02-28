// lib/pages/service_report_list_page.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../pages/service_report_form_page.dart';
import '../services/service_report_firestore.dart';
import '../../models/user_model.dart';
import '../../core/session/company_session.dart';
import '../pages/service_report_detail_page.dart';
import '../../theme/app_theme.dart';
import '../../pages/common/app_background_wrapper.dart';

class ServiceReportListPage extends StatefulWidget {
  
  const ServiceReportListPage({super.key});

  @override
  State<ServiceReportListPage> createState() => _ServiceReportListPageState();
}

class _ServiceReportListPageState extends State<ServiceReportListPage> {
  UserModel? _currentUser;
  bool _isLoadingUser = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String? _activeStatusFilter;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      _currentUser = UserModel(
        uid: 'test-uid',
        name: 'Test User',
        email: 'test@test.com',
        role: 'super_admin',
        position: 'technician',
        companyIds: ['atomIndonesia', 'atomVietnam'],
        active: true,
      );
      _isLoadingUser = false;
    });
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterSuperAdminReports(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    if (_currentUser == null) return snapshot.docs;
    
    return snapshot.docs.where((doc) {
      final companyId = doc.data()['companyId'];
      return _currentUser!.companyIds.contains(companyId);
    }).toList();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterReports(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return docs.where((doc) {
      final data = doc.data();
      
      // Filter berdasarkan search query
      if (_searchQuery.isNotEmpty) {
        final searchLower = _searchQuery.toLowerCase();
        final sheetId = (data['sheetId'] ?? '').toLowerCase();
        final factory = (data['factory'] ?? '').toLowerCase();
        final machine = (data['machine'] ?? '').toLowerCase();
        final technician = (data['technician1'] ?? '').toLowerCase();
        
        final matchesSearch = sheetId.contains(searchLower) ||
            factory.contains(searchLower) ||
            machine.contains(searchLower) ||
            technician.contains(searchLower);
            
        if (!matchesSearch) return false;
      }
      
      // Filter berdasarkan status
      if (_activeStatusFilter != null) {
        final status = data['status'] ?? 'Draft';
        if (status.toLowerCase() != _activeStatusFilter!.toLowerCase()) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }

  String _formatDate(dynamic date) {
    if (date == null) return "-";
    
    if (date is Timestamp) {
      final DateTime dt = date.toDate();
      return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
    }
    
    if (date is DateTime) {
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
    }
    
    return date.toString();
  }

  Map<String, int> _calculateStatusSummary(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    int draft = 0;
    int submitted = 0;
    
    for (var doc in docs) {
      final status = doc.data()['status'] ?? 'Draft';
      if (status.toLowerCase() == 'draft') {
        draft++;
      } else {
        submitted++;
      }
    }
    
    return {'draft': draft, 'submitted': submitted};
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingUser) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
  centerTitle: false,
  titleSpacing: 16,
  backgroundColor: Colors.transparent,
  elevation: 0,

  title: Row(
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.description,
          color: AppTheme.primaryColor,
          size: 22,
        ),
      ),
      const SizedBox(width: 12),

      /// 🔥 FIX UTAMA ADA DI SINI
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Service Reports',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),

            /// Subtitle hanya tampil di DESKTOP
            if (isDesktop)
              if (_currentUser?.role == 'super_admin')
                Text(
                  'Super Admin: Viewing all companies',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                )
              else if (CompanySession.selectedCompanyId != null)
                Text(
                  'Company: ${CompanySession.selectedCompanyId}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
          ],
        ),
      ),
    ],
  ),

  actions: [
    /// SEARCH BAR (DESKTOP ONLY)
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
            hintText: 'Search reports...',
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

    const SizedBox(width: 8),

    /// ADD BUTTON
    Container(
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        tooltip: 'Add Report',
        icon: const Icon(Icons.add, color: Colors.green),
        onPressed: () {
          if (_currentUser!.role != 'super_admin' &&
              CompanySession.selectedCompanyId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select a company first'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ServiceReportFormPage(),
            ),
          );
        },
      ),
    ),
  ],
),
      body: AppBackgroundWrapper(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
  stream: ServiceReportFirestore.streamReports(user: _currentUser!),
  builder: (context, snapshot) {
    if (snapshot.hasError) {
      print('Stream error: ${snapshot.error}'); // Debug
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => setState(() {}),
              child: const Text('Retry'),
                      ),
          ],
        ),
      );
    }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            // Filter berdasarkan role
            final List<QueryDocumentSnapshot<Map<String, dynamic>>> allDocs;
            if (_currentUser!.role == 'super_admin') {
              allDocs = _filterSuperAdminReports(snapshot.data!);
            } else {
              allDocs = snapshot.data!.docs;
            }

            // Apply search and status filters
            final filteredDocs = _filterReports(allDocs);
            final summary = _calculateStatusSummary(allDocs);

            if (isDesktop) {
              return _buildDesktopLayout(filteredDocs, summary, allDocs.length);
            } else {
              return _buildMobileLayout(filteredDocs, summary);
            }
          },
        ),
      ),
    );
  }

  // ================= DESKTOP LAYOUT =================
  Widget _buildDesktopLayout(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> filteredDocs,
    Map<String, int> summary,
    int totalDocs,
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
                _buildDesktopStatsCard(summary, totalDocs),
                const SizedBox(height: 16),
                _buildDesktopFilterCard(),
                const SizedBox(height: 16),
                _buildDesktopInfoCard(),
              ],
            ),
          ),
        ),

        // RIGHT CONTENT - REPORTS LIST
        Expanded(
          child: Column(
            children: [
              _buildDesktopActionButtons(),
              const SizedBox(height: 16),
              Expanded(
                child: _buildDesktopReportsList(filteredDocs),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopStatsCard(Map<String, int> summary, int total) {
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

          // STATS
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2,
            children: [
              _buildStatItem('Total', total, Colors.blue, Icons.description),
              _buildStatItem('Draft', summary['draft'] ?? 0, Colors.orange, Icons.drafts),
              _buildStatItem('Submitted', summary['submitted'] ?? 0, Colors.green, Icons.check_circle),
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
              _buildFilterChip('Draft', 'draft', Colors.orange),
              _buildFilterChip('Submitted', 'submitted', Colors.green),
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

  Widget _buildFilterChip(String label, String? status, Color color) {
    final isSelected = _activeStatusFilter == status;
    return InkWell(
      onTap: () => setState(() => _activeStatusFilter = status),
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
            'This Week',
            Icons.date_range,
            () => _filterByDateRange('week'),
          ),
          _buildQuickFilterTile(
            'This Month',
            Icons.calendar_month,
            () => _filterByDateRange('month'),
          ),
          _buildQuickFilterTile(
            'Last Month',
            Icons.calendar_today,
            () => _filterByDateRange('lastMonth'),
          ),
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

  Widget _buildDesktopInfoCard() {
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
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Colors.purple,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const ListTile(
            dense: true,
            leading: Icon(Icons.circle, size: 8, color: Colors.orange),
            title: Text('Draft: Reports being prepared'),
          ),
          const ListTile(
            dense: true,
            leading: Icon(Icons.circle, size: 8, color: Colors.green),
            title: Text('Submitted: Finalized reports'),
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
              label: const Text('Create Report'),
              onPressed: () {
                if (_currentUser!.role != 'super_admin' && 
                    CompanySession.selectedCompanyId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select a company first'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ServiceReportFormPage(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

 Widget _buildDesktopReportsList(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> filteredDocs,
) {
  return _glass(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              const Text(
                'Reports List',
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
                  '${filteredDocs.length} reports',
                  style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
                ),
              ),
            ],
          ),
        ),

        // TABLE
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white.withOpacity(0.3),
          ),
          height: 500,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Column(
              children: [
                // HEADER ROW
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  color: Colors.grey.shade200,
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      const Expanded(flex: 2, child: Text('Sheet ID', style: TextStyle(fontWeight: FontWeight.w600))),
                      const Expanded(flex: 2, child: Text('Factory / Machine', style: TextStyle(fontWeight: FontWeight.w600))),
                      const Expanded(flex: 2, child: Center(child: Text('Start Date', style: TextStyle(fontWeight: FontWeight.w600)))),
                      const Expanded(flex: 2, child: Center(child: Text('Technician', style: TextStyle(fontWeight: FontWeight.w600)))),
                      const Expanded(flex: 1, child: Center(child: Text('Status', style: TextStyle(fontWeight: FontWeight.w600)))),
                      const SizedBox(width: 24),
                    ],
                  ),
                ),
                
                // LIST VIEW
                Expanded(
                  child: filteredDocs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text('No reports found', style: TextStyle(color: Colors.grey.shade600)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredDocs.length,
                          itemBuilder: (context, index) {
                            final doc = filteredDocs[index];
                            final data = doc.data();

                              print("Report ID: ${doc.id}, Company ID: ${data['companyId']}");
                            
                            // 👇 DEFINISIKAN DI SINI, di dalam itemBuilder
                            String factoryMachine = data['factory'] ?? '-';
                            if (data['machine'] != null && data['machine'].toString().isNotEmpty) {
                              factoryMachine += ' • ${data['machine']}';
                            }
                            
                            return _buildTableRow(doc, factoryMachine); // 👈 KIRIMKAN KE FUNCTION
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

Widget _buildTableRow(
  QueryDocumentSnapshot<Map<String, dynamic>> doc, 
  String factoryMachine, // 👈 TAMBAHKAN PARAMETER INI
) {
  final data = doc.data();
  final status = data['status'] ?? 'Draft';
  final color = status.toLowerCase() == 'draft' ? Colors.orange : Colors.green;

  return Container(
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(color: Colors.grey.shade300),
      ),
    ),
    child: InkWell(
      onTap: () {
        final companyId = data['companyId'];
        if (companyId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Company ID tidak ditemukan dalam data report'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceReportDetailPage(
              reportId: doc.id,
              companyId: companyId,
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
            
            // Sheet ID
            Expanded(
              flex: 2,
              child: Text(
                data['sheetId'] ?? '-',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
            
            // Factory / Machine - GUNAKAN PARAMETER YANG DITERIMA
            Expanded(
              flex: 2,
              child: Text(
                factoryMachine, // 👈 GUNAKAN PARAMETER INI
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            // Start Date
            Expanded(
              flex: 2,
              child: Center(
                child: Text(
                  _formatDate(data['startDate']),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
            
            // Technician
            Expanded(
              flex: 2,
              child: Center(
                child: Text(
                  data['technician1'] ?? '-',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
            
            // Status
            Expanded(
              flex: 1,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
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

  // ================= MOBILE LAYOUT =================
  Widget _buildMobileLayout(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> filteredDocs,
    Map<String, int> summary,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reports Section
          _glass(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Service Reports',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildMobileStatusChips(summary),
                const Divider(height: 24),
                
                // Search Bar (Mobile)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search reports...',
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
                
                if (filteredDocs.isEmpty)
                  const Text(
                    'No reports found',
                    style: TextStyle(color: Colors.black54),
                  ),
                for (final doc in filteredDocs.take(5))
                  _buildMobileReportTile(doc),
                
                if (filteredDocs.length > 5)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Center(
                      child: Text(
                        '${filteredDocs.length - 5} more reports...',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ),
                  ),
                  
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Create Report'),
                    onPressed: () {
                      if (_currentUser!.role != 'super_admin' && 
                          CompanySession.selectedCompanyId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select a company first'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }
                      
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ServiceReportFormPage(),
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

  Widget _buildMobileStatusChips(Map<String, int> summary) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        _buildMobileChip(
          'All Reports',
          summary['draft']! + summary['submitted']!,
          Colors.blue,
          null,
        ),
        _buildMobileChip(
          'Draft',
          summary['draft'] ?? 0,
          Colors.orange,
          'draft',
        ),
        _buildMobileChip(
          'Submitted',
          summary['submitted'] ?? 0,
          Colors.green,
          'submitted',
        ),
      ],
    );
  }

  Widget _buildMobileChip(String label, int value, Color color, String? status) {
    final isSelected = _activeStatusFilter == status;
    return InkWell(
      onTap: () => setState(() {
        _activeStatusFilter = _activeStatusFilter == status ? null : status;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(isSelected ? 0.25 : 0.15),
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

  Widget _buildMobileReportTile(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
  final data = doc.data();
  final status = data['status'] ?? 'Draft';
  final color = status.toLowerCase() == 'draft' ? Colors.orange : Colors.green;

  return Card(
    margin: const EdgeInsets.only(bottom: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: ListTile(
        leading: Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        title: Text(
          data['sheetId'] ?? '-',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${data['factory'] ?? '-'} • ${data['machine'] ?? '-'}'),
            Text('Start: ${_formatDate(data['startDate'])}'),
            Text('Tech: ${data['technician1'] ?? '-'}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
        onTap: () {
        final companyId = data['companyId']; // AMBIL DARI DATA
        if (companyId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Company ID tidak ditemukan'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        print("Navigating to detail - Report ID: ${doc.id}, Company ID: $companyId");

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceReportDetailPage(
              reportId: doc.id,
              companyId: companyId,
            ),
          ),
        );
      },
    ),
  );
}

  // Helper functions
  void _filterByDateRange(String range) {
    // Implementasi filter by date range
    setState(() {
      _activeStatusFilter = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Filtering by $range')),
    );
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