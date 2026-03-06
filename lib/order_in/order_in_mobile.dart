import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/services/company_firestore.dart';
import '../pages/spare_part/spare_part_list_page.dart';
import '../../models/spare_part.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pages/partners/partner_list_page.dart';
import '../pages/order_in/order_in_detail_page.dart';

enum QtyDialogMode {
  orderIn,
  orderOut,
}

class OrderInMobile extends StatefulWidget {
  final bool isCompact;
  final String? searchKeyword;
  final bool autoCreate;
 final Map<String, dynamic>? initialEditData;

  const OrderInMobile({
    super.key,
    this.isCompact = false,
    this.searchKeyword,
    this.autoCreate = false,
    this.initialEditData,
  });

  @override
  State<OrderInMobile> createState() => _OrderInPageState();
}

/// =====================================================
/// LOCAL MODEL
/// =====================================================
class OrderInItem {
  final SparePart part;
  final int qty;

  OrderInItem({
    required this.part,
    required this.qty,
  });
}

class _OrderInPageState extends State<OrderInMobile> {
  bool isCreateMode = false;
  bool isEditMode = false;
  String? editingOrderId;

  @override
  void initState() {
    super.initState();

    if (widget.autoCreate) {
      isCreateMode = true;
    }

    if (widget.initialEditData != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openEditOrder(widget.initialEditData!);
      });
    }
  }

  int get totalItem => items.length;

int get totalQty =>
    items.fold<int>(0, (sum, item) => sum + item.qty);

double get totalWeight =>
    items.fold<double>(
      0,
      (sum, item) => sum + (item.part.weight * item.qty),
    );

  // ================= USER LOGIN HELPER =================
  String _getCurrentUsername() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return 'Unknown';
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    return user.email ?? 'Unknown';
  }

void _removeItemAtIndex(int index) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Hapus Item'),
      content: const Text('Yakin ingin menghapus item ini?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Hapus'),
        ),
      ],
    ),
  );

  if (confirm != true) return;

  setState(() {
    items.removeAt(index);
  });
}

  // ================= CREATE ORDER STATE =================
  DateTime? orderDate;
  String? selectedClient;
  final TextEditingController poController = TextEditingController();
  final FocusNode fullscreenSearchFocusNode = FocusNode();
  final List<OrderInItem> items = [];

  void _openEditOrder(Map<String, dynamic> data) {
    editingOrderId = data['id']; // ← sekarang VALID
  final orderItems = data['items'] as List<dynamic>;

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
        OrderInItem(
          part: SparePart(
            id: item['partId'],
            partCode: item['partCode'],
            name: '',
            nameEn: item['nameEn'],
            location: item['location'],

            // ===== FIELD WAJIB (DUMMY AMAN) =====
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

Future<void> _commitEditOrderIn() async {
  if (editingOrderId == null) {
    _showError('Order ID tidak valid');
    return;
  }

  if (orderDate == null ||
      selectedClient == null ||
      poController.text.trim().isEmpty ||
      items.isEmpty) {
    _showError('Data order belum lengkap');
    return;
  }

  final firestore = FirebaseFirestore.instance;
  final orderRef =
      CompanyFirestore.collection('order_in').doc(editingOrderId);

  try {
    await firestore.runTransaction((tx) async {
      // ===============================
      // 1. READ SEMUA DATA (WAJIB DI AWAL)
      // ===============================
      final oldSnap = await tx.get(orderRef);
      if (!oldSnap.exists) {
        throw Exception('Order tidak ditemukan');
      }

      final oldItems = oldSnap['items'] as List<dynamic>;

      final Map<String, int> stockMap = {};

      // baca stock part lama
      for (final old in oldItems) {
        final ref =
            CompanyFirestore.collection('spare_parts').doc(old['partId']);
        final snap = await tx.get(ref);
        stockMap[old['partId']] =
            (snap['currentStock'] as num).toInt();
      }

      // baca stock part baru (jika belum kebaca)
      for (final item in items) {
        if (!stockMap.containsKey(item.part.id)) {
          final ref = CompanyFirestore
              .collection('spare_parts')
              .doc(item.part.id);
          final snap = await tx.get(ref);
          stockMap[item.part.id] =
              (snap['currentStock'] as num).toInt();
        }
      }

      // ===============================
// 2. HITUNG STOCK FINAL (BENAR)
// ===============================

// rollback qty lama
for (final old in oldItems) {
  final oldQty = (old['qty'] as num).toInt();
  stockMap[old['partId']] =
      stockMap[old['partId']]! - oldQty;
}

// apply qty baru
for (final item in items) {
  stockMap[item.part.id] =
      stockMap[item.part.id]! + item.qty;
}

for (final entry in stockMap.entries) {
  if (entry.value < 0) {
    throw Exception('NEGATIVE_STOCK');
  }
}

      // ===============================
      // 3. WRITE (SETELAH SEMUA READ)
      // ===============================
      for (final entry in stockMap.entries) {
        tx.update(
          CompanyFirestore
              .collection('spare_parts')
              .doc(entry.key),
          {'currentStock': entry.value},
        );
      }

      tx.update(orderRef, {
        'orderDate': Timestamp.fromDate(orderDate!),
        'client': selectedClient,
        'poNumber': poController.text.trim().toUpperCase(),
        'items': items.map((e) => {
              'partId': e.part.id,
              'partCode': e.part.partCode,
              'nameEn': e.part.nameEn,
              'qty': e.qty,
              'location': e.part.location,
            }).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    if (!mounted) return;

    // reset UI
    setState(() {
      isEditMode = false;
      isCreateMode = false;
      editingOrderId = null;
      items.clear();
      orderDate = null;
      selectedClient = null;
      poController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order In berhasil diperbarui'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  } catch (e) {
  _handleError(e);
}
}


  Widget _buildFullscreenHeader() {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
    child: Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 8),
        const Text(
          'Order In',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

Future<void> _deleteOrder(
  BuildContext context,
  String orderId,
  Map<String, dynamic> data,
) async {
  final confirmed = await _confirmDeleteOrder(context);
  if (!confirmed) return;

  final firestore = FirebaseFirestore.instance;

  final orderRef =
      CompanyFirestore.collection('order_in').doc(orderId);

  try {
    await firestore.runTransaction((tx) async {
      final snap = await tx.get(orderRef);
      if (!snap.exists) return;

      final items = snap['items'] as List<dynamic>;

      final Map<String, int> qtyMap = {};

      for (final item in items) {
        final partId = item['partId'];
        final qty = item['qty'] as int;

        qtyMap[partId] = (qtyMap[partId] ?? 0) + qty;
      }

      for (final entry in qtyMap.entries) {
        final partRef =
            CompanyFirestore.collection('spare_parts')
                .doc(entry.key);

        final partSnap = await tx.get(partRef);
        final currentStock =
            (partSnap['currentStock'] as num).toInt();

        final newStock = currentStock - entry.value;

        if (newStock < 0) {
          throw Exception('NEGATIVE_STOCK');
        }

        tx.update(partRef, {
          'currentStock': newStock,
        });
      }

      tx.delete(orderRef);
    });

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order berhasil dihapus'),
        backgroundColor: Colors.redAccent,
        duration: Duration(seconds: 2),
      ),
    );
  } catch (e) {
    _handleError(e);
  }
}

  // ================= FULLSCREEN SEARCH & FILTER =================
  final TextEditingController fullscreenSearchController =
      TextEditingController();
  DateTime? fullscreenFilterDate;
  
  bool _isSaving = false;

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
    final SparePart? selected = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SparePartListPage(
          selectionMode: true,
        ),
      ),
    );

    if (selected == null) return;

    final snap = await CompanyFirestore
    .collection('spare_parts')
    .doc(selected.id)
    .get();

final firestoreStock =
    (snap['currentStock'] as num).toInt();

final int? qty = await _showQtyDialog(
  part: selected,
  mode: QtyDialogMode.orderIn,
  firestoreStock: firestoreStock,
);


    if (qty == null) return;

    final existingIndex =
    items.indexWhere((e) => e.part.id == selected.id);

if (existingIndex != -1) {
  setState(() {
    final current = items[existingIndex];
    items[existingIndex] = OrderInItem(
      part: current.part,
      qty: current.qty + qty,
    );
  });
} else {
  setState(() {
    items.add(OrderInItem(part: selected, qty: qty));
  });
}

  }
  
Future<void> _editItemAtIndex(int index) async {
  final current = items[index];

  final snap = await CompanyFirestore
      .collection('spare_parts')
      .doc(current.part.id)
      .get();

  if (!snap.exists) {
    _showError('Spare part tidak ditemukan');
    return;
  }

  final firestoreStock =
    (snap['currentStock'] as num).toInt(); // 100

final rollbackStock =
    firestoreStock - current.qty;

final partForEdit = SparePart(
  id: current.part.id,
  partCode: current.part.partCode,
  name: current.part.name,
  nameEn: current.part.nameEn,
  location: current.part.location,

  // 🔢 dipakai untuk LOGIKA (rollback)
  stock: rollbackStock,
  initialStock: rollbackStock,
  currentStock: rollbackStock,

  minimumStock: current.part.minimumStock,
  weight: current.part.weight,
  weightUnit: current.part.weightUnit,
  imageUrl: current.part.imageUrl,
);


  final int? newQty = await _showQtyDialog(
  part: partForEdit,
  mode: QtyDialogMode.orderIn,
  firestoreStock: firestoreStock,
);


  if (newQty == null) return;

  setState(() {
    items[index] = OrderInItem(
      part: current.part,
      qty: newQty,
    );
  });
}

  // ================= QTY DIALOG =================
  Future<int?> _showQtyDialog({
  required SparePart part,
  required QtyDialogMode mode,
  required int firestoreStock,
}) async {

  int qty = 1;
  final controller = TextEditingController(text: '1');
  String? error;

  return showDialog<int>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setLocal) {

          void increase() {
            setLocal(() {
              qty++;
              controller.text = qty.toString();
              error = null;
            });
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
            title: Text(part.partCode),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(part.nameEn),
                const SizedBox(height: 8),

                /// INFO STOCK (hanya info)
                Text('Stock saat ini: $firestoreStock'),

                const SizedBox(height: 16),

                /// ===== QTY STEPPER =====
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

                  /// VALIDASI KHUSUS ORDER OUT
                  if (mode == QtyDialogMode.orderOut &&
                      qty > part.currentStock) {
                    setLocal(() => error = 'Qty melebihi stock');
                    return;
                  }

                  Navigator.pop(ctx, qty);
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      );
    },
  );
}


  // ================= COMMIT FIRESTORE =================
  Future<void> _commitOrderIn() async {

    if (_isSaving) return;

setState(() {
  _isSaving = true;
});

  if (isEditMode) {
  try {
    await _commitEditOrderIn();
  } finally {
    if (mounted) {
      setState(() => _isSaving = false);
    }
  }
  return;
}


 if (orderDate == null ||
    selectedClient == null ||
    poController.text.trim().isEmpty ||
    items.isEmpty) {

  setState(() => _isSaving = false);

  _showError('Lengkapi Order Date, Client, PO, dan Item');
  return;
}


  final firestore = FirebaseFirestore.instance;
  final poNormalized = poController.text.trim().toUpperCase();

final orderRef =
   CompanyFirestore.collection('order_in').doc(poNormalized);

  try {
    await firestore.runTransaction((tx) async {

       final existing = await tx.get(orderRef);
  if (existing.exists) {
    throw Exception('PO_DUPLICATE');
  }
      // 1. VALIDASI & POTONG STOCK
      // ===============================
// GROUP BY PART ID
// ===============================
final Map<String, int> qtyMap = {};

for (final item in items) {
  qtyMap[item.part.id] =
      (qtyMap[item.part.id] ?? 0) + item.qty;
}


// ===============================
// UPDATE STOCK SEKALI PER PART
// ===============================
for (final entry in qtyMap.entries) {
  final partRef =
      CompanyFirestore.collection('spare_parts').doc(entry.key);

  final snap = await tx.get(partRef);
  final stock = (snap['currentStock'] as num).toInt();

  tx.update(partRef, {
    'currentStock': stock + entry.value,
  });
}

int totalItem = items.length;
int totalQty = 0;
double totalWeight = 0;

for (final item in items) {
  totalQty += item.qty;
  totalWeight += item.part.weight * item.qty;
}


      // 2. SIMPAN ORDER BARU
      tx.set(orderRef, {
  'orderDate': Timestamp.fromDate(orderDate!),
  'client': selectedClient,
  'poNumber': poNormalized,
  'createdAt': FieldValue.serverTimestamp(),
  'createdBy': _getCurrentUsername(),

  'totalItem': totalItem,
  'totalQty': totalQty,
  'totalWeight': totalWeight,

  'items': items.map((e) => {
    'partId': e.part.id,
    'partCode': e.part.partCode,
    'nameEn': e.part.nameEn,
    'qty': e.qty,
    'location': e.part.location,
  }).toList(),
});
    });

    if (!mounted) return;

    setState(() {
      isCreateMode = false;
      items.clear();
      orderDate = null;
      selectedClient = null;
      poController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text('Order In berhasil dibuat'),
    backgroundColor: Colors.green,
    duration: Duration(seconds: 2),
  ),
);
  } catch (e) {
  if (e.toString().contains('PO_DUPLICATE')) {
    _showError('PO Number sudah pernah digunakan');
  } else {
    _handleError(e);
  }
}
finally {
  if (mounted) {
    setState(() {
      _isSaving = false;
    });
  }
}

}

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
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

  // ================= ORDER DETAIL =================
  void _showOrderDetail(
      BuildContext context, Map<String, dynamic> data) {
    final items = data['items'] as List<dynamic>;

    final DateTime? orderDate =
    (data['orderDate'] as Timestamp?)?.toDate();


    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PO: ${data['poNumber']}',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text('Client: ${data['client']}'),

const SizedBox(height: 4),

Text(
  orderDate == null
      ? 'Date: -'
      : 'Date: '
        '${orderDate.day.toString().padLeft(2, '0')}/'
        '${orderDate.month.toString().padLeft(2, '0')}/'
        '${orderDate.year}',
  style: const TextStyle(fontSize: 13),
),

              
              if (data['createdBy'] != null)
  Text(
    'Created By: ${data['createdBy']}',
    style: const TextStyle(fontSize: 12),
  ),
              const Divider(height: 24),
              SizedBox(
                height: 250,
                child: ListView.builder(
  physics: const BouncingScrollPhysics(),
  itemCount: items.length,
  itemBuilder: (_, i) {
                    final item = items[i];
                    return ListTile(
  dense: true,
  title: Text(item['partCode']),
  subtitle: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(item['nameEn']),
      const SizedBox(height: 2),
      Text(
        'Location: ${item['location'] ?? '-'}',
        style: const TextStyle(
          fontSize: 12,
          color: Colors.black54,
        ),
      ),
    ],
  ),
  trailing: Text('Qty: ${item['qty']}'),
);

                  },
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
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
    ? FloatingActionButton(
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        onPressed: () => setState(() => isCreateMode = true),
        child: const Icon(Icons.add),
      )
    : null,

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
                      _buildFullscreenHeader(),

                      if (!isCreateMode)
                        _OrderInSearchFilterBar(
                          controller: fullscreenSearchController,
                          focusNode: fullscreenSearchFocusNode,
                          filterDate: fullscreenFilterDate,
                          onPickDate: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate:
                                  fullscreenFilterDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setState(() =>
                                  fullscreenFilterDate = picked);
                            }
                          },
                          onClearDate: () =>
                              setState(() => fullscreenFilterDate = null),
                          onSearch: (_) => setState(() {}),
                        ),

                      Expanded(
                        child: isCreateMode
                            ? _buildCreateForm()
                            : _OrderInListView(
  searchKeyword: fullscreenSearchController.text,
  filterDate: fullscreenFilterDate,

  onTap: (context, data) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderInDetailPage(data: data),
      ),
    );

    if (result != null && context.mounted) {
      _openEditOrder(result);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mode edit diaktifkan'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  },

  onDelete: (orderId, data) {
    _deleteOrder(context, orderId, data);
  },

  onEdit: (data) async {
    final confirm = await _confirmEditOrder(context);
    if (!confirm) return;

    _openEditOrder(data);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mode edit diaktifkan'),
        duration: Duration(seconds: 2),
      ),
    );
  },
)
                      )
                    ],
                  ),
          ),
          if (_isSaving)
  Container(
    color: Colors.black.withValues(alpha:0.3),
    child: const Center(
      child: CircularProgressIndicator(),
    ),
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
      final isFormValid =
    orderDate != null &&
    selectedClient != null &&
    poController.text.trim().isNotEmpty &&
    items.isNotEmpty;

      if (!isDesktop) {
        // ===== MOBILE LAYOUT (UNCHANGED) =====
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
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
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
        onClientChanged: (v) =>
            setState(() => selectedClient = v),
        poController: poController,
        onSave: _commitOrderIn,
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
        Row(
          children: [
            _summaryChip(Icons.list_alt, '$totalItem Item'),
            const SizedBox(width: 8),
            _summaryChip(Icons.inventory_2, '$totalQty Qty'),
            const SizedBox(width: 8),
            _summaryChip(
              Icons.scale,
              '${totalWeight.toStringAsFixed(2)} kg',
            ),
          ],
        ),
    ],
  ),
),
            Expanded(
              child: items.isEmpty
                  ? const Center(child: Text('Belum ada item'))
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
                label: const Text('Tambah Item'),
              ),
            ),
          ],
        );
      }

      // ===== DESKTOP LAYOUT =====

final desktopTotalItem = items.length;
final desktopTotalQty = items.fold<int>(
  0,
  (total, e) => total + e.qty,
);

return Column(
  children: [

    // ===== MAIN CONTENT =====
    Expanded(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ===== LEFT PANEL =====
            SizedBox(
              width: constraints.maxWidth * 0.35,
              child: _buildDesktopFormPanel(),
            ),

            const SizedBox(width: 32),

            // ===== RIGHT PANEL =====
            Expanded(
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _addPart,
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah Item'),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Expanded(
                    child: items.isEmpty
                        ? const Center(
                            child: Text('Belum ada item'),
                          )
                        : ListView.builder(
                            itemCount: items.length,
                            itemBuilder: (_, i) => Card(
                              child: ListTile(
                                title: Text(items[i].part.partCode),
                                subtitle: Text(items[i].part.nameEn),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Qty: ${items[i].qty}'),
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () =>
                                          _editItemAtIndex(i),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.redAccent,
                                      ),
                                      onPressed: () =>
                                          _removeItemAtIndex(i),
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

    // ===== STICKY SUMMARY BAR =====
    Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [

          Text(
            'Total Item: $desktopTotalItem',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(width: 24),

          Text(
            'Total Qty: $desktopTotalQty',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),

          const Spacer(),

          SizedBox(
            width: 220,
            child: ElevatedButton.icon(
              onPressed: (isFormValid && !_isSaving)
    ? _commitOrderIn
    : null,
              icon: const Icon(Icons.save),
              label: const Text('Save Order In'),
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
        'Order In',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 24),

      const Text(
  'Order Date *',
  style: TextStyle(fontWeight: FontWeight.w600),
),
      const SizedBox(height: 6),
      InkWell(
        onTap: _selectOrderDate,
        child: _Box(
          text: orderDate == null
              ? 'Select date'
              : '${orderDate!.day}/${orderDate!.month}/${orderDate!.year}',
        ),
      ),

      const SizedBox(height: 16),

      const Text(
  'Client *',
  style: TextStyle(fontWeight: FontWeight.w600),
),

      const SizedBox(height: 6),

     InkWell(
  onTap: () async {
    final partner = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PartnerListPage(
          selectionMode: true,
        ),
      ),
    );

    if (partner != null) {
      setState(() {
        selectedClient = partner.name;
      });
    }
  },
  child: _Box(
    text: selectedClient ?? 'Select Partner',
  ),
),

      const SizedBox(height: 16),

      const Text(
  'PO Number *',
  style: TextStyle(fontWeight: FontWeight.w600),
),

      const SizedBox(height: 6),
      TextField(
  controller: poController,
  readOnly: isEditMode,
  decoration: InputDecoration(
    border: const OutlineInputBorder(),
    errorText: poController.text.isEmpty && isCreateMode
        ? 'Required'
        : null,
  ),
  onChanged: (_) => setState(() {}),
),

    ],
  )
  );
}
void _handleError(Object e) {
  final message = e.toString();

  if (message.contains('PO_DUPLICATE')) {
    _showError('PO Number sudah pernah digunakan');
  } else if (message.contains('NEGATIVE_STOCK')) {
    _showError('Stock menjadi negatif. Operasi dibatalkan.');
  } else {
    _showError('Terjadi kesalahan. Silakan coba lagi.');
  }
}

Widget _summaryChip(IconData icon, String text) {
  return Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 10,
      vertical: 6,
    ),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.5),
      ),
    ),
    child: Row(
      children: [
        Icon(icon, size: 14),
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

}

/// =====================================================
/// FULLSCREEN LIST
/// =====================================================
class _OrderInListView extends StatelessWidget {
  final String searchKeyword;
  final DateTime? filterDate;
  final void Function(BuildContext, Map<String, dynamic>) onTap;
  final void Function(String orderId, Map<String, dynamic> data) onDelete;
  final void Function(Map<String, dynamic> data) onEdit;


  const _OrderInListView({
    required this.searchKeyword,
    required this.filterDate,
    required this.onTap,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
      Query query = CompanyFirestore
    .collection('order_in')
    .orderBy('createdAt', descending: true);

if (filterDate != null) {
  final start = DateTime(
    filterDate!.year,
    filterDate!.month,
    filterDate!.day,
  );

  final end = start.add(const Duration(days: 1));

  query = query
      .where('orderDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(start))
      .where('orderDate',
          isLessThan: Timestamp.fromDate(end));
}

return StreamBuilder<QuerySnapshot>(
  stream: query.snapshots(),

      builder: (_, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final keyword = searchKeyword.toLowerCase();
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
          return true;
        }).toList();

        if (docs.isEmpty) {
          return const Center(child: Text('Belum ada Order'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (_, i) {
  final data = docs[i].data() as Map<String, dynamic>;
  final orderId = docs[i].id; // ✅ AMAN

  return InkWell(
    onTap: () => onTap(context, data),
    child: _OrderHistoryCard(
      data: {
        ...data,
        'id': orderId, // inject id dengan BENAR
      },
      isFullscreen: true,
      onDelete: () => onDelete(orderId, data),
      onEdit: () => onEdit({
  ...data,
  'id': orderId,
}),

    ),
  );
},

        );
      },
    );
  }
}

/// =====================================================
/// HISTORY CARD
/// =====================================================
class _OrderHistoryCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isFullscreen;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const _OrderHistoryCard({
    required this.data,
    this.isFullscreen = false,
    this.onDelete,
    this.onEdit,
  });


  @override
Widget build(BuildContext context) {
  final date =
      (data['orderDate'] as Timestamp?)?.toDate();
      final items = (data['items'] ?? []) as List;

int totalItem = data['totalItem'] ?? items.length;

int totalQty = data['totalQty'] ??
    items.fold<int>(
      0,
      (sum, item) => sum + (item['qty'] as int),
    );

double totalWeight = (data['totalWeight'] ?? 0).toDouble();

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
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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

const SizedBox(height: 8),

Row(
  children: [

    _summaryChip(
      Icons.list_alt,
      '$totalItem Item',
    ),

    const SizedBox(width: 8),

    _summaryChip(
      Icons.inventory_2,
      '$totalQty Qty',
    ),

    const SizedBox(width: 8),

    _summaryChip(
      Icons.scale,
      '${totalWeight.toStringAsFixed(2)} kg',
    ),
  ],
),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _summaryChip(IconData icon, String text) {
  return Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 8,
      vertical: 4,
    ),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Icon(icon, size: 14),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 12),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.35)),
          ),
          child: Column(
            children: [
              // ===== HEADER ROW =====
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: onBack,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Order In',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ===== ORDER DATE =====
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

              // ===== CLIENT =====
             _HeaderRow(
  label: 'Client',
  child: InkWell(
    onTap: () async {
      final partner = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const PartnerListPage(
            selectionMode: true,
          ),
        ),
      );

      if (partner != null) {
        onClientChanged(partner.name);
      }
    },
    child: _Box(
      text: selectedClient ?? 'Select Partner',
    ),
  ),
),


              const SizedBox(height: 8),

              // ===== PO NUMBER =====
              _HeaderRow(
                label: 'PO Number',
                child: TextField(
  controller: poController,
  readOnly: isEditMode,
  decoration: InputDecoration(
    border: const OutlineInputBorder(),
    suffixIcon: isEditMode
        ? const Icon(Icons.lock, size: 18)
        : null,
  ),
),

              ),

              const SizedBox(height: 16),

              // ===== SAVE BUTTON =====
              SizedBox(
  width: 220,
  child: ElevatedButton(
    onPressed: (isFormValid && !isSaving)
        ? onSave
        : null,
    child: isSaving
        ? const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.save),
              SizedBox(width: 8),
              Text('Save Order In'),
            ],
          ),
  ),
),



            ],
          ),
        ),
      ),
    );
  }
}


/// =====================================================
/// ITEM CARD
/// =====================================================
class _ItemCard extends StatelessWidget {
  final OrderInItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ItemCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onEdit,
      title: Text(item.part.partCode),
      subtitle: Text(item.part.nameEn),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Qty: ${item.qty}'),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(
              Icons.delete,
              size: 20,
              color: Colors.redAccent,
            ),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}


/// =====================================================
/// SEARCH BAR
/// =====================================================
class _OrderInSearchFilterBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final DateTime? filterDate;
  final VoidCallback onPickDate;
  final VoidCallback onClearDate;
  final ValueChanged<String> onSearch;

  const _OrderInSearchFilterBar({
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
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search PO / Client',
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
/// =====================================================
/// SHARED HEADER ROW
/// =====================================================
class _HeaderRow extends StatelessWidget {
  final String label;
  final Widget child;

  const _HeaderRow({
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: child),
      ],
    );
  }
}

/// =====================================================
/// SHARED BOX (DATE DISPLAY)
/// =====================================================
class _Box extends StatelessWidget {
  final String text;

  const _Box({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13),
      ),
    );
  }
}
Future<bool> _confirmEditOrder(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Edit Order'),
      content: const Text('Apakah Anda yakin ingin mengedit order ini?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Edit'),
        ),
      ],
    ),
  );

  return result == true;
}
Future<bool> _confirmDeleteOrder(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Hapus Order'),
      content: const Text(
        'Order ini akan dihapus dan stock akan dikembalikan.\nLanjutkan?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Hapus'),
        ),
      ],
    ),
  );

  return result == true;
}
