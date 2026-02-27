// lib/pages/service_report_detail_page.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/service_report_firestore.dart';
import '../../core/session/company_session.dart';
import 'service_report_form_page.dart';
import '../../config/cloudinary_config.dart';
import '../../theme/app_theme.dart';
import '../../pages/common/app_background_wrapper.dart';

class ServiceReportDetailPage extends StatefulWidget {
  final String reportId;
  final String companyId;
  
  const ServiceReportDetailPage({
  super.key,
  required this.reportId,
  required this.companyId,
});

  @override
  State<ServiceReportDetailPage> createState() => _ServiceReportDetailPageState();
}

class _ServiceReportDetailPageState extends State<ServiceReportDetailPage> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  DocumentSnapshot<Map<String, dynamic>>? _reportDoc;
  String? _error;
  bool _isDesktop = false;

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
      final doc = await ServiceReportFirestore.getReport(
  companyId: widget.companyId,
  docId: widget.reportId,
);
      
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
      await ServiceReportFirestore.submitServiceReport(
  companyId: widget.companyId,
  docId: widget.reportId,
);
      
      if (!mounted) return;
      
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
    
    if (result == true) {
      _loadReport();
    }
  }

  void _playVideo(BuildContext context, String url) {
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
    _isDesktop = MediaQuery.of(context).size.width >= 900;

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
                Icons.description,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Service Report Detail',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_reportDoc != null && _reportDoc!.data()?['status'] == 'Draft' && !_isSubmitting)
            Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: _editReport,
                tooltip: "Edit Report",
              ),
            ),
        ],
      ),
      body: AppBackgroundWrapper(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
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
                'Error: $_error',
                style: TextStyle(color: Colors.red.shade700),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_reportDoc == null || !_reportDoc!.exists) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox, size: 48, color: Colors.orange.shade700),
              const SizedBox(height: 12),
              Text(
                'Report not found',
                style: TextStyle(color: Colors.orange.shade700),
              ),
            ],
          ),
        ),
      );
    }

    final data = _reportDoc!.data()!;
    final status = data['status'] ?? 'Draft';
    final isDraft = status == 'Draft';

    if (_isDesktop) {
      return _buildDesktopLayout(data, status, isDraft);
    } else {
      return _buildMobileLayout(data, status, isDraft);
    }
  }

  // ================= DESKTOP LAYOUT =================
  Widget _buildDesktopLayout(Map<String, dynamic> data, String status, bool isDraft) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEFT SIDEBAR - REPORT METADATA
        Container(
          width: 300,
          margin: const EdgeInsets.only(right: 16),
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildDesktopStatusCard(data, status, isDraft),
                const SizedBox(height: 16),
                _buildDesktopInfoCard(data),
                const SizedBox(height: 16),
                _buildDesktopSystemInfoCard(data),
              ],
            ),
          ),
        ),

        // RIGHT CONTENT - REPORT DETAILS
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildDesktopHeaderCard(data),
                const SizedBox(height: 16),
                _buildDesktopContentCards(data),
                if (isDraft && !_isSubmitting) ...[
                  const SizedBox(height: 16),
                  _buildDesktopActionButtons(),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopStatusCard(Map<String, dynamic> data, String status, bool isDraft) {
    final color = isDraft ? Colors.orange : Colors.green;
    final icon = isDraft ? Icons.drafts : Icons.check_circle;

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
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(
                        isDraft ? 'Draft mode - editable' : 'Submitted - read only',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Sheet ID Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SHEET ID',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  data['sheetId'] ?? '-',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopInfoCard(Map<String, dynamic> data) {
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
                child: const Icon(Icons.info_outline, color: Colors.purple, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Quick Info',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoTile('Factory', data['factory'] ?? '-', Icons.factory),
          _buildInfoTile('Machine', data['machine'] ?? '-', Icons.precision_manufacturing),
          _buildInfoTile('Customer', data['customerName'] ?? '-', Icons.person),
          _buildInfoTile('Technician', data['technician1'] ?? '-', Icons.engineering),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
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

  Widget _buildDesktopSystemInfoCard(Map<String, dynamic> data) {
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
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.settings, color: Colors.teal, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'System Info',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSystemInfoRow('Created', _formatDateTime(data['createdAt'])),
          _buildSystemInfoRow('Created By', data['createdBy'] ?? '-'),
          if (data['submittedAt'] != null)
            _buildSystemInfoRow('Submitted', _formatDateTime(data['submittedAt'])),
          if (data['submittedBy'] != null)
            _buildSystemInfoRow('Submitted By', data['submittedBy']),
        ],
      ),
    );
  }

  Widget _buildSystemInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopHeaderCard(Map<String, dynamic> data) {
    return _glass(
      Row(
        children: [
          Container(
            width: 4,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['sheetId'] ?? '-',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${data['factory'] ?? '-'} • ${data['machine'] ?? '-'}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: (data['status'] == 'Draft' ? Colors.orange : Colors.green).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              data['status'] ?? 'Draft',
              style: TextStyle(
                color: data['status'] == 'Draft' ? Colors.orange : Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopContentCards(Map<String, dynamic> data) {
    return Column(
      children: [
        // BASIC INFORMATION
        _buildDesktopInfoSection(
          'BASIC INFORMATION',
          Icons.info,
          Colors.blue,
          [
            _buildDetailRow('Start Date', _formatDate(data['startDate'])),
            _buildDetailRow('End Date', _formatDate(data['endDate'])),
            _buildDetailRow('End Customer', data['endCustomer'] ?? '-'),
            _buildDetailRow('Customer Code', data['customerCode'] ?? '-'),
          ],
        ),

        const SizedBox(height: 16),

        // MACHINE INFORMATION
        _buildDesktopInfoSection(
          'MACHINE INFORMATION',
          Icons.precision_manufacturing,
          Colors.purple,
          [
            _buildDetailRow('Serial Number', data['serialNumber'] ?? '-'),
            _buildDetailRow('Asset Number', data['assetNumber'] ?? '-'),
          ],
        ),

        const SizedBox(height: 16),

        // DESCRIPTION
        _buildDesktopInfoSection(
          'PROBLEM DESCRIPTION',
          Icons.description,
          Colors.orange,
          [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(data['problemDescription'] ?? '-'),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ACTIVITY
        _buildDesktopInfoSection(
          'ACTIVITY',
          Icons.bolt,
          Colors.green,
          [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(data['activity'] ?? '-'),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // NOTE FOR CUSTOMER
        if (data['noteForCustomer'] != null && data['noteForCustomer'].toString().isNotEmpty)
          _buildDesktopInfoSection(
            'NOTE FOR CUSTOMER',
            Icons.note,
            Colors.teal,
            [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(data['noteForCustomer']),
              ),
            ],
          ),

        if (data['noteForCustomer'] != null && data['noteForCustomer'].toString().isNotEmpty)
          const SizedBox(height: 16),

        // TECHNICIANS
        _buildDesktopInfoSection(
          'TECHNICIANS',
          Icons.engineering,
          Colors.brown,
          [
            _buildDetailRow('Technician 1', data['technician1'] ?? '-'),
            if (data['technician2'] != null)
              _buildDetailRow('Technician 2', data['technician2']),
            if (data['technician3'] != null)
              _buildDetailRow('Technician 3', data['technician3']),
          ],
        ),

        const SizedBox(height: 16),

        // SPARE PARTS
        if (data['spareParts'] != null && (data['spareParts'] as List).isNotEmpty)
          _buildDesktopInfoSection(
            'SPARE PARTS',
            Icons.build,
            Colors.deepOrange,
            (data['spareParts'] as List).map((part) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(part['name'] ?? '-')),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "Qty: ${part['qty'] ?? '1'}",
                        style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

        if (data['spareParts'] != null && (data['spareParts'] as List).isNotEmpty)
          const SizedBox(height: 16),

        // SIGNATURE
        _buildDesktopInfoSection(
          'CUSTOMER SIGNATURE',
          Icons.draw,
          Colors.indigo,
          [
            Container(
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: data['signature'] != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        data['signature'],
                        fit: BoxFit.contain,
                      ),
                    )
                  : const Center(
                      child: Text("No signature"),
                    ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // MEDIA
        _buildDesktopInfoSection(
          'MEDIA',
          Icons.photo_library,
          Colors.pink,
          _buildMediaWidgets(data),
        ),
      ],
    );
  }

  List<Widget> _buildMediaWidgets(Map<String, dynamic> data) {
    List<Widget> widgets = [];
    
    if (data['photo1'] != null) {
      widgets.addAll([
        const Text("Photo 1", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            data['photo1'],
            height: 200,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 16),
      ]);
    }
    
    if (data['photo2'] != null) {
      widgets.addAll([
        const Text("Photo 2", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            data['photo2'],
            height: 200,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 16),
      ]);
    }
    
    if (data['photo3'] != null) {
      widgets.addAll([
        const Text("Photo 3", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            data['photo3'],
            height: 200,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 16),
      ]);
    }
    
    if (data['video'] != null) {
      widgets.addAll([
        const Text("Video", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: TextButton.icon(
              onPressed: () => _playVideo(context, data['video']),
              icon: const Icon(Icons.play_circle_filled, color: Colors.white, size: 48),
              label: const Text("Play Video", style: TextStyle(color: Colors.white)),
            ),
          ),
        ),
      ]);
    }
    
    if (widgets.isEmpty) {
      widgets.add(const Center(child: Text("No media")));
    }
    
    return widgets;
  }

  Widget _buildDesktopInfoSection(String title, IconData icon, Color color, List<Widget> children) {
    return _glass(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopActionButtons() {
  return _glass(
    Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton.icon(
              onPressed: _editReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade200,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: const Icon(Icons.edit),
              label: const Text("Edit Draft"),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: _submitReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: const Icon(Icons.send),
              label: const Text("Submit Report"),
            ),
          ],
        ),

        const SizedBox(height: 12),

        ElevatedButton.icon(
          onPressed: _deleteReport,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          icon: const Icon(Icons.delete),
          label: const Text("Delete Report"),
        ),
      ],
    ),
  );
}

  // ================= MOBILE LAYOUT =================
  Widget _buildMobileLayout(Map<String, dynamic> data, String status, bool isDraft) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Status Banner
          _glass(
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isDraft ? Colors.orange : Colors.green,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['sheetId'] ?? '-',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${data['factory'] ?? '-'} • ${data['machine'] ?? '-'}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (isDraft ? Colors.orange : Colors.green).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isDraft ? Icons.drafts : Icons.check_circle,
                          size: 14,
                          color: isDraft ? Colors.orange : Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          status,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDraft ? Colors.orange : Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Basic Info Card
          _buildMobileInfoCard(
            'BASIC INFORMATION',
            Icons.info,
            Colors.blue,
            [
              _buildMobileInfoRow('Start Date', _formatDate(data['startDate'])),
              _buildMobileInfoRow('End Date', _formatDate(data['endDate'])),
              _buildMobileInfoRow('Factory', data['factory'] ?? '-'),
              _buildMobileInfoRow('End Customer', data['endCustomer'] ?? '-'),
              _buildMobileInfoRow('Customer Code', data['customerCode'] ?? '-'),
            ],
          ),
          const SizedBox(height: 12),

          // Machine Info Card
          _buildMobileInfoCard(
            'MACHINE INFORMATION',
            Icons.precision_manufacturing,
            Colors.purple,
            [
              _buildMobileInfoRow('Machine', data['machine'] ?? '-'),
              _buildMobileInfoRow('Serial Number', data['serialNumber'] ?? '-'),
              _buildMobileInfoRow('Asset Number', data['assetNumber'] ?? '-'),
            ],
          ),
          const SizedBox(height: 12),

          // Description Card
          _buildMobileInfoCard(
            'PROBLEM DESCRIPTION',
            Icons.description,
            Colors.orange,
            [
              Text(data['problemDescription'] ?? '-'),
            ],
          ),
          const SizedBox(height: 12),

          // Activity Card
          _buildMobileInfoCard(
            'ACTIVITY',
            Icons.bolt,
            Colors.green,
            [
              Text(data['activity'] ?? '-'),
            ],
          ),
          const SizedBox(height: 12),

          // Note Card
          if (data['noteForCustomer'] != null && data['noteForCustomer'].toString().isNotEmpty)
            _buildMobileInfoCard(
              'NOTE FOR CUSTOMER',
              Icons.note,
              Colors.teal,
              [
                Text(data['noteForCustomer']),
              ],
            ),
          if (data['noteForCustomer'] != null && data['noteForCustomer'].toString().isNotEmpty)
            const SizedBox(height: 12),

          // Technicians Card
          _buildMobileInfoCard(
            'TECHNICIANS',
            Icons.engineering,
            Colors.brown,
            [
              _buildMobileInfoRow('Technician 1', data['technician1'] ?? '-'),
              if (data['technician2'] != null)
                _buildMobileInfoRow('Technician 2', data['technician2']),
              if (data['technician3'] != null)
                _buildMobileInfoRow('Technician 3', data['technician3']),
            ],
          ),
          const SizedBox(height: 12),

          // Spare Parts Card
          if (data['spareParts'] != null && (data['spareParts'] as List).isNotEmpty)
            _buildMobileInfoCard(
              'SPARE PARTS',
              Icons.build,
              Colors.deepOrange,
              (data['spareParts'] as List).map((part) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Expanded(child: Text(part['name'] ?? '-')),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "Qty: ${part['qty'] ?? '1'}",
                          style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          if (data['spareParts'] != null && (data['spareParts'] as List).isNotEmpty)
            const SizedBox(height: 12),

          // Signature Card
          _buildMobileInfoCard(
            'CUSTOMER SIGNATURE',
            Icons.draw,
            Colors.indigo,
            [
              Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: data['signature'] != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          data['signature'],
                          fit: BoxFit.contain,
                        ),
                      )
                    : const Center(
                        child: Text("No signature"),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Media Card
          _buildMobileInfoCard(
            'MEDIA',
            Icons.photo_library,
            Colors.pink,
            _buildMediaWidgets(data),
          ),
          const SizedBox(height: 20),

          // System Info Card
          _buildMobileInfoCard(
            'SYSTEM INFORMATION',
            Icons.settings,
            Colors.teal,
            [
              _buildMobileInfoRow('Created At', _formatDateTime(data['createdAt'])),
              _buildMobileInfoRow('Created By', data['createdBy'] ?? '-'),
              if (data['submittedAt'] != null)
                _buildMobileInfoRow('Submitted At', _formatDateTime(data['submittedAt'])),
              if (data['submittedBy'] != null)
                _buildMobileInfoRow('Submitted By', data['submittedBy']),
            ],
          ),
          const SizedBox(height: 20),

          // Action Buttons
          // Action Buttons
if (isDraft && !_isSubmitting) ...[
  Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _editReport,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade200,
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.edit),
            label: const Text("Edit Draft"),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _submitReport,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.send),
            label: const Text("Submit"),
          ),
        ),
      ],
    ),
  ),

  Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _deleteReport,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        icon: const Icon(Icons.delete),
        label: const Text("Delete Report"),
     ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMobileInfoCard(String title, IconData icon, Color color, List<Widget> children) {
    return _glass(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildMobileInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
  Future<void> _deleteReport() async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Delete Service Report"),
      content: const Text(
        "This action cannot be undone.\n\nAre you sure you want to delete this report?",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("CANCEL"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: const Text("DELETE"),
        ),
      ],
    ),
  );

  if (confirm != true) return;

  try {
    await ServiceReportFirestore.deleteServiceReport(
      companyId: widget.companyId,
      docId: widget.reportId,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Service Report deleted successfully"),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context, true);

  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Error deleting report: $e"),
        backgroundColor: Colors.red,
      ),
    );
  }
}
}

// ================= UI HELPERS =================
Widget _glass(Widget child) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.4)),
        ),
        child: child,
      ),
    ),
  );
}