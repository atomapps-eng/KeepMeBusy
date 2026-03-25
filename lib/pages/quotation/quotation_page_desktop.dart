// 🔽 ANCHOR CODE: quotation_page_desktop.dart

import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/quotation_service.dart';
import 'quotation_detail_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'quotation_detail_page_desktop.dart';
import 'create_quotation_page_desktop.dart';
import '../../core/widgets/draggable_window.dart';

class QuotationPageDesktop extends StatefulWidget {
  final String companyId;
  final bool isSuperAdmin;

  const QuotationPageDesktop({
    super.key,
    required this.companyId,
    required this.isSuperAdmin,
  });

  @override
  State<QuotationPageDesktop> createState() => _QuotationPageDesktopState();
}

class _QuotationPageDesktopState extends State<QuotationPageDesktop> {
  bool _showCreateWindow = false;
  Map<String, dynamic>? _selectedQuotation;
bool _showDetailWindow = false;
bool _showEditWindow = false;
Map<String, dynamic>? _editData;
  ValueNotifier<Map<String, dynamic>?> selectedDataNotifier = ValueNotifier(null);
  final TextEditingController searchController = TextEditingController();
  String selectedStatus = 'all';
  String selectedSort = 'newest';

  Color _getStatusColor(String status) {
    switch (status) {
      case 'draft':
        return const Color(0xFFF59E0B);
      case 'submitted':
        return const Color(0xFF3B82F6);
      case 'approved':
        return const Color(0xFF10B981);
      case 'rejected':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _getStatusIcon(String status) {
    switch (status) {
      case 'draft':
        return '📝';
      case 'submitted':
        return '📤';
      case 'approved':
        return '✅';
      case 'rejected':
        return '❌';
      default:
        return '📄';
    }
  }

 @override
Widget build(BuildContext context) {
  return Scaffold(
    extendBodyBehindAppBar: true,
    floatingActionButton: FloatingActionButton.extended(
  onPressed: () {
    final overlay = Overlay.of(context, rootOverlay: true);

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) {
        return Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: DraggableResizableWindow(
              title: "Create Quotation",
              headerColor: Colors.green,
              onClose: () {
                entry.remove();
              },
              child: CreateQuotationPageDesktop(
                onClose: () {
                  entry.remove();
                },
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(entry);
  },
  icon: const Icon(Icons.add),
  label: const Text('New Quotation'),
  backgroundColor: const Color(0xFF2563EB),
),

    body: Stack(
      children: [

        // =========================
        // 🔵 MAIN CONTENT
        // =========================
        Container(
          decoration: BoxDecoration(
            gradient: AppTheme.backgroundGradient,
          ),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: _buildPreviewPanel(),
              ),
              Expanded(
                flex: 6,
                child: _buildListPanel(),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  // ===============================
  // PREVIEW PANEL (Modern)
  // ===============================
 Widget _buildPreviewPanel() {
  return ValueListenableBuilder<Map<String, dynamic>?>(
    valueListenable: selectedDataNotifier,
    builder: (context, selectedData, _) {
      if (selectedData == null) {
        return Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200.withOpacity(0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.request_quote,
                    size: 48,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No Quotation Selected',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Click on any quotation to view details',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      final data = selectedData;
      final format = NumberFormat.currency(
        locale: 'id',
        symbol: '${data['currency'] ?? ''} ',
        decimalDigits: 0,
      );

      final status = data['status'] ?? 'draft';
      final statusColor = _getStatusColor(status);
      final isDraft = status == 'draft';
      final isSubmitted = status == 'submitted';
      final validUntil = data['validUntil'];
      bool isExpired = false;

      if (validUntil != null) {
        final expiryDate = (validUntil as Timestamp).toDate();
        isExpired = DateTime.now().isAfter(expiryDate);
      }

      return RepaintBoundary(
        child: KeyedSubtree(
          key: ValueKey(data['id']),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // ================= HEADER CARD =================
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [statusColor, statusColor.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getStatusIcon(status),
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['quotationNumber'] ?? '-',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                if (isExpired) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'EXPIRED',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ================= PARTNER INFO CARD =================
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200.withOpacity(0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.business,
                                size: 18,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Partner Information',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          data['partnerName'] ?? '-',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          data['partnerAddress'] ?? '-',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ================= AMOUNT CARD =================
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200.withOpacity(0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Amount',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          format.format(data['totalAmount'] ?? 0),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        const Divider(height: 24),
                        _infoRow(
                          'Currency',
                          data['currency'] ?? '-',
                          Icons.attach_money,
                        ),
                        _infoRow(
                          'Exchange Rate',
                          '1 EUR = ${NumberFormat('#,###').format(data['exchangeRate'] ?? 0)}',
                          Icons.currency_exchange,
                        ),
                        if (data['validUntil'] != null)
                          _infoRow(
                            'Valid Until',
                            DateFormat('dd MMM yyyy').format(
                              (data['validUntil'] as Timestamp).toDate(),
                            ),
                            Icons.calendar_today,
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ================= DETAILS CARD =================
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200.withOpacity(0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.info_outline,
                                size: 16,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Details',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _infoRow(
                          'Created By',
                          data['createdByName'] ?? '-',
                          Icons.person,
                        ),
                        _infoRow(
                          'Created At',
                          data['createdAt'] != null
                              ? DateFormat('dd MMM yyyy').format(
                                  (data['createdAt'] as Timestamp).toDate(),
                                )
                              : '-',
                          Icons.calendar_today,
                        ),
                        if (data['approvedByName'] != null) ...[
                          const SizedBox(height: 8),
                          _infoRow(
                            'Approved By',
                            data['approvedByName'],
                            Icons.verified,
                            color: Colors.green,
                          ),
                        ],
                        if (data['submittedByName'] != null) ...[
                          const SizedBox(height: 8),
                          _infoRow(
                            'Submitted By',
                            data['submittedByName'],
                            Icons.send,
                          ),
                        ],
                        if (data['rejectedReason'] != null) ...[
                          const SizedBox(height: 8),
                          _infoRow(
                            'Rejection Reason',
                            data['rejectedReason'],
                            Icons.info_outline,
                            color: Colors.red,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ================= ACTION BUTTONS =================
                
              ],
            ),
          ),
        ),
      );
    },
  );
}

  // ===============================
  // LIST PANEL (Modern)
  // ===============================
  Widget _buildListPanel() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('companies')
            .doc(widget.companyId)
            .collection('quotations')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(child: Text("No data"));
          }

          var allDocs = snapshot.data!.docs;
          // 🔥 SYNC selectedData dengan firestore
if (selectedDataNotifier.value != null) {
  final selectedId = selectedDataNotifier.value!['id'];

  DocumentSnapshot? updatedDoc;

  try {
    updatedDoc = allDocs.firstWhere((doc) => doc.id == selectedId);
  } catch (e) {
    updatedDoc = null;
  }

 if (updatedDoc != null) {
  final newData = updatedDoc.data() as Map<String, dynamic>;
final safeData = Map<String, dynamic>.from(newData);
safeData['id'] = updatedDoc.id; // 🔥 WAJIB

if (selectedDataNotifier.value?['updatedAt'] != newData['updatedAt']) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;

    selectedDataNotifier.value = safeData;
  });
}

  // 🔥 HANYA update kalau data benar-benar berubah
  if (selectedDataNotifier.value?['updatedAt'] != newData['updatedAt']) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      selectedDataNotifier.value = {...newData, 'id': updatedDoc!.id};
    });
  }
}
}


          // Filter
          allDocs = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final search = searchController.text.toLowerCase();
            final number = (data['quotationNumber'] ?? '').toString().toLowerCase();
            final partner = (data['partnerName'] ?? '').toString().toLowerCase();
            final status = data['status'] ?? 'draft';

            final matchSearch = number.contains(search) || partner.contains(search);
            final matchStatus = selectedStatus == 'all' || status == selectedStatus;

            return matchSearch && matchStatus;
          }).toList();

          // Sort
          allDocs.sort((a, b) {
            final dataA = a.data() as Map<String, dynamic>;
            final dataB = b.data() as Map<String, dynamic>;

            switch (selectedSort) {
              case 'newest':
                final dateA = (dataA['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
                final dateB = (dataB['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
                return dateB.compareTo(dateA);
              case 'oldest':
                final dateA = (dataA['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
                final dateB = (dataB['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
                return dateA.compareTo(dateB);
              case 'amount_high':
                return (dataB['totalAmount'] ?? 0).compareTo(dataA['totalAmount'] ?? 0);
              case 'amount_low':
                return (dataA['totalAmount'] ?? 0).compareTo(dataB['totalAmount'] ?? 0);
              default:
                return 0;
            }
          });

          // Auto select first item
          if (allDocs.isNotEmpty && selectedDataNotifier.value == null) {
            final first = allDocs.first;
            final firstData = first.data() as Map<String, dynamic>;
final safeData = Map<String, dynamic>.from(firstData);
safeData['id'] = first.id; // 🔥 WAJIB

WidgetsBinding.instance.addPostFrameCallback((_) {
  selectedDataNotifier.value = safeData;
});
          }

          return Column(
            children: [
              // Search and Filter Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Search quotations...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF1F5F9),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButton<String>(
                        value: selectedStatus,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All Status')),
                          DropdownMenuItem(value: 'draft', child: Text('Draft')),
                          DropdownMenuItem(value: 'submitted', child: Text('Submitted')),
                          DropdownMenuItem(value: 'approved', child: Text('Approved')),
                          DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                        ],
                        onChanged: (value) {
                          setState(() => selectedStatus = value!);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButton<String>(
                        value: selectedSort,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down),
                        items: const [
                          DropdownMenuItem(value: 'newest', child: Text('Newest First')),
                          DropdownMenuItem(value: 'oldest', child: Text('Oldest First')),
                          DropdownMenuItem(value: 'amount_high', child: Text('Highest Amount')),
                          DropdownMenuItem(value: 'amount_low', child: Text('Lowest Amount')),
                        ],
                        onChanged: (value) {
                          setState(() => selectedSort = value!);
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // List Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const SizedBox(width: 48),
                    Expanded(
                      child: const Text(
                        'Quotation Number / Partner',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 100),
                    const Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 80),
                    const Text(
                      'Amount',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // List Items
              Expanded(
                child: allDocs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.request_quote,
                                size: 48,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No quotations found',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your search or filters',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: allDocs.length,
                        itemBuilder: (context, index) {
                          final doc = allDocs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final status = data['status'] ?? 'draft';
                          final statusColor = _getStatusColor(status);
                          final format = NumberFormat.currency(
                            locale: 'id',
                            symbol: '${data['currency'] ?? ''} ',
                            decimalDigits: 0,
                          );

                          final isSelected = selectedDataNotifier.value?['id'] == doc.id;

                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
  final safeData = Map<String, dynamic>.from(data);
  safeData['id'] = doc.id;

  selectedDataNotifier.value = safeData;
},
                               onDoubleTap: () {
  final safeData = Map<String, dynamic>.from(data);
  safeData['id'] = doc.id;

  final overlay = Overlay.of(context, rootOverlay: true);

  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (context) {
      return Positioned.fill(
        child: Material(
          color: Colors.transparent,
          child: DraggableResizableWindow(
            title: "Quotation Detail",
            headerColor: Colors.blueGrey,
            onClose: () {
              entry.remove();
            },
            child: QuotationDetailPageDesktop(
              data: safeData,
              isSuperAdmin: widget.isSuperAdmin,
              onEdit: (editData) {
  final overlay = Overlay.of(context, rootOverlay: true);

  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (context) {
      return Positioned.fill(
        child: Material(
          color: Colors.transparent,
          child: DraggableResizableWindow(
            title: "Edit Quotation",
            headerColor: Colors.orange,
            onClose: () {
              entry.remove();
            },
            child: CreateQuotationPageDesktop(
              initialData: editData,
              onClose: () {
                entry.remove();
              },
            ),
          ),
        ),
      );
    },
  );

  overlay.insert(entry);
},
            ),
          ),
        ),
      );
    },
  );

  overlay.insert(entry);
},
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              statusColor,
                                              statusColor.withOpacity(0.8),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          Icons.request_quote,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              data['quotationNumber'] ?? '-',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF0F172A),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              data['partnerName'] ?? '-',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        width: 100,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            status.toUpperCase(),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: statusColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 100,
                                        child: Text(
                                          format.format(data['totalAmount'] ?? 0),
                                          textAlign: TextAlign.end,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2563EB),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String value, IconData icon, {Color color = const Color(0xFF64748B)}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF64748B)),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPreviewContent(
  Map<String, dynamic> data,
  Color statusColor,
  bool isExpired,
) {
  final format = NumberFormat.currency(
    locale: 'id',
    symbol: '${data['currency'] ?? ''} ',
    decimalDigits: 0,
  );

  return [
    // HEADER CARD
    Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor, statusColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(
            data['quotationNumber'] ?? '-',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    ),

    const SizedBox(height: 16),

    // TOTAL
    Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        format.format(data['totalAmount'] ?? 0),
        style: const TextStyle(fontSize: 24),
      ),
    ),

    const SizedBox(height: 16),

    // DETAILS
    Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _infoRow('Partner', data['partnerName'] ?? '-', Icons.business),
          _infoRow('Address', data['partnerAddress'] ?? '-', Icons.location_on),
        ],
      ),
    ),
  ];
}

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 0,
      ),
      onPressed: onPressed,
    );
  }

}