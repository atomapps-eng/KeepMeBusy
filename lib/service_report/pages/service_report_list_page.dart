// lib/pages/service_report_list_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../pages/service_report_form_page.dart';
import '../services/service_report_firestore.dart';
import '../../models/user_model.dart';
import '../../core/session/company_session.dart';
import '../pages/service_report_detail_page.dart';

class ServiceReportListPage extends StatefulWidget {
  const ServiceReportListPage({super.key});

  @override
  State<ServiceReportListPage> createState() => _ServiceReportListPageState();
}

class _ServiceReportListPageState extends State<ServiceReportListPage> {
  UserModel? _currentUser;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    // TODO: Implementasi auth service untuk get current user
    // Sementara pakai dummy untuk testing
    await Future.delayed(const Duration(milliseconds: 500)); // Simulasi loading
    
    setState(() {
      _currentUser = UserModel(
        uid: 'test-uid',
        name: 'Test User',
        email: 'test@test.com',
        role: 'super_admin', // Ganti untuk testing: 'super_admin', 'admin', 'user'
        position: 'technician',
        companyIds: ['atomIndonesia', 'atomVietnam'], // Company yang bisa diakses
        active: true,
      );
      _isLoadingUser = false;
    });
  }

  // Filter hasil di client-side untuk super_admin
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterSuperAdminReports(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    if (_currentUser == null) return snapshot.docs;
    
    return snapshot.docs.where((doc) {
      // Path: companies/{companyId}/service_reports/{docId}
      final companyId = doc.reference.parent.parent!.id;
      return _currentUser!.companyIds.contains(companyId);
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

  @override
  Widget build(BuildContext context) {
    if (_isLoadingUser) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Service Reports"),
        actions: [
          if (_currentUser?.role == 'super_admin')
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Text(
                  'Super Admin: Viewing all companies',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: ServiceReportFirestore.streamReports(user: _currentUser!),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {}); // Refresh
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // Untuk super_admin, filter hasil di client
          final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
          if (_currentUser!.role == 'super_admin') {
            docs = _filterSuperAdminReports(snapshot.data!);
          } else {
            docs = snapshot.data!.docs;
          }

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Service Reports',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_currentUser?.role != 'super_admin')
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Selected company: ${CompanySession.selectedCompanyId ?? 'None'}',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ),
                ],
              ),
            );
          }

          // Gunakan layout yang sudah ada
          return _desktopFirestoreLayout(context, docs);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Cek apakah company terpilih (untuk admin/user)
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
        child: const Icon(Icons.add),
      ),
    );
  }

  // Desktop layout dengan Firestore data
  Widget _desktopFirestoreLayout(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: DataTable(
            columns: const [
              DataColumn(label: Text("Sheet ID")),
              DataColumn(label: Text("Factory")),
              DataColumn(label: Text("Machine")),
              DataColumn(label: Text("Start Date")),
              DataColumn(label: Text("Tech 1")),
              DataColumn(label: Text("Status")),
              DataColumn(label: Text("Action")),
            ],
            rows: docs.map((doc) {
              final data = doc.data();
              return DataRow(cells: [
                DataCell(Text(data["sheetId"] ?? "-")),
                DataCell(Text(data["factory"] ?? "-")),
                DataCell(Text(data["machine"] ?? "-")),
                DataCell(Text(_formatDate(data["startDate"]))),
                DataCell(Text(data["technician1"] ?? "-")),
                DataCell(_statusBadge(data["status"] ?? "Draft")),
                DataCell(
                  // Di service_report_list_page.dart, bagian IconButton:

IconButton(
  icon: const Icon(Icons.visibility),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceReportDetailPage(
          reportId: doc.id,
        ),
      ),
    );
  },
),
                ),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final color = status.toLowerCase() == "draft" 
        ? Colors.orange 
        : Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
  
  // Method _desktopLayout untuk dummy data
Widget _desktopLayout(BuildContext context, List reports) {
  return Padding(
    padding: const EdgeInsets.all(24),
    child: Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: DataTable(
          columns: const [
            DataColumn(label: Text("Sheet ID")),
            DataColumn(label: Text("Factory")),
            DataColumn(label: Text("Machine")),
            DataColumn(label: Text("Start Date")),
            DataColumn(label: Text("Tech 1")),
            DataColumn(label: Text("Status")),
            DataColumn(label: Text("Action")),
          ],
          rows: reports.map((report) {
            return DataRow(cells: [
              DataCell(Text(report["sheetId"])),
              DataCell(Text(report["factory"])),
              DataCell(Text(report["machine"])),
              DataCell(Text(report["start"])),
              DataCell(Text(report["tech"])),
              DataCell(_statusBadge(report["status"])),
              DataCell(
                IconButton(
                  icon: const Icon(Icons.visibility),
                  onPressed: () {
                    // Untuk dummy data, kita tidak punya reportId
                    // Jadi sementara pakai snackbar
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Detail page untuk dummy data"),
                      ),
                    );
                  },
                ),
              ),
            ]);
          }).toList(),
        ),
      ),
    ),
  );
}

  Widget _mobileLayout(BuildContext context, List reports) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final report = reports[index];

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report["sheetId"],
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text("Factory: ${report["factory"]}"),
                Text("Machine: ${report["machine"]}"),
                Text("Start: ${report["start"]}"),
                Text("Tech: ${report["tech"]}"),
                const SizedBox(height: 8),
                _statusBadge(report["status"]),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(
                          context, '/service-report-detail');
                    },
                    child: const Text("View"),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}