import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../spare_part/spare_part_list_page.dart';
import '../../models/spare_part.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum QtyDialogMode {
  orderIn,
  orderOut,
}

class OrderInPage extends StatefulWidget {
  final bool isCompact;
  final String? searchKeyword;

  const OrderInPage({
    super.key,
    this.isCompact = false,
    this.searchKeyword,
  });

  @override
  State<OrderInPage> createState() => _OrderInPageState();
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

class _OrderInPageState extends State<OrderInPage> {
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
      firestore.collection('order_in').doc(editingOrderId);

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
            firestore.collection('spare_parts').doc(old['partId']);
        final snap = await tx.get(ref);
        stockMap[old['partId']] =
            (snap['currentStock'] as num).toInt();
      }

      // baca stock part baru (jika belum kebaca)
      for (final item in items) {
        if (!stockMap.containsKey(item.part.id)) {
          final ref = firestore
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


      // ===============================
      // 3. WRITE (SETELAH SEMUA READ)
      // ===============================
      for (final entry in stockMap.entries) {
        tx.update(
          firestore
              .collection('spare_parts')
              .doc(entry.key),
          {'currentStock': entry.value},
        );
      }

      tx.update(orderRef, {
        'orderDate': Timestamp.fromDate(orderDate!),
        'client': selectedClient,
        'poNumber': poController.text.trim(),
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
    _showError(e.toString());
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
  final orderRef = firestore.collection('order_in').doc(orderId);

  try {
    await firestore.runTransaction((tx) async {
      final snap = await tx.get(orderRef);
      if (!snap.exists) return;

      final items = snap['items'] as List<dynamic>;

      for (final item in items) {
        final partRef =
            firestore.collection('spare_parts').doc(item['partId']);

        final partSnap = await tx.get(partRef);
        final currentStock =
            (partSnap['currentStock'] as num).toInt();

        tx.update(partRef, {
          'currentStock': currentStock - (item['qty'] as int),
        });
      }

      tx.delete(orderRef);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order berhasil dihapus'),
        backgroundColor: Colors.redAccent,
        duration: Duration(seconds: 2),
      ),
    );
  } catch (e) {
    _showError(e.toString());
  }
}

  // ================= FULLSCREEN SEARCH & FILTER =================
  final TextEditingController fullscreenSearchController =
      TextEditingController();
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
    final SparePart? selected = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SparePartListPage(
          selectionMode: true,
        ),
      ),
    );

    if (selected == null) return;

    final snap = await FirebaseFirestore.instance
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

    setState(() {
      items.add(OrderInItem(part: selected, qty: qty));
    });
  }
  
Future<void> _editItemAtIndex(int index) async {
  final current = items[index];

  final snap = await FirebaseFirestore.instance
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
  final controller = TextEditingController();
  String? error;

  return showDialog<int>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setLocal) {
          return AlertDialog(
            title: Text(part.partCode),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(part.nameEn),
                const SizedBox(height: 8),

                // INFO STOCK (HANYA INFORMASI)
               Text('Stock saat ini: $firestoreStock'),

                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Qty',
                    errorText: error,
                  ),
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
                  final qty = int.tryParse(controller.text) ?? 0;

                  // ===== VALIDASI UMUM =====
                  if (qty <= 0) {
                    setLocal(() => error = 'Qty tidak valid');
                    return;
                  }

                  // ===== VALIDASI KHUSUS ORDER OUT =====
                  if (mode == QtyDialogMode.orderOut &&
                      qty > part.currentStock) {
                    setLocal(() => error = 'Qty melebihi stock');
                    return;
                  }

                  // ===== ORDER IN TIDAK PUNYA VALIDASI STOCK =====
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
  if (isEditMode) {
    await _commitEditOrderIn();
    return;
  }

  if (orderDate == null ||
      selectedClient == null ||
      poController.text.trim().isEmpty ||
      items.isEmpty) {
    _showError('Lengkapi Order Date, Client, PO, dan Item');
    return;
  }

  final firestore = FirebaseFirestore.instance;
  final orderRef = firestore.collection('order_in').doc();

  try {
    await firestore.runTransaction((tx) async {
      // 1. VALIDASI & POTONG STOCK
      for (final item in items) {
  final partRef =
      firestore.collection('spare_parts').doc(item.part.id);

  final snap = await tx.get(partRef);
  final stock = (snap['currentStock'] as num).toInt();

  // ✅ ORDER IN SELALU MENAMBAH STOCK
  tx.update(partRef, {
    'currentStock': stock + item.qty,
  });
}

      // 2. SIMPAN ORDER BARU
      tx.set(orderRef, {
        'orderDate': Timestamp.fromDate(orderDate!),
        'client': selectedClient,
        'poNumber': poController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': _getCurrentUsername(),
        'items': items.map((e) => {
          'partId': e.part.id,
          'partCode': e.part.partCode,
          'nameEn': e.part.nameEn,
          'qty': e.qty,
          'location': e.part.location,
        }).toList(),
      });
    });

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
    _showError(e.toString());
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

              if (orderDate != null)
  Text(
   'Tanggal: ${orderDate.day}/${orderDate.month}/${orderDate.year}',

    style: const TextStyle(fontSize: 12),
  ),
              const Divider(height: 24),
              SizedBox(
                height: 250,
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final item = items[i];
                    return ListTile(
                      dense: true,
                      title: Text(item['partCode']),
                      subtitle: Text(item['nameEn']),
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

      floatingActionButton: (!widget.isCompact && !isCreateMode)
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
            child: widget.isCompact
                ? const _OrderInQuickView()
                : Column(
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
  onTap: _showOrderDetail,
  onDelete: (orderId, data) {
    _deleteOrder(context, orderId, data);
  },
  onEdit: (data) async {
  final confirm = await _confirmEditOrder(context);
  if (!confirm) return;

  _openEditOrder(data);

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Mode edit diaktifkan'),
      duration: Duration(seconds: 2),
    ),
  );
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
  setState(() {
    isCreateMode = false;
    isEditMode = false;
    editingOrderId = null;
    items.clear();
    orderDate = null;
    selectedClient = null;
    poController.clear();
  });
},

          ),
          const Text(
            'Order In',
            style:
                TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateForm() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: _OrderHeader(
            orderDate: orderDate,
            onPickDate: _selectOrderDate,
            selectedClient: selectedClient,
            onClientChanged: (v) =>
                setState(() => selectedClient = v),
            poController: poController,
            onSave: _commitOrderIn,
            onBack: () => setState(() => isCreateMode = false),
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? const Center(child: Text('Belum ada item'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (_, i) =>
                      _ItemCard(
  item: items[i],
  onEdit: () {
    _editItemAtIndex(i);
  },
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
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('order_in')
          .orderBy('createdAt', descending: true)
          .snapshots(),
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

          if (filterDate != null) {
            final date =
                (data['orderDate'] as Timestamp).toDate();
            if (date.year != filterDate!.year ||
                date.month != filterDate!.month ||
                date.day != filterDate!.day) {
              return false;
            }
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
/// QUICK VIEW (FLOATING)
/// =====================================================
class _OrderInQuickView extends StatelessWidget {
  const _OrderInQuickView();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('order_in')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .snapshots(),
      builder: (_, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (_, i) {
            final data =
                snapshot.data!.docs[i].data() as Map<String, dynamic>;
            return _OrderHistoryCard(data: data);
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
                ],
              ),
            ),

            // ===== ACTIONS (FULLSCREEN ONLY) =====
            if (isFullscreen) ...[
  IconButton(
    icon: const Icon(
      Icons.edit,
      size: 20,
      color: Colors.blueGrey,
    ),
    tooltip: 'Edit Order',
    onPressed: onEdit,
  ),
  IconButton(
    icon: const Icon(
      Icons.delete,
      size: 20,
      color: Colors.redAccent,
    ),
    tooltip: 'Delete Order',
    onPressed: onDelete,
  ),
],

          ],
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

  const _OrderHeader({
    required this.orderDate,
    required this.onPickDate,
    required this.selectedClient,
    required this.onClientChanged,
    required this.poController,
    required this.onSave,
    required this.onBack,
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
  child: StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('partners')
        .orderBy('name')
        .snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const SizedBox(
          height: 48,
          child: Center(child: CircularProgressIndicator()),
        );
      }

      final docs = snapshot.data!.docs;

      final partnerNames = docs
    .map((doc) => (doc.data() as Map<String, dynamic>)['name'] as String)
    .toList();

final safeValue =
    partnerNames.contains(selectedClient) ? selectedClient : null;

return DropdownButtonFormField<String>(
  initialValue: safeValue,
  items: partnerNames.map((name) {
    return DropdownMenuItem<String>(
      value: name,
      child: Text(name),
    );
  }).toList(),
  onChanged: onClientChanged,
  decoration: const InputDecoration(
    border: OutlineInputBorder(),
    isDense: true,
  ),
);

    },
  ),
),


              const SizedBox(height: 8),

              // ===== PO NUMBER =====
              _HeaderRow(
                label: 'PO Number',
                child: TextField(
                  controller: poController,
                  decoration:
                      const InputDecoration(border: OutlineInputBorder()),
                ),
              ),

              const SizedBox(height: 16),

              // ===== SAVE BUTTON =====
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onSave,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Order In'),
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

  const _ItemCard({
    required this.item,
    required this.onEdit,
  });


  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onEdit,
      title: Text(item.part.partCode),
      subtitle: Text(item.part.nameEn),
      trailing: Text('Qty: ${item.qty}'),
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
