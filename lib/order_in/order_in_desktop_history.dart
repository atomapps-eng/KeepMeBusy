import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/widgets/draggable_window.dart';
import '../pages/order_in/order_in_detail_page.dart';
import '../core/services/company_firestore.dart';

class OrderInDesktopHistory extends StatefulWidget {

  final void Function(BuildContext, Map<String, dynamic>) onEdit;

  const OrderInDesktopHistory({
    super.key,
    required this.onEdit,
  });
  @override
  State<OrderInDesktopHistory> createState() =>
      _OrderInDesktopHistoryState();
}

class _OrderInDesktopHistoryState
    extends State<OrderInDesktopHistory> {

  final TextEditingController _searchController =
      TextEditingController();

  DateTime? _filterDate;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFE0B2),
            Color(0xFFFFFFFF),
          ],
        ),
      ),
      child: Column(
        children: [

          // ================= SEARCH =================
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search PO / Client',
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                IconButton(
                  icon: const Icon(Icons.date_range),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate:
                          _filterDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );

                    if (picked != null) {
                      setState(() => _filterDate = picked);
                    }
                  },
                ),

                if (_filterDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () =>
                        setState(() => _filterDate = null),
                  ),
              ],
            ),
          ),

          // ================= LIST =================
          Expanded(
            child: _buildHistoryList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return StreamBuilder<QuerySnapshot>(
      stream: CompanyFirestore
          .collection('order_in')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (_, snapshot) {

        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator());
        }

        final keyword =
            _searchController.text.toLowerCase();

        final docs = snapshot.data!.docs.where((doc) {

          final data =
              doc.data() as Map<String, dynamic>;

          if (keyword.isNotEmpty &&
              !data['poNumber']
                  .toString()
                  .toLowerCase()
                  .contains(keyword) &&
              !data['client']
                  .toString()
                  .toLowerCase()
                  .contains(keyword)) {
            return false;
          }

          if (_filterDate != null) {
            final date =
                (data['orderDate'] as Timestamp?)
                    ?.toDate();

            if (date == null ||
                date.year != _filterDate!.year ||
                date.month != _filterDate!.month ||
                date.day != _filterDate!.day) {
              return false;
            }
          }

          return true;

        }).toList();

        if (docs.isEmpty) {
          return const Center(
              child: Text('No Order'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (_, i) {

            final data =
                docs[i].data() as Map<String, dynamic>;

            final orderId = docs[i].id;

            return InkWell(
  onTap: () async {
 final result = await showGeneralDialog<Map<String, dynamic>>(
  context: context,
  barrierDismissible: true,
  barrierLabel: "OrderInDetail",
  barrierColor: Colors.black.withValues(alpha: 0.35),
  transitionDuration: const Duration(milliseconds: 200),
  pageBuilder: (_, _, _) {
    return DraggableResizableWindow(
      title: "Order In Detail",
      child: OrderInDetailPage(
        data: {
          ...data,
          'id': orderId,
        },
      ),
    );
  },
);

  // 🔥 INI YANG PENTING
  if (!mounted || result == null) return;

widget.onEdit(context, result);
},
  child: _OrderInHistoryCard(
    data: {
      ...data,
      'id': orderId,
    },
    onEdit: () => widget.onEdit(
      context,
      {
        ...data,
        'id': orderId,
      },
    ),
  ),
);
          },
        );
      },
    );
  }
}

class _OrderInHistoryCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback? onEdit;

  const _OrderInHistoryCard({
    required this.data,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {

    final date =
        (data['orderDate'] as Timestamp?)
            ?.toDate();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PO: ${data['poNumber']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text('Client: ${data['client']}'),

                if (data['createdBy'] != null)
                  Text(
                    'Created By: ${data['createdBy']}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),

                if (date != null)
                  Text(
                    '${date.day}/${date.month}/${date.year}',
                    style: const TextStyle(fontSize: 12),
                  ),
              ],
            ),
          ),

          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blueGrey),
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }
}