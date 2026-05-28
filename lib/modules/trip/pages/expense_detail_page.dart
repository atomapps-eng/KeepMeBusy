import 'package:flutter/material.dart';
import 'dart:ui';
import '../models/trip_expense_model.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../pages/common/app_background_wrapper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/trip_expense_service.dart';
import 'add_expense_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/session/company_session.dart';

class ExpenseDetailPage extends StatelessWidget {
  final TripExpense expense;
  final String tripId;

  const ExpenseDetailPage({
    super.key,
    required this.expense,
    required this.tripId,
  });

  Future<void> downloadFile(String url) async {
    final uri = Uri.parse(url);

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Hotel':
        return Colors.blue;
      case 'Meal':
        return Colors.green;
      case 'Transportation':
        return Colors.orange;
      case 'Other':
        return Colors.purple;
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPdf = expense.receiptUrl.contains(".pdf");
    final categoryColor = _getCategoryColor(expense.category);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        actions: [
          /// EDIT
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Edit Expense"),
                  content: const Text("Do you want to edit this expense?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Edit"),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AddExpensePage(tripId: tripId, expenseId: expense.id),
                  ),
                );
              }
            },
          ),

          /// DELETE
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Delete Expense"),
                  content: const Text(
                    "Are you sure you want to delete this expense?",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Delete"),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await TripExpenseService().deleteExpense(tripId, expense.id);

                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
          ),
        ],
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    categoryColor.withValues(alpha: 0.2),
                    categoryColor.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: categoryColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Icon(Icons.receipt, color: categoryColor, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Expense Detail',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    expense.category,
                    style: TextStyle(
                      fontSize: 10,
                      color: categoryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.2),
                Colors.white.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: AppBackgroundWrapper(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Info Card
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
                                categoryColor.withValues(alpha: 0.2),
                                categoryColor.withValues(alpha: 0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.info_outline,
                            color: categoryColor,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Expense Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildInfoTile(
                      icon: Icons.category,
                      label: 'Category',
                      value: expense.category,
                      color: categoryColor,
                    ),

                    _buildInfoTile(
                      icon: Icons.attach_money,
                      label: 'Amount',
                      value:
                          '${expense.currency} ${formatCurrency(expense.amount)}',
                      color: Colors.green,
                    ),

                    _buildInfoTile(
                      icon: Icons.calendar_today,
                      label: 'Date',
                      value: _formatDate(expense.date),
                      color: Colors.blue,
                    ),

                    FutureBuilder<String>(
                      future: _getTripCreatorName(),
                      builder: (context, snapshot) {
                        final name = snapshot.data ?? 'Loading...';

                        return _buildInfoTile(
                          icon: Icons.person,
                          label: 'Employee',
                          value: name,
                          color: Colors.purple,
                        );
                      },
                    ),

                    const Divider(height: 24),

                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        expense.description.isEmpty
                            ? 'No description'
                            : expense.description,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Receipt Card
              if (expense.receiptUrl.isNotEmpty) ...[
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
                                  Colors.orange.withValues(alpha: 0.2),
                                  Colors.orange.withValues(alpha: 0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.receipt,
                              color: Colors.orange,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Receipt',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Center(
                        child: Container(
                          constraints: const BoxConstraints(maxHeight: 300),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            children: [
                              if (!isPdf)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: GestureDetector(
                                    onTap: () {
                                      _openImagePreview(
                                        context,
                                        expense.receiptUrl,
                                      );
                                    },
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        expense.receiptUrl,
                                        height: 200,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),

                              if (isPdf)
                                Container(
                                  height: 150,
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.picture_as_pdf,
                                          size: 50,
                                          color: Colors.red,
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'PDF Document',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 12),

                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 40),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                icon: const Icon(Icons.download, size: 18),
                                label: const Text('Download Receipt'),
                                onPressed: () {
                                  downloadFile(expense.receiptUrl);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _openImagePreview(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (_) {
        return GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: InteractiveViewer(child: Image.network(imageUrl)),
            ),
          ),
        );
      },
    );
  }

  Future<String> _getTripCreatorName() async {
    try {
      /// ambil trip
      final tripDoc = await FirebaseFirestore.instance
          .collection('companies')
          .doc(await _getCompanyId())
          .collection('trips')
          .doc(tripId)
          .get();

      final createdBy = tripDoc.data()?['createdBy'];

      if (createdBy == null) return '-';

      /// ambil user
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(createdBy)
          .get();

      return userDoc.data()?['username'] ?? '-';
    } catch (e) {
      return '-';
    }
  }

  Future<String> _getCompanyId() async {
    final selectedCompanyId = CompanySession.selectedCompanyId;
    if (selectedCompanyId != null && selectedCompanyId.isNotEmpty) {
      return selectedCompanyId;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return '';

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final companyIds = List<String>.from(doc.data()?['companyIds'] ?? []);

    return companyIds.isNotEmpty ? companyIds.first : '';
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String formatCurrency(double value) {
    final number = value.toInt().toString();

    return number.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
  }

  Future<String> _getUserName(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists) {
        return doc.data()?['username'] ?? uid;
      }

      return uid;
    } catch (e) {
      return uid;
    }
  }
}

// =======================================================
// UI HELPERS
// =======================================================
Widget _glass(Widget child) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.3),
              Colors.white.withValues(alpha: 0.15),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
        ),
        child: child,
      ),
    ),
  );
}
