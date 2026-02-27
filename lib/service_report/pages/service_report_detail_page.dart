// lib/pages/service_report_detail_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/service_report_firestore.dart';
import '../../core/session/company_session.dart';
import 'service_report_form_page.dart';
import '../../config/cloudinary_config.dart';

class ServiceReportDetailPage extends StatefulWidget {
  final String reportId;
  
  const ServiceReportDetailPage({super.key, required this.reportId});

  @override
  State<ServiceReportDetailPage> createState() => _ServiceReportDetailPageState();
}

class _ServiceReportDetailPageState extends State<ServiceReportDetailPage> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  DocumentSnapshot<Map<String, dynamic>>? _reportDoc;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final doc = await ServiceReportFirestore.getReport(widget.reportId);
      
      if (!mounted) return;
      
      setState(() {
        _reportDoc = doc;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _submitReport() async {
    // Konfirmasi
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Submit Service Report"),
        content: const Text(
          "After submission, this report cannot be edited. "
          "Are you sure you want to submit?"
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            child: const Text("SUBMIT"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ServiceReportFirestore.submitServiceReport(widget.reportId);
      
      if (!mounted) return;
      
      // Reload data
      await _loadReport();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Service Report submitted successfully"),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error submitting: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _editReport() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ServiceReportFormPage(
          reportId: widget.reportId,
        ),
      ),
    );
    
    // Jika kembali dari edit, reload data
    if (result == true) {
      _loadReport();
    }
  }

  void _playVideo(BuildContext context, String url) {
  // TODO: Implement video player
  // Sementara pakai snackbar
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("Video player akan diimplementasikan")),
  );
}

  String _formatDate(dynamic date) {
    if (date == null) return "-";
    
    if (date is Timestamp) {
      final DateTime dt = date.toDate();
      return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
    }
    
    return date.toString();
  }

  String _formatDateTime(dynamic date) {
    if (date == null) return "-";
    
    if (date is Timestamp) {
      final DateTime dt = date.toDate();
      return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    }
    
    return date.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Service Report Detail"),
        actions: [
          if (_reportDoc != null && _reportDoc!.data()?['status'] == 'Draft' && !_isSubmitting)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editReport,
              tooltip: "Edit Report",
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadReport,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_reportDoc == null || !_reportDoc!.exists) {
      return const Center(
        child: Text("Report not found"),
      );
    }

    final data = _reportDoc!.data()!;
    final status = data['status'] ?? 'Draft';
    final isDraft = status == 'Draft';

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Status Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDraft ? Colors.orange.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDraft ? Colors.orange : Colors.green,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isDraft ? Icons.drafts : Icons.check_circle,
                      color: isDraft ? Colors.orange : Colors.green,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Status: $status",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDraft ? Colors.orange : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),

              // Sheet ID Card
              _infoCard(
                title: "SHEET ID",
                child: Text(
                  data['sheetId'] ?? '-',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // BASIC INFO
              _infoCard(
                title: "BASIC INFORMATION",
                child: Column(
                  children: [
                    _infoRow("Start Date", _formatDate(data['startDate'])),
                    _infoRow("End Date", _formatDate(data['endDate'])),
                    _infoRow("Factory", data['factory'] ?? '-'),
                    _infoRow("End Customer", data['endCustomer'] ?? '-'),
                    _infoRow("Customer Code", data['customerCode'] ?? '-'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // MACHINE INFO
              _infoCard(
                title: "MACHINE INFORMATION",
                child: Column(
                  children: [
                    _infoRow("Machine", data['machine'] ?? '-'),
                    _infoRow("Serial Number", data['serialNumber'] ?? '-'),
                    _infoRow("Asset Number", data['assetNumber'] ?? '-'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // DESCRIPTION
              _infoCard(
                title: "PROBLEM DESCRIPTION",
                child: Text(data['problemDescription'] ?? '-'),
              ),
              const SizedBox(height: 20),

              _infoCard(
                title: "ACTIVITY",
                child: Text(data['activity'] ?? '-'),
              ),
              const SizedBox(height: 20),

              // NOTE
              if (data['noteForCustomer'] != null && data['noteForCustomer'].toString().isNotEmpty)
                _infoCard(
                  title: "NOTE FOR CUSTOMER",
                  child: Text(data['noteForCustomer']),
                ),
              if (data['noteForCustomer'] != null && data['noteForCustomer'].toString().isNotEmpty)
                const SizedBox(height: 20),

              // TECHNICIANS
              _infoCard(
                title: "TECHNICIANS",
                child: Column(
                  children: [
                    _infoRow("Technician 1", data['technician1'] ?? '-'),
                    if (data['technician2'] != null)
                      _infoRow("Technician 2", data['technician2']),
                    if (data['technician3'] != null)
                      _infoRow("Technician 3", data['technician3']),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // CUSTOMER
              _infoCard(
                title: "CUSTOMER",
                child: _infoRow("Customer Name", data['customerName'] ?? '-'),
              ),
              const SizedBox(height: 20),

              // SPARE PARTS
              if (data['spareParts'] != null && (data['spareParts'] as List).isNotEmpty)
                _infoCard(
                  title: "SPARE PARTS",
                  child: Column(
                    children: (data['spareParts'] as List).map((part) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(child: Text(part['name'] ?? '-')),
                            Text("Qty: ${part['qty'] ?? '1'}"),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              if (data['spareParts'] != null && (data['spareParts'] as List).isNotEmpty)
                const SizedBox(height: 20),

              // SIGNATURE (placeholder)
              _infoCard(
  title: "CUSTOMER SIGNATURE",
  child: Container(
    height: 150,
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(8),
    ),
    child: data['signature'] != null
        ? Image.network(
             data['signature'],
            fit: BoxFit.contain,
          )
        : const Center(
            child: Text("No signature"),
          ),
  ),
),
              const SizedBox(height: 20),

              // MEDIA (placeholder)
              _infoCard(
  title: "MEDIA",
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (data['photo1'] != null) ...[
        const Text("Photo 1", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Image.network(
          data['photo1'] ?? '',
          height: 200,
          fit: BoxFit.cover,
        ),
        const SizedBox(height: 16),
      ],
      if (data['photo2'] != null) ...[
        const Text("Photo 2", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Image.network(
          data['photo2'] ?? '',
          height: 200,
          fit: BoxFit.cover,
        ),
        const SizedBox(height: 16),
      ],
      if (data['photo3'] != null) ...[
        const Text("Photo 3", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Image.network(
          data['photo3'] ?? '',
          height: 200,
          fit: BoxFit.cover,
        ),
        const SizedBox(height: 16),
      ],
      if (data['video'] != null) ...[
        const Text("Video", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          height: 200,
          color: Colors.black,
          child: Center(
            child: TextButton.icon(
              onPressed: () {
                // Bisa dibuka dengan video player
               _playVideo(context, data['video']);
              },
              icon: const Icon(Icons.play_circle_filled, color: Colors.white),
              label: const Text("Play Video", style: TextStyle(color: Colors.white)),
            ),
          ),
        ),
      ],
      if (data['photo1'] == null && 
          data['photo2'] == null && 
          data['photo3'] == null && 
          data['video'] == null)
        const Center(child: Text("No media")),
    ],
  ),
),
              const SizedBox(height: 20),

              // METADATA
              _infoCard(
                title: "SYSTEM INFORMATION",
                child: Column(
                  children: [
                    _infoRow("Created At", _formatDateTime(data['createdAt'])),
                    _infoRow("Created By", data['createdBy'] ?? '-'),
                    if (data['submittedAt'] != null)
                      _infoRow("Submitted At", _formatDateTime(data['submittedAt'])),
                    if (data['submittedBy'] != null)
                      _infoRow("Submitted By", data['submittedBy']),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // ACTION BUTTONS
              if (isDraft && !_isSubmitting)
                Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: _editReport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("Edit Draft"),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _submitReport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("Submit Report"),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (_isSubmitting)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  Widget _infoCard({required String title, required Widget child}) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}