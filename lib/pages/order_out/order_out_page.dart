import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderOutPage extends StatefulWidget {
  final bool isCompact;
  final String? searchKeyword;

  const OrderOutPage({
    super.key,
    this.isCompact = false,
    this.searchKeyword,
  });

  @override
  State<OrderOutPage> createState() => _OrderOutPageState();
}

/// =====================================================
/// MODEL LOKAL ORDER ITEM
/// =====================================================
class OrderOutItem {
  final String partCode;
  final String name;
  final String nameEn;
  final String location;
  final int qty;
  final double weight;

  OrderOutItem({
    required this.partCode,
    required this.name,
    required this.nameEn,
    required this.location,
    required this.qty,
    required this.weight,
  });
}

class _OrderOutPageState extends State<OrderOutPage> {
  // ================= HEADER STATE (STEP 2) =================
  DateTime? orderDate;
  String? selectedClient;
  final TextEditingController poController = TextEditingController();

  // ================= STEP 3 STATE =================
  final List<OrderOutItem> items = [];

  @override
  void dispose() {
    poController.dispose();
    super.dispose();
  }

  // ================= DATE PICKER =================
  Future<void> _selectOrderDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: orderDate ?? now,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 3),
    );

    if (picked != null) {
      setState(() => orderDate = picked);
    }
  }

  // ================= OPEN ADD PART =================
  Future<void> _openAddPartSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddPartSheet(
        onAdd: (item) {
          setState(() {
            items.add(item);
          });
        },
      ),
    );
  }

  // ================= MAIN BUILD =================
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        floatingActionButton: widget.isCompact
            ? null
            : FloatingActionButton(
                child: const Icon(Icons.add),
                onPressed: _openAddPartSheet,
              ),
        body: Stack(
          children: [
            Container(
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
            ),
            SafeArea(
              child: Column(
                children: [
                  if (!widget.isCompact)
                    _OrderHeader(
                      orderDate: orderDate,
                      onPickDate: _selectOrderDate,
                      selectedClient: selectedClient,
                      onClientChanged: (v) =>
                          setState(() => selectedClient = v),
                      poController: poController,
                    ),

                  Expanded(
                    child: items.isEmpty
                        ? const Center(
                            child: Text(
                              'Belum ada item\nGunakan tombol +',
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: items.length,
                            itemBuilder: (_, i) {
                              final item = items[i];
                              return _ItemCard(item: item);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// =====================================================
/// HEADER (STEP 2 – TETAP)
/// =====================================================
class _OrderHeader extends StatelessWidget {
  final DateTime? orderDate;
  final VoidCallback onPickDate;
  final String? selectedClient;
  final ValueChanged<String?> onClientChanged;
  final TextEditingController poController;

  const _OrderHeader({
    required this.orderDate,
    required this.onPickDate,
    required this.selectedClient,
    required this.onClientChanged,
    required this.poController,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text('Order Out'),
                  ],
                ),
                const SizedBox(height: 12),
                _HeaderRow(
                  label: 'Order Date',
                  child: InkWell(
                    onTap: onPickDate,
                    child: _Box(
                      text: orderDate == null
                          ? 'Select date'
                          : '${orderDate!.day}/${orderDate!.month}/${orderDate!.year}',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _HeaderRow(
                  label: 'Client',
                  child: DropdownButtonFormField<String>(
                    initialValue: selectedClient,
                    items: const [
                      DropdownMenuItem(
                          value: 'Client A', child: Text('Client A')),
                      DropdownMenuItem(
                          value: 'Client B', child: Text('Client B')),
                    ],
                    onChanged: onClientChanged,
                  ),
                ),
                const SizedBox(height: 8),
                _HeaderRow(
                  label: 'PO Number',
                  child: TextField(controller: poController),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// =====================================================
/// ADD PART BOTTOM SHEET
/// =====================================================
class _AddPartSheet extends StatefulWidget {
  final ValueChanged<OrderOutItem> onAdd;

  const _AddPartSheet({required this.onAdd});

  @override
  State<_AddPartSheet> createState() => _AddPartSheetState();
}

class _AddPartSheetState extends State<_AddPartSheet> {
  final TextEditingController partCodeCtrl = TextEditingController();
  final TextEditingController qtyCtrl = TextEditingController();

  DocumentSnapshot? partDoc;
  String? error;

  Future<void> _searchPart() async {
    final snap = await FirebaseFirestore.instance
        .collection('spare_parts')
        .where('partCode', isEqualTo: partCodeCtrl.text.trim())
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      setState(() => error = 'Part tidak ditemukan');
      return;
    }

    setState(() {
      partDoc = snap.docs.first;
      error = null;
    });
  }

  void _add() {
    if (partDoc == null) return;

    final qty = int.tryParse(qtyCtrl.text) ?? 0;
    final stock = partDoc!['currentStock'] as int;

    if (qty <= 0 || qty > stock) {
      setState(() => error = 'Qty tidak valid / melebihi stock');
      return;
    }

    widget.onAdd(
      OrderOutItem(
        partCode: partDoc!['partCode'],
        name: partDoc!['name'],
        nameEn: partDoc!['nameEn'],
        location: partDoc!['location'],
        qty: qty,
        weight: (partDoc!['weight'] as num).toDouble() * qty,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: partCodeCtrl,
              decoration: const InputDecoration(labelText: 'Part Code'),
            ),
            ElevatedButton(
              onPressed: _searchPart,
              child: const Text('Search'),
            ),
            if (partDoc != null) ...[
              Text(partDoc!['nameEn']),
              Text('Stock: ${partDoc!['currentStock']}'),
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Qty'),
              ),
              ElevatedButton(
                onPressed: _add,
                child: const Text('Add'),
              ),
            ],
            if (error != null)
              Text(error!, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}

/// =====================================================
/// ITEM CARD
/// =====================================================
class _ItemCard extends StatelessWidget {
  final OrderOutItem item;

  const _ItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(item.nameEn),
        subtitle: Text(
          '${item.partCode} • ${item.location}',
        ),
        trailing: Text('Qty: ${item.qty}'),
      ),
    );
  }
}

/// =====================================================
/// SHARED WIDGETS
/// =====================================================
class _HeaderRow extends StatelessWidget {
  final String label;
  final Widget child;

  const _HeaderRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 90, child: Text(label)),
        Expanded(child: child),
      ],
    );
  }
}

class _Box extends StatelessWidget {
  final String text;

  const _Box({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text),
    );
  }
}
