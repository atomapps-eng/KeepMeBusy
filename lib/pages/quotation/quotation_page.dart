import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/session/company_session.dart';
import '../../services/quotation_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import 'create_quotation_page.dart';
import 'quotation_detail_page.dart';

class QuotationPage extends StatelessWidget {
  const QuotationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final companyId = CompanySession.selectedCompanyId;

    if (companyId == null) {
      return const Center(child: Text("No company selected"));
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;

        final accessLevel = userData['accessLevel'];
        final role = userData['role'];

        final isAdmin = accessLevel == 'admin_countries';
        final isSuperAdmin = role == 'super_admin';

        if (!isAdmin && !isSuperAdmin) {
          return const Scaffold(
            body: Center(
              child: Text("Access Denied"),
            ),
          );
        }

        return _buildQuotationContent(
          context,
          companyId,
          isSuperAdmin,
        );
      },
    );
  }

  Widget _buildQuotationContent(
    BuildContext context,
    String companyId,
    bool isSuperAdmin,
  ) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.request_quote,
                size: 20,
                color: Colors.deepOrangeAccent,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Quotation',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        leading: Container(
          margin: const EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('companies')
              .doc(companyId)
              .collection('quotations')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading quotations...'),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red.shade400,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading quotations',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      style: TextStyle(color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final docs = snapshot.data!.docs;

            if (docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.request_quote,
                        size: 64,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No Quotations Yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Create your first quotation',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CreateQuotationPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Create Quotation'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.only(
  top: MediaQuery.of(context).padding.top + 40,
  left: 16,
  right: 16,
  bottom: 100,
),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;
                final format = NumberFormat.currency(
                  locale: 'id',
                  symbol: '${data['currency'] ?? ''} ',
                  decimalDigits: 0,
                );
                final validUntil = data['validUntil'];
                bool isExpired = false;

                if (validUntil != null) {
                  final expiryDate = (validUntil as Timestamp).toDate();
                  isExpired = DateTime.now().isAfter(expiryDate);
                }

                final status = data['status'] ?? 'draft';
                final isDraft = status == 'draft';
                final isSubmitted = status == 'submitted';
                final isApproved = status == 'approved';
                final isRejected = status == 'rejected';

                Color getStatusColor(String status) {
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

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
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
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QuotationDetailPage(
                              data: {
                                ...(doc.data() as Map<String, dynamic>),
                                'id': doc.id,
                              },
                              isSuperAdmin: isSuperAdmin,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row
                            Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF2563EB),
                                        Color(0xFF3B82F6),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.request_quote,
                                    color: Colors.white,
                                    size: 24,
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
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),

                                      const SizedBox(height: 4),

Text(
  data['partnerName'] ?? '-',
  style: TextStyle(
    fontSize: 13,
    color: Colors.black,
    fontWeight: FontWeight.w500,
  ),
),
const SizedBox(height: 6),

Row(
  children: [
    Icon(Icons.person, size: 14, color: Colors.grey),
    const SizedBox(width: 4),
    Expanded(
      child: Text(
        'Created: ${data['createdByName'] ?? '-'}',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    ),
  ],
),

if (data['approvedBy'] != null) ...[
  const SizedBox(height: 2),

  FutureBuilder<DocumentSnapshot>(
    future: FirebaseFirestore.instance
        .collection('users')
        .doc(data['approvedBy'])
        .get(),
    builder: (context, snapshot) {
      String name = '-';

      if (snapshot.hasData && snapshot.data!.exists) {
        final userData = snapshot.data!.data() as Map<String, dynamic>;
        name = userData['name'] ?? '-';
      }

      return Row(
        children: [
          const Icon(Icons.verified, size: 14, color: Colors.green),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'Approved: $name',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    },
  ),
],
                                      const SizedBox(height: 4),
                                      
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: getStatusColor(status).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              status.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: getStatusColor(status),
                                              ),
                                            ),
                                          ),
                                          if (isExpired) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.red.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Text(
                                                'EXPIRED',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Amount
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    format.format(data['totalAmount'] ?? 0),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Action Buttons
                            if ((isDraft && !isExpired) || (isSubmitted && isSuperAdmin))
                              Container(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (isDraft && !isExpired)
                                      _buildActionButton(
                                        icon: Icons.send,
                                        label: 'Submit',
                                        color: Colors.blue,
                                        onPressed: () async {
                                          final user = FirebaseAuth.instance.currentUser!;
                                          await QuotationService.submitQuotation(
                                            companyId: companyId,
                                            quotationId: doc.id,
                                            userId: user.uid,
                                          );
                                        },
                                      ),
                                    if (isSubmitted && isSuperAdmin) ...[
                                      _buildActionButton(
                                        icon: Icons.check,
                                        label: 'Approve',
                                        color: Colors.green,
                                        onPressed: isExpired
                                            ? null
                                            : () async {
                                                final confirm = await showDialog<bool>(
                                                  context: context,
                                                  builder: (_) => AlertDialog(
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(20),
                                                    ),
                                                    title: const Text("Approve Quotation"),
                                                    content: const Text(
                                                      "Are you sure you want to approve this quotation?",
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.pop(context, false),
                                                        child: const Text("Cancel"),
                                                      ),
                                                      ElevatedButton(
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: Colors.green,
                                                          foregroundColor: Colors.white,
                                                        ),
                                                        onPressed: () => Navigator.pop(context, true),
                                                        child: const Text("Approve"),
                                                      ),
                                                    ],
                                                  ),
                                                );

                                                if (confirm == true) {
                                                  final user = FirebaseAuth.instance.currentUser!;
                                                  await QuotationService.approveQuotation(
                                                    companyId: companyId,
                                                    quotationId: doc.id,
                                                    userId: user.uid,
                                                  );
                                                }
                                              },
                                      ),
                                      const SizedBox(width: 8),
                                      _buildActionButton(
                                        icon: Icons.close,
                                        label: 'Reject',
                                        color: Colors.red,
                                        onPressed: isExpired
                                            ? null
                                            : () async {
                                                final controller = TextEditingController();

                                                final reason = await showDialog<String>(
                                                  context: context,
                                                  builder: (_) => AlertDialog(
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(20),
                                                    ),
                                                    title: const Text("Reject Quotation"),
                                                    content: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        const Text(
                                                          "Please provide a reason for rejection:",
                                                        ),
                                                        const SizedBox(height: 10),
                                                        TextField(
                                                          controller: controller,
                                                          maxLines: 3,
                                                          decoration: const InputDecoration(
                                                            hintText: "Enter rejection reason...",
                                                            border: OutlineInputBorder(),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.pop(context),
                                                        child: const Text("Cancel"),
                                                      ),
                                                      ElevatedButton(
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: Colors.red,
                                                          foregroundColor: Colors.white,
                                                        ),
                                                        onPressed: () {
                                                          if (controller.text.trim().isEmpty) return;
                                                          Navigator.pop(context, controller.text.trim());
                                                        },
                                                        child: const Text("Continue"),
                                                      ),
                                                    ],
                                                  ),
                                                );

                                                if (reason == null) return;

                                                final confirm = await showDialog<bool>(
                                                  context: context,
                                                  builder: (_) => AlertDialog(
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(20),
                                                    ),
                                                    title: const Text("Confirm Rejection"),
                                                    content: Text(
                                                      "Are you sure you want to reject this quotation?\n\nReason:\n$reason",
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.pop(context, false),
                                                        child: const Text("Back"),
                                                      ),
                                                      ElevatedButton(
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: Colors.red,
                                                          foregroundColor: Colors.white,
                                                        ),
                                                        onPressed: () => Navigator.pop(context, true),
                                                        child: const Text("Reject"),
                                                      ),
                                                    ],
                                                  ),
                                                );

                                                if (confirm == true) {
                                                  final user = FirebaseAuth.instance.currentUser!;
                                                  await QuotationService.rejectQuotation(
                                                    companyId: companyId,
                                                    quotationId: doc.id,
                                                    userId: user.uid,
                                                    note: reason,
                                                  );
                                                }
                                              },
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateQuotationPage(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Quotation'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 0,
      ),
      onPressed: onPressed,
    );
  }
}