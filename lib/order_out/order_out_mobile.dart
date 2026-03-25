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
  // ================= CREATE ORDER STATE =================
  DateTime? orderDate;
  String? selectedClient;
  final TextEditingController poController = TextEditingController();
  final FocusNode fullscreenSearchFocusNode = FocusNode();
  final List<OrderOutItem> items = [];

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
        OrderOutItem(
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

    // ===============================
    // 1️⃣ AGGREGATE NEW ITEMS
    // ===============================
    for (final item in newItems) {
      aggregatedNewQty.update(
        item.part.id,
        (value) => value + item.qty,
        ifAbsent: () => item.qty,
      );
    }

    // ===============================
    // 2️⃣ IF EDIT → ROLLBACK OLD STOCK
    // ===============================
   if (isEdit) {
  final oldSnap = await tx.get(orderRef);

  if (!oldSnap.exists) {
    throw Exception('Order tidak ditemukan');
  }

  final oldItems =
      List<Map<String, dynamic>>.from(oldSnap['items']);

  // ===============================
  // AGGREGATE OLD QTY
  // ===============================
  final Map<String, int> aggregatedOldQty = {};

  for (final old in oldItems) {
    aggregatedOldQty.update(
      old['partId'],
      (value) => value + (old['qty'] as int),
      ifAbsent: () => old['qty'] as int,
    );
  }

  // ===============================
  // ROLLBACK STOCK
  // ===============================
  for (final entry in aggregatedOldQty.entries) {
    final partRef =
        CompanyFirestore.collection('spare_parts').doc(entry.key);

    final snap = await tx.get(partRef);

    final currentStock =
        (snap['currentStock'] as num).toInt();

    stockMap[entry.key] =
        currentStock + entry.value;
  }
}

    // ===============================
    // 3️⃣ READ STOCK UNTUK PART BARU
    // ===============================
    for (final entry in aggregatedNewQty.entries) {
      final partId = entry.key;

      if (!stockMap.containsKey(partId)) {
        final ref =
            CompanyFirestore.collection('spare_parts').doc(partId);

        final snap = await tx.get(ref);

        stockMap[partId] =
            (snap['currentStock'] as num).toInt();
      }
    }

    // ===============================
    // 4️⃣ VALIDASI & POTONG STOCK
    // ===============================
    for (final entry in aggregatedNewQty.entries) {
      final partId = entry.key;
      final qty = entry.value;

      if (stockMap[partId]! < qty) {
        throw Exception('Stock tidak mencukupi');
      }

      stockMap[partId] =
          stockMap[partId]! - qty;
    }

    // ===============================
    // 5️⃣ UPDATE STOCK
    // ===============================
    for (final entry in stockMap.entries) {
      tx.update(
       CompanyFirestore.collection('spare_parts').doc(entry.key),
        {'currentStock': entry.value},
      );
    }

    // ===============================
    // 6️⃣ SAVE ORDER
    // ===============================
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
      if (!isEdit)
        'createdAt': FieldValue.serverTimestamp(),
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
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 8),
        const Text(
          'Order Out',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
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
  final isDesktop = MediaQuery.of(context).size.width >= 900;

  SparePart? selected;

  if (isDesktop) {
    selected = await showGeneralDialog<SparePart>(
      context: context,
      barrierDismissible: true,
      barrierLabel: "SelectSparePart",
      barrierColor: Colors.black.withValues(alpha: 0.35),
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

  final int? qty = await _showQtyDialog(selected);
  if (qty == null) return;

  setState(() {
    items.add(OrderOutItem(part: selected!, qty: qty));
  });
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

  final currentStock =
      (snap['currentStock'] as num).toInt();

  // 🔑 STOCK SEBENARNYA SAAT EDIT
  final availableStock = currentStock + current.qty;

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

  final int? newQty = await _showQtyDialog(partForEdit);
  if (newQty == null) return;

  setState(() {
    items[index] = OrderOutItem(
      part: current.part,
      qty: newQty,
    );
  });
}

  // ================= QTY DIALOG =================
  Future<int?> _showQtyDialog(SparePart part) async {
  int qty = 1;
  final controller = TextEditingController(text: '1');
  String? error;

  return showDialog<int>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setLocal) {
          void increase() {
            if (qty < part.currentStock) {
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
            title: Text(part.partCode),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(part.nameEn),
                const SizedBox(height: 8),
                Text('Stock tersedia: ${part.currentStock}'),
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
                          errorText: error,
                          isDense: true,
                          border: const OutlineInputBorder(),
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

                  if (qty > part.currentStock) {
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

  if (orderDate == null ||
      selectedClient == null ||
      poController.text.trim().isEmpty ||
      items.isEmpty) {
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
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order berhasil disimpan'),
        backgroundColor: Colors.green,
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

  // ================= ORDER DETAIL =================//


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
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderOutDetailPage(data: data),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      _openEditOrder(result);
    }
  },

  onDelete: (id, _) => _deleteOrder(id),

  onEdit: (_) {},
)
                      )

                    ],
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
        // Biarkan mobile layout lama (tidak kita sentuh)
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
                onSave: _commitOrderOut,
                onBack: () => setState(() => isCreateMode = false),
                isFormValid: isFormValid,
              ),
            ),
            Expanded(
      child: Column(
        children: [

    if (items.isNotEmpty)
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
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
      ),

    const SizedBox(height: 8),

    Expanded(
      child: items.isEmpty
                  ? const Center(child: Text('No item'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      itemBuilder: (_, i) => _ItemCard(
  item: items[i],
  onEdit: () => _editItemAtIndex(i),
  onDelete: () async {
    final confirmed = await _confirmDeleteItem(context);
    if (!confirmed) return;

    setState(() {
      items.removeAt(i);
    });
  },
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
            ),
            ),
          ]
        );
      }

      // ===============================
      // DESKTOP STRUCTURE (IDENTIK ORDER IN)
      // ===============================

      final desktopTotalItem = totalItem;
final desktopTotalQty = totalQty;
final desktopTotalWeight = totalWeight;

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
                            label: const Text('Add Item'),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Expanded(
  child: items.isEmpty
      ? const Center(
          child: Text('No item'),
        )
      : ListView.builder(
          itemCount: items.length,
          itemBuilder: (_, i) {
            return Card(
              child: ListTile(
                title: Text(items[i].part.partCode),
                subtitle: Text(items[i].part.nameEn),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Qty: ${items[i].qty}'),
                    const SizedBox(width: 8),

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
                      onPressed: () async {
                        final confirmed =
                            await _confirmDeleteItem(context);
                        if (!confirmed) return;

                        setState(() {
                          items.removeAt(i);
                        });
                      },
                    ),
                  ],
                ),
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

                Text(
  'Total Weight: ${desktopTotalWeight.toStringAsFixed(2)} kg',
  style: const TextStyle(
    fontWeight: FontWeight.w600,
  ),
),

                const Spacer(),

                SizedBox(
                  width: 220,
                  child: ElevatedButton.icon(
                    onPressed: isFormValid
                        ? _commitOrderOut
                        : null,
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

  final isDateInvalid = orderDate == null;
  final isPoInvalid = poController.text.trim().isEmpty;

  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const Text(
          'Order Out',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 24),

        // ================= DATE =================
        const Text(
          'Order Date *',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),

        InkWell(
          onTap: _selectOrderDate,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDateInvalid
                    ? Colors.red
                    : Colors.grey.shade400,
              ),
            ),
            child: Text(
              orderDate == null
                  ? 'Select date'
                  : '${orderDate!.day}/${orderDate!.month}/${orderDate!.year}',
              style: TextStyle(
                color: orderDate == null
                    ? Colors.grey
                    : Colors.black,
              ),
            ),
          ),
        ),

        if (isDateInvalid)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Required',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),

        const SizedBox(height: 16),

        // ================= CLIENT =================
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

        // ================= PO NUMBER =================
        const Text(
          'PO Number *',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),

        TextField(
          controller: poController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            errorText:
                isPoInvalid ? 'Required' : null,
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
      title: const Text('Hapus Item'),
      content: const Text(
        'Item ini akan dihapus dari order.\nLanjutkan?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
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
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Hapus Order'),
      content: const Text(
          'Order ini akan dihapus dan tidak bisa dikembalikan.\nLanjutkan?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Hapus'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  await CompanyFirestore.collection('order_out')
      .doc(orderId)
      .delete();

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
class _OrderOutListView extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: CompanyFirestore
          .collection('order_out')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (_, snapshot) {
         if (snapshot.connectionState == ConnectionState.waiting) {
    return const Center(child: CircularProgressIndicator());
  }

  if (!snapshot.hasData || snapshot.data == null) {
    return const Center(child: Text('No data'));
  }
        if (snapshot.hasData) {
    ReadTrackerService().trackRead(
      page: 'OrderOutPage',
      collection: 'order_out',
      operation: 'stream_list',
      documentsCount: snapshot.data!.docs.length,
    );
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
          return const Center(child: Text('No Order'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (_, i) {
  final doc = docs[i];

  final data = {
    ...(doc.data() as Map<String, dynamic>),
    'id': doc.id,
  };

  return InkWell(
  onTap: () => onTap(context, data),
  child: _OrderHistoryCard(
    data: data,
    isAdmin: isAdmin,
    onDelete: isAdmin
        ? () => onDelete?.call(doc.id, data)
        : null,
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
  final bool isAdmin;
  final VoidCallback? onDelete;

  const _OrderHistoryCard({
    required this.data,
    required this.isAdmin,
    this.onDelete,
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

_summaryChip(
  Icons.inventory_2,
  '$totalQty Qty',
),

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
  final bool isFormValid;

  const _OrderHeader({
    required this.orderDate,
    required this.onPickDate,
    required this.selectedClient,
    required this.onClientChanged,
    required this.poController,
    required this.onSave,
    required this.onBack,
     required this.isFormValid,
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
                    'Order Out',
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
                  decoration:
                      const InputDecoration(border: OutlineInputBorder()),
                ),
              ),

              const SizedBox(height: 16),

              // ===== SAVE BUTTON =====
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isFormValid ? onSave : null,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Order Out'),
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
    return ListTile(
  onTap: onEdit,
  title: Text(item.part.partCode),
  subtitle: Text(item.part.nameEn),
  trailing: Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('Qty: ${item.qty}'),
        const SizedBox(height: 4),
        Text(
          item.part.location.isNotEmpty
              ? 'Loc: ${item.part.location}'
              : 'Loc: -',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ],
    ),
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

