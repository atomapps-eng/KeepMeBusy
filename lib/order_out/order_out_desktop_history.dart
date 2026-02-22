import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/services/company_firestore.dart';

class OrderOutDesktopHistory extends StatefulWidget {
  final void Function(BuildContext, Map<String, dynamic>) onTap;

  const OrderOutDesktopHistory({
    super.key,
    required this.onTap,
  });

  @override
  State<OrderOutDesktopHistory> createState() =>
      _OrderOutDesktopHistoryState();
}

class _OrderOutDesktopHistoryState
    extends State<OrderOutDesktopHistory> {

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

        // ================= SEARCH BAR =================
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
          .collection('order_out')
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
                (data['orderDate'] as Timestamp)
                    .toDate();

            if (date.year != _filterDate!.year ||
                date.month != _filterDate!.month ||
                date.day != _filterDate!.day) {
              return false;
            }
          }

          return true;

        }).toList();

        if (docs.isEmpty) {
          return const Center(
              child: Text('Belum ada Order'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (_, i) {

            final data =
                docs[i].data() as Map<String, dynamic>;

            final orderId = docs[i].id;

            return InkWell(
              onTap: () => widget.onTap(
                context,
                {
                  ...data,
                  'id': orderId,
                },
              ),
              child: _OrderHistoryCard(
                data: {
                  ...data,
                  'id': orderId,
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _OrderHistoryCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _OrderHistoryCard({
    required this.data,
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
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color:
              Colors.white.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
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
              style: const TextStyle(
                  fontSize: 12),
            ),
        ],
      ),
    );
  }
}