import 'package:flutter/material.dart';
import '../pages/service_report_form_page.dart';
import '../services/service_report_firestore.dart';

class ServiceReportListPage extends StatelessWidget {
  const ServiceReportListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final reports = [
      {
        "sheetId": "SR-2026-001",
        "factory": "PT. ORISOL",
        "machine": "31B All in One",
        "start": "02/04/2026",
        "tech": "Basuki",
        "status": "Draft",
      },
      {
        "sheetId": "SR-2026-002",
        "factory": "PT. POUCHEN",
        "machine": "Cutting Pro X",
        "start": "05/04/2026",
        "tech": "Agus",
        "status": "Submitted",
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Service Reports"),
      ),
      body: StreamBuilder(
  stream: ServiceReportFirestore.streamReports(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    final docs = snapshot.data!.docs;

    if (docs.isEmpty) {
      return const Center(child: Text("No Service Reports"));
    }

    return _desktopFirestoreLayout(context, docs);
  },
),
      floatingActionButton: FloatingActionButton(
  onPressed: () {
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

  // ================= DESKTOP =================

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
                      Navigator.pushNamed(
                          context, '/service-report-detail');
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

  // ================= MOBILE =================

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

  Widget _statusBadge(String status) {
    final color =
        status == "Draft" ? Colors.orange : Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
            color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
  Widget _desktopFirestoreLayout(
    BuildContext context, List docs) {
  return Padding(
    padding: const EdgeInsets.all(24),
    child: Card(
      child: DataTable(
        columns: const [
          DataColumn(label: Text("Machine")),
          DataColumn(label: Text("Factory")),
          DataColumn(label: Text("Status")),
        ],
        rows: docs.map((doc) {
          final data = doc.data();
          return DataRow(cells: [
            DataCell(Text(data["sheetId"] ?? "-")),
          ]);
        }).toList(),
      ),
    ),
  );
}
}