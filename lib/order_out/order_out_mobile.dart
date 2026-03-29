import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/services/company_firestore.dart';
import '../pages/spare_part/spare_part_list_page.dart';
import '../../models/spare_part.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pages/partners/partner_list_page.dart';
import '../pages/order_out/order_out_detail_page.dart';
import '../theme/app_theme.dart';
import '../../models/read_tracker_service.dart';
import '../core/widgets/draggable_window.dart';
import '../core/cache/order_out_cache.dart';

class OrderOutMobile extends StatefulWidget {
  final String? searchKeyword;
  final bool autoCreate;
  final Map<String, dynamic>? initialEditData;
  final bool isAdmin;

  const OrderOutMobile({
    super.key,
    this.searchKeyword,
    this.autoCreate = false,
    this.initialEditData,
    this.isAdmin = false,
  });

  @override
  State<OrderOutMobile> createState() => _OrderOutPageState();
}

/// =====================================================
/// LOCAL MODEL
/// =====================================================
class OrderOutItem {
  final SparePart part;
  final int qty;

  OrderOutItem({
    required this.part,
    required this.qty,
  });
}

class _OrderOutPageState extends State<OrderOutMobile> {
  bool isAdmin = false;
  bool isCheckingAdmin = true;
  bool _isSaving = false;

  int get totalItem => items.length;
  int get totalQty => items.fold<int>(0, (sum, item) => sum + item.qty);
  double get totalWeight => items.fold<double>(0, (sum, item) => sum + (item.part.weight * item.qty));

  // ================= USER LOGIN HELPER =================
  String _getCurrentUsername() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'Unknown';
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    return user.email ?? 'Unknown';
  }

  // ================= CREATE ORDER STATE =================
  DateTime? orderDate;
  String? selectedClient;
  final TextEditingController poController = TextEditingController();
  final FocusNode fullscreenSearchFocusNode = FocusNode();
  List<OrderOutItem> items = [];

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ReadTrackerService().trackRead(
        page: 'OrderOutPage',
        collection: 'order_out',
        operation: 'page_open',
        documentsCount: 0,
      );
    });
    if (widget.autoCreate) {
      isCreateMode = true;
    }
    if (widget.initialEditData != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openEditOrder(widget.initialEditData!);
      });
    }
  }

  void _openEditOrder(Map<String, dynamic> data) {
    editingOrderId = data['id'];
    final orderItems = data['items'] as List<dynamic>;

    if (data['id'] == null) {
  _showError('Order ID missing (OrderOut)');
  return;
}

    setState(() {
      isCreateMode = true;
      isEditMode = true;
      editingOrderId = data['id'];
      orderDate = (data['orderDate'] as Timestamp).toDate();
      selectedClient = data['client'];
      poController.text = data['poNumber'];

      items.clear();
      for (final item in orderItems) {
        items.add(
          OrderOutItem(
            part: SparePart(
              id: item['partId'],
              partCode: item['partCode'],
              name: '',
              nameEn: item['nameEn'],
              location: item['location'],
              stock: 0,
              initialStock: 0,
              currentStock: 0,
              minimumStock: 0,
              weight: 0,
              weightUnit: 'pcs',
              imageUrl: '',
            ),
            qty: item['qty'],
          ),
        );
      }
    });
  }

  Future<void> _applyOrderOutTransaction({
    required String? orderId,
    required List<OrderOutItem> newItems,
    required bool isEdit,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final orderRef = isEdit
        ? CompanyFirestore.collection('order_out').doc(orderId)
        : CompanyFirestore.collection('order_out').doc();

    await firestore.runTransaction((tx) async {
      Map<String, int> stockMap = {};
      Map<String, int> aggregatedNewQty = {};

      for (final item in newItems) {
        aggregatedNewQty.update(
          item.part.id,
          (value) => value + item.qty,
          ifAbsent: () => item.qty,
        );
      }

      if (isEdit) {
        final oldSnap = await tx.get(orderRef);
        if (!oldSnap.exists) {
          throw Exception('Order tidak ditemukan');
        }
        final oldItems = List<Map<String, dynamic>>.from(oldSnap['items']);
        final Map<String, int> aggregatedOldQty = {};
        for (final old in oldItems) {
          aggregatedOldQty.update(
            old['partId'],
            (value) => value + (old['qty'] as int),
            ifAbsent: () => old['qty'] as int,
          );
        }
        for (final entry in aggregatedOldQty.entries) {
          final partRef = CompanyFirestore.collection('spare_parts').doc(entry.key);
          final snap = await tx.get(partRef);
          final currentStock = (snap['currentStock'] as num).toInt();
          stockMap[entry.key] = currentStock + entry.value;
        }
      }

      for (final entry in aggregatedNewQty.entries) {
        final partId = entry.key;
        if (!stockMap.containsKey(partId)) {
          final ref = CompanyFirestore.collection('spare_parts').doc(partId);
          final snap = await tx.get(ref);
          stockMap[partId] = (snap['currentStock'] as num).toInt();
        }
      }

      for (final entry in aggregatedNewQty.entries) {
        final partId = entry.key;
        final qty = entry.value;
        if (stockMap[partId]! < qty) {
          throw Exception('Stock tidak mencukupi');
        }
        stockMap[partId] = stockMap[partId]! - qty;
      }

      for (final entry in stockMap.entries) {
        tx.update(
          CompanyFirestore.collection('spare_parts').doc(entry.key),
          {'currentStock': entry.value},
        );
      }

      int totalItem = newItems.length;
      int totalQty = 0;
      double totalWeight = 0;

      for (final item in newItems) {
        totalQty += item.qty;
        totalWeight += item.part.weight * item.qty;
      }

      tx.set(orderRef, {
        'orderDate': Timestamp.fromDate(orderDate!),
        'client': selectedClient,
        'poNumber': poController.text.trim(),
        'items': newItems.map((e) => {
              'partId': e.part.id,
              'partCode': e.part.partCode,
              'nameEn': e.part.nameEn,
              'qty': e.qty,
              'location': e.part.location,
            }).toList(),
        'totalItem': totalItem,
        'totalQty': totalQty,
        'totalWeight': totalWeight,
        if (!isEdit) 'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': _getCurrentUsername(),
      }, SetOptions(merge: isEdit));
    });
  }

  Widget _buildFullscreenHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Order Out',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ================= FULLSCREEN SEARCH & FILTER =================
  final TextEditingController fullscreenSearchController = TextEditingController();
  DateTime? fullscreenFilterDate;

  bool isCreateMode = false;
  bool isEditMode = false;
  String? editingOrderId;

  @override
  void dispose() {
    poController.dispose();
    fullscreenSearchController.dispose();
    fullscreenSearchFocusNode.dispose();
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

  // ================= ADD PART =================
  Future<void> _addPart() async {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    SparePart? selected;

    if (isDesktop) {
      selected = await showGeneralDialog<SparePart>(
        context: context,
        barrierDismissible: true,
        barrierLabel: "SelectSparePart",
        barrierColor: Colors.black.withOpacity(0.35),
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (_, __, ___) {
          return DraggableResizableWindow(
            title: "Select Spare Part",
            child: const SparePartListPage(
              selectionMode: true,
              isWindow: true,
            ),
          );
        },
      );
    } else {
      selected = await Navigator.push<SparePart>(
        context,
        MaterialPageRoute(
          builder: (_) => const SparePartListPage(
            selectionMode: true,
          ),
        ),
      );
    }

    if (selected == null) return;

    final snap = await CompanyFirestore.collection('spare_parts').doc(selected.id).get();
    final firestoreStock = (snap['currentStock'] as num).toInt();

    final int? qty = await _showQtyDialog(part: selected, firestoreStock: firestoreStock);
    if (qty == null) return;

    setState(() {
      items.add(OrderOutItem(part: selected!, qty: qty));
    });
  }

  Future<void> _editItemAtIndex(int index) async {
    final current = items[index];
    final snap = await CompanyFirestore.collection('spare_parts').doc(current.part.id).get();

    final confirm = await showDialog<bool>(
  context: context,
  builder: (_) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    title: const Text('Edit Quantity'),
    content: const Text('Do you want to change the quantity of this item?'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('Cancel'),
      ),
      ElevatedButton(
        onPressed: () => Navigator.pop(context, true),
        child: const Text('Continue'),
      ),
    ],
  ),
);

if (confirm != true) return;

    if (!snap.exists) {
      _showError('Spare part tidak ditemukan');
      return;
    }

    final firestoreStock = (snap['currentStock'] as num).toInt();
    final availableStock = firestoreStock + current.qty;

    final partForEdit = SparePart(
      id: current.part.id,
      partCode: current.part.partCode,
      name: current.part.name,
      nameEn: current.part.nameEn,
      location: current.part.location,
      stock: availableStock,
      initialStock: availableStock,
      currentStock: availableStock,
      minimumStock: current.part.minimumStock,
      weight: current.part.weight,
      weightUnit: current.part.weightUnit,
      imageUrl: current.part.imageUrl,
    );

    final int? newQty = await _showQtyDialog(part: partForEdit, firestoreStock: firestoreStock);
    if (newQty == null) return;

    setState(() {
  final newList = List<OrderOutItem>.from(items);

  newList[index] = OrderOutItem(
    part: current.part,
    qty: newQty,
  );

  items = newList; // 🔥 penting
});
  }

  void _removeItemAtIndex(int index) async {
    final confirm = await _confirmDeleteItem(context);
    if (confirm) setState(() => items.removeAt(index));
  }

  // ================= QTY DIALOG =================
  Future<int?> _showQtyDialog({required SparePart part, required int firestoreStock}) async {
    int qty = 1;
    final controller = TextEditingController(text: '1');
    String? error;

    return showDialog<int>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            void increase() {
              if (qty < firestoreStock) {
                setLocal(() {
                  qty++;
                  controller.text = qty.toString();
                  error = null;
                });
              }
            }

            void decrease() {
              if (qty > 1) {
                setLocal(() {
                  qty--;
                  controller.text = qty.toString();
                  error = null;
                });
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(part.partCode, style: const TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(part.nameEn, style: const TextStyle(color: Color(0xFF64748B))),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Available: $firestoreStock',
                      style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: decrease,
                      ),
                      SizedBox(
                        width: 70,
                        child: TextField(
                          controller: controller,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            final value = int.tryParse(v) ?? 0;
                            setLocal(() {
                              qty = value;
                            });
                          },
                          decoration: InputDecoration(
                            isDense: true,
                            border: const OutlineInputBorder(),
                            errorText: error,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: increase,
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (qty <= 0) {
                      setLocal(() => error = 'Qty tidak valid');
                      return;
                    }
                    if (qty > firestoreStock) {
                      setLocal(() => error = 'Qty melebihi stock');
                      return;
                    }
                    Navigator.pop(ctx, qty);
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ================= COMMIT FIRESTORE =================
  Future<void> _commitOrderOut() async {

    final confirm = await showDialog<bool>(
  context: context,
  builder: (_) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    title: const Text('Save Order'),
    content: const Text('Are you sure you want to save this order?'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('Cancel'),
      ),
      ElevatedButton(
        onPressed: () => Navigator.pop(context, true),
        child: const Text('Save'),
      ),
    ],
  ),
);

if (confirm != true) return;

    if (_isSaving) return;
    setState(() => _isSaving = true);

    if (orderDate == null || selectedClient == null || poController.text.trim().isEmpty || items.isEmpty) {
      setState(() => _isSaving = false);
      _showError('Lengkapi semua data');
      return;
    }

    try {
      await _applyOrderOutTransaction(
        orderId: editingOrderId,
        newItems: items,
        isEdit: isEditMode,
      );

      ReadTrackerService().trackRead(
        page: 'OrderOutPage',
        collection: 'order_out',
        operation: isEditMode ? 'edit' : 'create',
        documentsCount: items.length,
      );

      setState(() {
  isCreateMode = false;
  isEditMode = false;
  editingOrderId = null;
  items.clear();
  orderDate = null;
  selectedClient = null;
  poController.clear();
  _isSaving = false;
});

// 🔥 FORCE REFRESH LIST
await Future.delayed(const Duration(milliseconds: 200));
if (mounted) {
  setState(() {}); // trigger rebuild parent
}

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order berhasil disimpan'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isSaving = false);
      _showError(e.toString());
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: (!isCreateMode)
            ? FloatingActionButton.extended(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                onPressed: () => setState(() => isCreateMode = true),
                icon: const Icon(Icons.add),
                label: const Text('New Order'),
              )
            : null,
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.backgroundGradient,
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  _buildFullscreenHeader(),
                  if (!isCreateMode)
                    _OrderOutSearchFilterBar(
                      controller: fullscreenSearchController,
                      focusNode: fullscreenSearchFocusNode,
                      filterDate: fullscreenFilterDate,
                      onPickDate: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: fullscreenFilterDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() => fullscreenFilterDate = picked);
                        }
                      },
                      onClearDate: () => setState(() => fullscreenFilterDate = null),
                      onSearch: (_) => setState(() {}),
                    ),
                  Expanded(
                    child: isCreateMode
                        ? _buildCreateForm()
                        : _OrderOutListView(
                            isAdmin: isAdmin,
                            searchKeyword: fullscreenSearchController.text,
                            filterDate: fullscreenFilterDate,
                            onTap: (context, data) async {
                              ReadTrackerService().trackRead(
                                page: 'OrderOutPage',
                                collection: 'order_out',
                                operation: 'open_detail',
                                documentsCount: 1,
                              );
                              final isDesktop = MediaQuery.of(context).size.width >= 900;

dynamic result;

if (isDesktop) {
  await showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    builder: (context) {
      return DraggableResizableWindow(
        title: "Order Out Detail",
        headerColor: Colors.red,
        child: OrderOutDetailPage(
  data: data,
  isWindow: true,
  onEdit: (editData) {
    Navigator.of(context).pop();
    _openEditOrder(editData);
  },
),
      );
    },
  );
} else {
  result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => OrderOutDetailPage(data: data),
    ),
  );
}

if (result != null && result is Map<String, dynamic>) {
  _openEditOrder(result);
}
                              if (result != null && result is Map<String, dynamic>) {
                                _openEditOrder(result);
                              }
                            },
                            onDelete: (id, _) => _deleteOrder(id),
                            onEdit: (_) {},
                          ),
                  ),
                ],
              ),
            ),
            if (_isSaving)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateForm() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;
        final isFormValid = orderDate != null &&
            selectedClient != null &&
            poController.text.trim().isNotEmpty &&
            items.isNotEmpty;

        if (!isDesktop) {
          return Column(
            children: [
              if (isEditMode)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  color: Colors.orange.shade100,
                  child: const Text(
                    'EDIT MODE',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _OrderHeader(
                      orderDate: orderDate,
                      onPickDate: _selectOrderDate,
                      selectedClient: selectedClient,
                      onClientChanged: (v) => setState(() => selectedClient = v),
                      poController: poController,
                      onSave: _commitOrderOut,
                      onBack: () => setState(() {
                        isCreateMode = false;
                        isEditMode = false;
                        editingOrderId = null;
                      }),
                      isSaving: _isSaving,
                      isFormValid: isFormValid,
                      isEditMode: isEditMode,
                    ),
                    const SizedBox(height: 10),
if (items.isNotEmpty)
  Builder(
    builder: (_) {
      final qty = totalQty;
      final itemCount = totalItem;
      final weight = totalWeight;

      return Row(
        children: [
          _summaryChip(Icons.list_alt, '$itemCount Item'),
          const SizedBox(width: 8),
          _summaryChip(Icons.inventory_2, '$qty Qty'),
          const SizedBox(width: 8),
          _summaryChip(Icons.scale, '${weight.toStringAsFixed(2)} kg'),
        ],
      );
    },
  ),
                  ],
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? const Center(child: Text('No item'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        itemBuilder: (_, i) => _ItemCard(
                          item: items[i],
                          onEdit: () => _editItemAtIndex(i),
                          onDelete: () => _removeItemAtIndex(i),
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: OutlinedButton.icon(
                  onPressed: _addPart,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: constraints.maxWidth * 0.35,
                      child: _buildDesktopFormPanel(),
                    ),
                    const SizedBox(width: 32),
                    Expanded(
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              onPressed: _addPart,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Item'),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: items.isEmpty
                                ? const Center(child: Text('No item'))
                                : ListView.builder(
                                    itemCount: items.length,
                                    itemBuilder: (_, i) => Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.grey.shade200),
                                      ),
                                      child: ListTile(
                                        title: Text(
                                          items[i].part.partCode,
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                        subtitle: Text(
                                          items[i].part.nameEn,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Qty: ${items[i].qty}',
                                              style: const TextStyle(fontWeight: FontWeight.w500),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.edit, size: 18),
                                              onPressed: () => _editItemAtIndex(i),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                              onPressed: () => _removeItemAtIndex(i),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    'Total Item: $totalItem',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 24),
                  Text(
                    'Total Qty: $totalQty',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 220,
                    child: ElevatedButton.icon(
                      onPressed: (isFormValid && !_isSaving) ? _commitOrderOut : null,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Order Out'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDesktopFormPanel() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Out',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 24),
          _buildFormField(
            label: 'Order Date *',
            child: InkWell(
              onTap: _selectOrderDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  orderDate == null
                      ? 'Select date'
                      : '${orderDate!.day}/${orderDate!.month}/${orderDate!.year}',
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildFormField(
            label: 'Client *',
            child: InkWell(
              onTap: () async {
                final partner = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PartnerListPage(selectionMode: true),
                  ),
                );
                if (partner != null) {
                  setState(() => selectedClient = partner.name);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(selectedClient ?? 'Select Partner'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildFormField(
            label: 'PO Number *',
            child: TextField(
              controller: poController,
              readOnly: isEditMode,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: isEditMode ? const Icon(Icons.lock, size: 18) : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _summaryChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color.fromARGB(255, 210, 44, 15)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDeleteItem(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Item'),
        content: const Text('Yakin ingin menghapus item ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _checkAdminAccess() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      setState(() {
        isAdmin = false;
        isCheckingAdmin = false;
      });
      return;
    }
    final email = user.email!.toLowerCase().trim();
    final doc = await FirebaseFirestore.instance
        .collection('admin_whitelist')
        .doc(email)
        .get();
    setState(() {
      isAdmin = doc.exists && doc.data()?['active'] == true;
      isCheckingAdmin = false;
    });
  }

  Future<void> _deleteOrder(String orderId) async {
    final confirmed = await _confirmDeleteOrder(context);
    if (!confirmed) return;

    await CompanyFirestore.collection('order_out').doc(orderId).delete();

    ReadTrackerService().trackRead(
      page: 'OrderOutPage',
      collection: 'order_out',
      operation: 'delete',
      documentsCount: 1,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order berhasil dihapus'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

Future<bool> _confirmDeleteOrder(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Hapus Order'),
      content: const Text('Order ini akan dihapus dan tidak bisa dikembalikan.\nLanjutkan?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Hapus'),
        ),
      ],
    ),
  );
  return result == true;
}

/// =====================================================
/// FULLSCREEN LIST
/// =====================================================
class _OrderOutListView extends StatefulWidget {
  final String searchKeyword;
  final DateTime? filterDate;
  final void Function(BuildContext, Map<String, dynamic>) onTap;
  final void Function(String orderId, Map<String, dynamic> data)? onDelete;
  final void Function(Map<String, dynamic> data)? onEdit;
  final bool isAdmin;

  const _OrderOutListView({
    required this.searchKeyword,
    required this.filterDate,
    required this.onTap,
    required this.onDelete,
    required this.onEdit,
    this.isAdmin = false,
  });

  @override
  State<_OrderOutListView> createState() => _OrderOutListViewState();
}

class _OrderOutListViewState extends State<_OrderOutListView> {
  static const int _limit = 20;
  List<DocumentSnapshot> _docs = [];
  int _page = 1;
  List<Map<String, dynamic>> _cachedDocs = [];
  DocumentSnapshot? _lastDoc;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool get _isFiltering =>
    widget.searchKeyword.isNotEmpty || widget.filterDate != null;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadFromCache();
    _scrollController.addListener(() {
      if (widget.searchKeyword.isNotEmpty || widget.filterDate != null) return;
      final threshold = 500;
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - threshold) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

 Future<void> _loadInitial() async {
  setState(() => _isLoading = true);

  try {
    Query query = CompanyFirestore
        .collection('order_out')
        .orderBy('orderDate', descending: true);

    // 🔥 kalau filtering → ambil SEMUA (no limit)
    if (!_isFiltering) {
      query = query.limit(_limit);
    }

    final snapshot = await query.get();

// ✅ TRACK READ
ReadTrackerService().trackRead(
  page: 'OrderOutList',
  collection: 'order_out',
  operation: 'load_initial',
  documentsCount: snapshot.docs.length,
);

_docs = snapshot.docs;
_lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
_hasMore = !_isFiltering && snapshot.docs.length == _limit;

    // cache tetap aman
    final safeList = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        ...data,
        'id': doc.id,
        'orderDate': (data['orderDate'] as Timestamp?)?.toDate().toIso8601String(),
        'createdAt': (data['createdAt'] as Timestamp?)?.toDate().toIso8601String(),
        'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate().toIso8601String(),
      };
    }).toList();

    const maxCache = 100;
    final limitedList =
        safeList.length > maxCache ? safeList.sublist(0, maxCache) : safeList;

    await OrderOutCache().save(limitedList);
  } catch (e) {
    debugPrint('Error load initial: $e');
  }

  if (mounted) {
    setState(() => _isLoading = false);
  }
}

  Future<void> _loadMore() async {
    if (_isFiltering) return;
    if (!_hasMore || _isLoadingMore || _lastDoc == null) return;
    if (_isLoading) return;
    setState(() => _isLoadingMore = true);
    _page++;

    try {
      final snapshot = await CompanyFirestore
          .collection('order_out')
          .orderBy('orderDate', descending: true)
          .startAfterDocument(_lastDoc!)
          .limit(_limit)
          .get();

          ReadTrackerService().trackRead(
  page: 'OrderOutList',
  collection: 'order_out',
  operation: 'load_more',
  documentsCount: snapshot.docs.length,
);

      if (snapshot.docs.isNotEmpty) {
        _docs.addAll(snapshot.docs);

        final safeList = _docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            ...data,
            'id': doc.id,
            'orderDate': (data['orderDate'] as Timestamp?)?.toDate().toIso8601String(),
            'createdAt': (data['createdAt'] as Timestamp?)?.toDate().toIso8601String(),
            'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate().toIso8601String(),
          };
        }).toList();

        if (_page % 3 == 0) {
          const maxCache = 100;
          final limitedList = safeList.length > maxCache ? safeList.sublist(0, maxCache) : safeList;
          await OrderOutCache().save(limitedList);
        }
        _lastDoc = snapshot.docs.last;
      }
      _hasMore = !_isFiltering && snapshot.docs.length == _limit;
    } catch (e) {
      debugPrint('Error load more: $e');
    }
    if (mounted) {
      setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_docs.isEmpty && _cachedDocs.isNotEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _cachedDocs.length,
        itemBuilder: (_, i) {
          final data = _cachedDocs[i];
          return InkWell(
            onTap: () => widget.onTap(context, data),
            child: _OrderHistoryCard(
              data: data,
              isAdmin: widget.isAdmin,
              onDelete: widget.isAdmin && widget.onDelete != null
                  ? () => widget.onDelete?.call(data['id'], data)
                  : null,
            ),
          );
        },
      );
    }

    final filtered = _docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final keyword = widget.searchKeyword.toLowerCase();

      if (keyword.isNotEmpty &&
          !data['poNumber'].toString().toLowerCase().contains(keyword) &&
          !data['client'].toString().toLowerCase().contains(keyword)) {
        return false;
      }

      if (widget.filterDate != null) {
        final date = (data['orderDate'] as Timestamp).toDate();
        if (date.year != widget.filterDate!.year ||
            date.month != widget.filterDate!.month ||
            date.day != widget.filterDate!.day) {
          return false;
        }
      }
      return true;
    }).toList();

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length + (_hasMore ? 1 : 0),
      itemBuilder: (_, i) {
        if (_hasMore && i == filtered.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final doc = filtered[i];
        final data = {
          ...(doc.data() as Map<String, dynamic>),
          'id': doc.id,
        };

        return InkWell(
          onTap: () => widget.onTap(context, data),
          child: _OrderHistoryCard(
            data: data,
            isAdmin: widget.isAdmin,
            onDelete: widget.isAdmin && widget.onDelete != null
                ? () => widget.onDelete?.call(doc.id, data)
                : null,
          ),
        );
      },
    );
  }

  Future<void> _loadFromCache() async {
    final cache = OrderOutCache();
    final cached = await cache.load();
    final expired = await cache.isExpired();

    if (cached.isNotEmpty) {
      setState(() {
        _cachedDocs = cached;
      });
    }

    if (cached.isEmpty || expired) {
      await _loadInitial();
    }
  }

 @override
void didUpdateWidget(covariant _OrderOutListView oldWidget) {
  super.didUpdateWidget(oldWidget);

  // 🔥 FORCE RELOAD SETIAP ADA PERUBAHAN
  _loadInitial();

  if (oldWidget.searchKeyword != widget.searchKeyword ||
      oldWidget.filterDate != widget.filterDate) {
    _loadInitial();
  }
}

}

/// =====================================================
/// HISTORY CARD
/// =====================================================
class _OrderHistoryCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isAdmin;
  final VoidCallback? onDelete;

  const _OrderHistoryCard({
    required this.data,
    required this.isAdmin,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final rawDate = data['orderDate'];
    DateTime? date;

    if (rawDate is Timestamp) {
      date = rawDate.toDate();
    } else if (rawDate is String) {
      date = DateTime.tryParse(rawDate);
    }

    final items = (data['items'] ?? []) as List;
    int totalItem = data['totalItem'] ?? items.length;
    int totalQty = data['totalQty'] ??
        items.fold<int>(0, (sum, item) => sum + (item['qty'] as int));
    double totalWeight = (data['totalWeight'] ?? 0).toDouble();

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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                       colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.inventory, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PO: ${data['poNumber']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Client: ${data['client']}',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                      ),
                      if (data['createdBy'] != null)
                        Text(
                          'Created By: ${data['createdBy']}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      if (date != null)
                        Text(
                          '${date.day}/${date.month}/${date.year}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                _summaryChip(Icons.list_alt, '$totalItem Item'),
                _summaryChip(Icons.inventory_2, '$totalQty Qty'),
                _summaryChip(Icons.scale, '${totalWeight.toStringAsFixed(2)} kg'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: const Color(0xFF475569)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
          ),
        ],
      ),
    );
  }
}

/// =====================================================
/// HEADER (CREATE FORM)
/// =====================================================
class _OrderHeader extends StatelessWidget {
  final DateTime? orderDate;
  final VoidCallback onPickDate;
  final String? selectedClient;
  final ValueChanged<String?> onClientChanged;
  final TextEditingController poController;
  final VoidCallback onSave;
  final VoidCallback onBack;
  final bool isSaving;
  final bool isFormValid;
  final bool isEditMode;

  const _OrderHeader({
    required this.orderDate,
    required this.onPickDate,
    required this.selectedClient,
    required this.onClientChanged,
    required this.poController,
    required this.onSave,
    required this.onBack,
    required this.isSaving,
    required this.isFormValid,
    required this.isEditMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack,
              ),
              const SizedBox(width: 8),
              const Text(
                'Order Out',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _formField(
            label: 'Order Date',
            child: InkWell(
              onTap: onPickDate,
              child: _box(
                orderDate == null
                    ? 'Select date'
                    : '${orderDate!.day}/${orderDate!.month}/${orderDate!.year}',
              ),
            ),
          ),
          const SizedBox(height: 12),
          _formField(
            label: 'Client',
            child: InkWell(
              onTap: () async {
                final partner = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PartnerListPage(selectionMode: true),
                  ),
                );
                if (partner != null) {
                  onClientChanged(partner.name);
                }
              },
              child: _box(selectedClient ?? 'Select Partner'),
            ),
          ),
          const SizedBox(height: 12),
          _formField(
            label: 'PO Number',
            child: TextField(
              controller: poController,
              readOnly: isEditMode,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: isEditMode ? const Icon(Icons.lock, size: 18) : null,
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (isFormValid && !isSaving) ? onSave : null,
              child: isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Order Out'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }

  Widget _box(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13),
      ),
    );
  }
}

/// =====================================================
/// ITEM CARD
/// =====================================================
class _ItemCard extends StatelessWidget {
  final OrderOutItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ItemCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        onTap: onEdit,
        title: Text(
          item.part.partCode,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          item.part.nameEn,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Qty: ${item.qty}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (item.part.location.isNotEmpty)
                  Text(
                    'Loc: ${item.part.location}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete, size: 18, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

/// =====================================================
/// SEARCH BAR
/// =====================================================
class _OrderOutSearchFilterBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final DateTime? filterDate;
  final VoidCallback onPickDate;
  final VoidCallback onClearDate;
  final ValueChanged<String> onSearch;

  const _OrderOutSearchFilterBar({
    required this.controller,
    required this.focusNode,
    required this.filterDate,
    required this.onPickDate,
    required this.onClearDate,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onSearch,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search PO / Client',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: onPickDate,
          ),
          if (filterDate != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: onClearDate,
            ),
        ],
      ),
    );
  }
}