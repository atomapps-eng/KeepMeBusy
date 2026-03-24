// 🔽 ANCHOR CODE: quotation_page_desktop.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/quotation_service.dart';
import 'quotation_detail_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'quotation_detail_page_desktop.dart';
import 'create_quotation_page_desktop.dart';

class QuotationPageDesktop extends StatefulWidget {
  final String companyId;
  final bool isSuperAdmin;

  const QuotationPageDesktop({
    super.key,
    required this.companyId,
    required this.isSuperAdmin,
  });

  @override
  State<QuotationPageDesktop> createState() =>
      _QuotationPageDesktopState();
}

class _QuotationPageDesktopState
    extends State<QuotationPageDesktop> {

  Map<String, dynamic>? selectedData;

  final TextEditingController searchController = TextEditingController();
String selectedStatus = 'all';
String selectedSort = 'newest';

@override
void initState() {
  super.initState();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateQuotationPageDesktop(),
      ),
    );
  },
  child: const Icon(Icons.add),
),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: Row(
          children: [

            // 🔽 LEFT PANEL (PREVIEW)
            Expanded(
              flex: 3,
              child: _buildPreview(),
            ),

            // 🔽 RIGHT PANEL (LIST)
            Expanded(
              flex: 5,
              child: _buildList(),
            ),
          ],
        ),
      ),
    );
  }

  // ===============================
  // 🔽 PREVIEW PANEL
  // ===============================
 Widget _buildPreview() {
  if (selectedData == null) {
    return const Center(
      child: Text("Select quotation"),
    );
  }

  final data = selectedData!;

  final format = NumberFormat.currency(
    locale: 'id',
    symbol: '${data['currency'] ?? ''} ',
    decimalDigits: 0,
  );

  final status = data['status'] ?? 'draft';

  Color getStatusColor(String status) {
    switch (status) {
      case 'draft':
        return Colors.orange;
      case 'submitted':
        return Colors.blue;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  return Container(
    margin: const EdgeInsets.all(16),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
        )
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // 🔽 HEADER
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.request_quote,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                data['quotationNumber'] ?? '-',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // 🔽 STATUS
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: getStatusColor(status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            status.toUpperCase(),
            style: TextStyle(
              color: getStatusColor(status),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 20),

        // 🔽 PARTNER
        Text(
          "Partner",
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          data['partnerName'] ?? '-',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 20),

        // 🔽 CREATED BY
        Row(
          children: [
            const Icon(Icons.person, size: 16, color: Colors.grey),
            const SizedBox(width: 6),
            Text(
              "Created: ${data['createdByName'] ?? '-'}",
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // 🔽 APPROVED BY
        if (data['approvedBy'] != null)
          Row(
            children: [
              const Icon(Icons.verified, size: 16, color: Colors.green),
              const SizedBox(width: 6),
              Text(
                "Approved: ${data['approvedByName'] ?? '-'}",
                style: const TextStyle(color: Colors.green),
              ),
            ],
          ),

        const Spacer(),

        // 🔽 TOTAL AMOUNT (BIG)
        Text(
          "Total",
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 6),
        Text(
          format.format(data['totalAmount'] ?? 0),
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),


// 🔽 ACTION BUTTONS
const SizedBox(height: 20),

Builder(
  builder: (context) {
    final user = FirebaseAuth.instance.currentUser!;
    final isSuperAdmin = widget.isSuperAdmin;

    final status = data['status'] ?? 'draft';
    final isDraft = status == 'draft';
    final isSubmitted = status == 'submitted';

    return Row(
      children: [

        // 🔽 SUBMIT
        if (isDraft)
          ElevatedButton.icon(
            icon: const Icon(Icons.send, size: 16),
            label: const Text("Submit"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.withOpacity(0.1),
              foregroundColor: Colors.blue,
            ),
            onPressed: () async {
              await QuotationService.submitQuotation(
                companyId: widget.companyId,
                quotationId: data['id'],
                userId: user.uid,
              );
            },
          ),

        const SizedBox(width: 10),

        // 🔽 APPROVE
        if (isSubmitted && isSuperAdmin)
          ElevatedButton.icon(
            icon: const Icon(Icons.check, size: 16),
            label: const Text("Approve"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.withOpacity(0.1),
              foregroundColor: Colors.green,
            ),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Approve"),
                  content: const Text("Approve this quotation?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Approve"),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await QuotationService.approveQuotation(
                  companyId: widget.companyId,
                  quotationId: data['id'],
                  userId: user.uid,
                );
              }
            },
          ),

        const SizedBox(width: 10),

        // 🔽 REJECT
        if (isSubmitted && isSuperAdmin)
          ElevatedButton.icon(
            icon: const Icon(Icons.close, size: 16),
            label: const Text("Reject"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.1),
              foregroundColor: Colors.red,
            ),
            onPressed: () async {
              final controller = TextEditingController();

              final reason = await showDialog<String>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Reject Reason"),
                  content: TextField(
                    controller: controller,
                    maxLines: 3,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, controller.text);
                      },
                      child: const Text("Submit"),
                    ),
                  ],
                ),
              );

              if (reason == null || reason.trim().isEmpty) return;

              await QuotationService.rejectQuotation(
                companyId: widget.companyId,
                quotationId: data['id'],
                userId: user.uid,
                note: reason,
              );
            },
          ),
      ],
    );
  },
),

      ],
    ),
  );
}

  // ===============================
  // 🔽 LIST PANEL
  // ===============================
 Widget _buildList() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .collection('quotations')
        .orderBy('createdAt', descending: true)
        .snapshots(),
    builder: (context, snapshot) {

      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }

      final allDocs = snapshot.data!.docs;

      // 🔽 FILTER
      List<QueryDocumentSnapshot> docs = allDocs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;

        final search = searchController.text.toLowerCase();
        final name = (data['quotationNumber'] ?? '').toString().toLowerCase();
        final partner = (data['partnerName'] ?? '').toString().toLowerCase();

        final status = data['status'] ?? 'draft';

        final matchSearch =
            name.contains(search) || partner.contains(search);

        final matchStatus =
            selectedStatus == 'all' || status == selectedStatus;

        return matchSearch && matchStatus;
      }).toList();

      // 🔽 SORT
      docs.sort((a, b) {
        final dataA = a.data() as Map<String, dynamic>;
        final dataB = b.data() as Map<String, dynamic>;

        final createdA = (dataA['createdAt'] as Timestamp?)?.toDate();
        final createdB = (dataB['createdAt'] as Timestamp?)?.toDate();

        final amountA = (dataA['totalAmount'] ?? 0) as num;
        final amountB = (dataB['totalAmount'] ?? 0) as num;

        switch (selectedSort) {
          case 'newest':
            return (createdB ?? DateTime(0))
                .compareTo(createdA ?? DateTime(0));

          case 'oldest':
            return (createdA ?? DateTime(0))
                .compareTo(createdB ?? DateTime(0));

          case 'amount_high':
            return amountB.compareTo(amountA);

          case 'amount_low':
            return amountA.compareTo(amountB);

          default:
            return 0;
        }
      });

      // 🔽 AUTO SELECT (FIXED)
      if (docs.isNotEmpty) {
        final exists = docs.any((doc) => doc.id == selectedData?['id']);

        if (!exists) {
          final first = docs.first;
          final firstData = first.data() as Map<String, dynamic>;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              selectedData = {
                ...firstData,
                'id': first.id,
              };
            });
          });
        }
      }

      return Column(
        children: [

          // 🔽 SEARCH + FILTER + SORT
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [

                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: "Search quotation...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),

                const SizedBox(width: 10),

                DropdownButton<String>(
                  value: selectedStatus,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(value: 'draft', child: Text('Draft')),
                    DropdownMenuItem(value: 'submitted', child: Text('Submitted')),
                    DropdownMenuItem(value: 'approved', child: Text('Approved')),
                    DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedStatus = value!;
                    });
                  },
                ),

                const SizedBox(width: 10),

                DropdownButton<String>(
                  value: selectedSort,
                  items: const [
                    DropdownMenuItem(value: 'newest', child: Text('Newest')),
                    DropdownMenuItem(value: 'oldest', child: Text('Oldest')),
                    DropdownMenuItem(value: 'amount_high', child: Text('Amount ↑')),
                    DropdownMenuItem(value: 'amount_low', child: Text('Amount ↓')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedSort = value!;
                    });
                  },
                ),
              ],
            ),
          ),

          // 🔽 LIST
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: docs.length,
              itemBuilder: (context, index) {

                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;

                final selectedId = selectedData?['id'];
                final isSelected = selectedId == doc.id;

                final format = NumberFormat.currency(
                  locale: 'id',
                  symbol: '${data['currency'] ?? ''} ',
                  decimalDigits: 0,
                );

                final status = data['status'] ?? 'draft';

                Color getStatusColor(String status) {
                  switch (status) {
                    case 'draft':
                      return Colors.orange;
                    case 'submitted':
                      return Colors.blue;
                    case 'approved':
                      return Colors.green;
                    case 'rejected':
                      return Colors.red;
                    default:
                      return Colors.grey;
                  }
                }

                return GestureDetector(
                  onTap: () {
  setState(() {
    selectedData = {
      ...data,
      'id': doc.id,
    };
  });
},

onDoubleTap: () {

  final isDesktop = MediaQuery.of(context).size.width > 900;

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => isDesktop
          ? QuotationDetailPageDesktop(
              data: {
                ...data,
                'id': doc.id,
              },
              isSuperAdmin: widget.isSuperAdmin,
            )
          : QuotationDetailPage(
              data: {
                ...data,
                'id': doc.id,
              },
              isSuperAdmin: widget.isSuperAdmin,
            ),
    ),
  );
},
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.blue.withOpacity(0.08)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? Colors.blue
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      children: [

                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.request_quote, color: Colors.blue),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['quotationNumber'] ?? '-',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                data['partnerName'] ?? '-',
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: getStatusColor(status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: getStatusColor(status),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        Text(
                          format.format(data['totalAmount'] ?? 0),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    },
  );
}
  
}
