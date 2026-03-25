import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../core/session/company_session.dart';
import '../../services/quotation_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../pages/partners/partner_list_page.dart';
import '../spare_part/spare_part_list_page.dart';
import '../../services/exchange_rate_service.dart';
import 'package:intl/intl.dart';
import '../../core/widgets/draggable_window.dart';

class CreateQuotationPageDesktop extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  final VoidCallback? onClose;

const CreateQuotationPageDesktop({
  super.key,
  this.initialData,
  this.onClose,
});

  @override
  State<CreateQuotationPageDesktop> createState() =>
      _CreateQuotationPageDesktopState();
}

class _CreateQuotationPageDesktopState
    extends State<CreateQuotationPageDesktop> {
  bool get isEditMode => widget.initialData != null;
  double? liveRate;

  final TextEditingController validityController =
      TextEditingController(text: '30');
  final TextEditingController vatController =
      TextEditingController(text: '0');
  final TextEditingController discountController =
      TextEditingController(text: '0');

  final List<Map<String, dynamic>> selectedItems = [];
  final Map<String, TextEditingController> qtyControllers = {};

  String? selectedPartnerName;
  String? selectedPartnerAddress;

  double subtotal = 0;
  double discountAmount = 0;
  double vatAmount = 0;
  double totalAmount = 0;

  bool get hasOverStock =>
      selectedItems.any((e) => e['qty'] > e['stock']);

  @override
  void initState() {
    super.initState();
    _loadRate();

    if (isEditMode) {
      final data = widget.initialData!;
      selectedPartnerName = data['partnerName'];
      selectedPartnerAddress = data['partnerAddress'];
      validityController.text = data['priceValidityDays']?.toString() ?? '30';
      vatController.text = data['vatPercent']?.toString() ?? '0';
      discountController.text = data['discountPercent']?.toString() ?? '0';
      
      final items = data['items'] as List;
      for (var item in items) {
        selectedItems.add({
          'partId': item['partId'],
          'partName': item['partName'],
          'qty': item['qty'],
          'stock': item['stock'],
          'priceEur': item['priceEur'],
        });
      }
      _recalculateTotal(liveRate ?? 15000);
    }
  }

  Future<void> _loadRate() async {
    try {
      final rate = await ExchangeRateService.getEurToIdr();
      setState(() => liveRate = rate);
    } catch (_) {}
  }

  void _recalculateTotal(double rate) {
    double calcSubtotal = 0;

    for (var item in selectedItems) {
      calcSubtotal += item['qty'] * item['priceEur'] * rate;
    }

    final vatPercent = double.tryParse(vatController.text) ?? 0;
    final discountPercent = double.tryParse(discountController.text) ?? 0;

    final calcDiscount = calcSubtotal * (discountPercent / 100);
    final afterDiscount = calcSubtotal - calcDiscount;
    final calcVat = afterDiscount * (vatPercent / 100);

    setState(() {
      subtotal = calcSubtotal;
      discountAmount = calcDiscount;
      vatAmount = calcVat;
      totalAmount = afterDiscount + calcVat;
    });
  }

  String format(double v) {
    final companyId = CompanySession.selectedCompanyId!;
    final config = QuotationService.getCurrencyConfig(companyId);
    return NumberFormat.currency(
      locale: 'id',
      symbol: '${config['currency']} ',
      decimalDigits: 0,
    ).format(v);
  }

  Color _getStatusColor() {
    if (hasOverStock) return const Color(0xFFEF4444);
    if (selectedItems.isEmpty) return const Color(0xFFF59E0B);
    if (selectedPartnerName == null) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  String _getStatusMessage() {
    if (hasOverStock) return 'Over stock detected';
    if (selectedItems.isEmpty) return 'No items selected';
    if (selectedPartnerName == null) return 'Partner not selected';
    return 'Ready to save';
  }

  @override
  Widget build(BuildContext context) {
    final companyId = CompanySession.selectedCompanyId!;
    final config = QuotationService.getCurrencyConfig(companyId);
    final rate = config['rate'];
    final statusColor = _getStatusColor();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
  title: isEditMode
      ? const SizedBox() // 🔥 kosongkan di edit mode
      : Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.add,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Create Quotation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
  backgroundColor: Colors.transparent,
  elevation: 0,
  scrolledUnderElevation: 0, // 🔥 INI WAJIB
  surfaceTintColor: Colors.transparent, // 🔥 INI WAJIB
  foregroundColor: Colors.white,

  // 🔥 hilangkan tombol back saat edit mode
  leading: isEditMode
      ? null
      : Container(
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
        child: Row(
          children: [
            // LEFT PANEL - Form
            Expanded(
              flex: 5,
              child: _buildLeftPanel(context, rate),
            ),
            // RIGHT PANEL - Summary
            Expanded(
              flex: 3,
              child: _buildRightPanel(rate, statusColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftPanel(BuildContext context, double rate) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Partner Section
          Container(
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
                onTap: () async {
  final overlay = Overlay.of(context, rootOverlay: true);

  late OverlayEntry entry;
  dynamic result;

  entry = OverlayEntry(
  builder: (context) {
    return Positioned.fill(
      child: Material(
        color: Colors.black.withOpacity(0.2),
        child: DraggableResizableWindow(
          title: "Select Partner",
          headerColor: Colors.blueGrey,
          onClose: () {
            entry.remove();
          },
          child: PartnerListPage(
            selectionMode: true,
            onSelected: (data) {
              result = data;
              entry.remove();
            },
          ),
        ),
      ),
    );
  },
);

  overlay.insert(entry);

  // 🔥 tunggu sampai dialog ditutup
  await Future.doWhile(() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return entry.mounted;
  });

  if (result != null) {
    setState(() {
      selectedPartnerName = result.name;
      selectedPartnerAddress = result.address;
    });
    _recalculateTotal(liveRate ?? rate);
  }
},
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.business,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedPartnerName ?? 'Select Partner',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: selectedPartnerName != null
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                            if (selectedPartnerAddress != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                selectedPartnerAddress!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Add Items Button
          Container(
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
                onTap: () async {
  final overlay = Overlay.of(context, rootOverlay: true);

  late OverlayEntry entry;
  dynamic result;

  entry = OverlayEntry(
  builder: (context) {
    return Positioned.fill(
      child: Material(
        color: Colors.black.withOpacity(0.2),
        child: DraggableResizableWindow(
          title: "Select Spare Part",
          headerColor: Colors.blueGrey,
          onClose: () {
            entry.remove();
          },
          child: SparePartListPage(
            selectionMode: true,
            onSelected: (data) {
              result = data;
              entry.remove();
            },
          ),
        ),
      ),
    );
  },
);

  overlay.insert(entry);

  await Future.doWhile(() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return entry.mounted;
  });

  if (result != null) {
    setState(() {
      selectedItems.add({
        'partId': result.id,
        'partName': result.name,
        'qty': 1,
        'stock': result.currentStock ?? 0,
        'priceEur': result.basePriceEur,
      });
    });
    _recalculateTotal(liveRate ?? rate);
  }
},
                borderRadius: BorderRadius.circular(16),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.add, color: Color(0xFF2563EB)),
                      SizedBox(width: 12),
                      Text(
                        'Add Spare Parts',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Items Table
          if (selectedItems.isNotEmpty)
            Container(
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
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.inventory,
                            size: 16,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Selected Items',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${selectedItems.length} items',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(
                          const Color(0xFFF8FAFC),
                        ),
                        columnSpacing: 24,
                        columns: const [
                          DataColumn(
                            label: Text(
                              "Part Name",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "Qty",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "Stock",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "Price",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "Total",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "Action",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                        rows: selectedItems.map((item) {
                          final qty = item['qty'];
                          final stock = item['stock'];
                          final isOverStock = qty > stock;
                          final priceLocal = item['priceEur'] * (liveRate ?? rate);
                          final total = priceLocal * qty;

                          return DataRow(
                            color: isOverStock
                                ? MaterialStateProperty.all(
                                    Colors.red.withOpacity(0.05))
                                : null,
                            cells: [
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    item['partName'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: isOverStock ? Colors.red : null,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove, size: 16),
                                      onPressed: () {
                                        setState(() {
                                          item['qty']--;
                                          if (item['qty'] <= 0) {
                                            selectedItems.remove(item);
                                          }
                                        });
                                        _recalculateTotal(liveRate ?? rate);
                                      },
                                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                      padding: EdgeInsets.zero,
                                    ),
                                    Container(
                                      width: 40,
                                      alignment: Alignment.center,
                                      child: Text(qty.toString()),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add, size: 16),
                                      onPressed: () {
                                        setState(() {
                                          item['qty']++;
                                        });
                                        _recalculateTotal(liveRate ?? rate);
                                      },
                                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Text(
                                  stock.toString(),
                                  style: TextStyle(
                                    color: isOverStock ? Colors.red : null,
                                  ),
                                ),
                              ),
                              DataCell(Text(format(priceLocal))),
                              DataCell(
                                Text(
                                  format(total),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                              DataCell(
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      selectedItems.remove(item);
                                    });
                                    _recalculateTotal(liveRate ?? rate);
                                  },
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Pricing Controls
          if (selectedItems.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
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
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.calculate,
                            size: 16,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Pricing',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: validityController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Validity (days)',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            onChanged: (_) => _recalculateTotal(liveRate ?? rate),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: vatController,
                            onChanged: (_) => _recalculateTotal(liveRate ?? rate),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'VAT (%)',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: discountController,
                            onChanged: (_) => _recalculateTotal(liveRate ?? rate),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Discount (%)',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRightPanel(double rate, Color statusColor) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.summarize,
                  size: 18,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Status Indicator
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  hasOverStock
                      ? Icons.warning
                      : (selectedItems.isEmpty || selectedPartnerName == null)
                          ? Icons.info_outline
                          : Icons.check_circle,
                  color: statusColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getStatusMessage(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Financial Summary
          _summaryRow('Subtotal', format(subtotal)),
          if (discountAmount > 0)
            _summaryRow(
              'Discount',
              '-${format(discountAmount)}',
              isNegative: true,
            ),
          if (vatAmount > 0)
            _summaryRow('VAT', format(vatAmount)),
          const Divider(height: 24),
          _summaryRow(
            'TOTAL',
            format(totalAmount),
            isBold: true,
            isTotal: true,
          ),

          const Spacer(),

          // Create Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: (selectedItems.isEmpty || selectedPartnerName == null || hasOverStock)
    ? null
    : () async {
        try {
          print("STEP A - BUTTON CLICKED");

          final user = FirebaseAuth.instance.currentUser!;
          print("STEP B - USER OK");

          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          print("STEP C - USER DOC OK");

          final username = userDoc['username'] ?? '-';
          final companyId = CompanySession.selectedCompanyId!;
          final config = QuotationService.getCurrencyConfig(companyId);

          print("STEP D - BEFORE SAVE");

          if (isEditMode) {
            print("STEP E - EDIT MODE");
            print("DOC ID: ${widget.initialData!['id']}");
print("COMPANY ID: $companyId");

            await FirebaseFirestore.instance
                .collection('companies')
                .doc(companyId)
                .collection('quotations')
                .doc(widget.initialData!['id'])
                .update({
              'subtotal': subtotal,
              'discountPercent': double.tryParse(discountController.text) ?? 0,
              'discountAmount': discountAmount,
              'vatPercent': double.tryParse(vatController.text) ?? 0,
              'vatAmount': vatAmount,
              'totalAmount': totalAmount,
              'validUntil': Timestamp.fromDate(
                DateTime.now().add(
                  Duration(days: int.tryParse(validityController.text) ?? 30),
                ),
              ),
              'items': selectedItems.map((item) {
                final priceLocal = item['priceEur'] * (liveRate ?? rate);
                return {
                  'partId': item['partId'],
                  'partName': item['partName'],
                  'qty': item['qty'],
                  'stock': item['stock'],
                  'priceEur': item['priceEur'],
                  'priceLocal': priceLocal,
                  'total': priceLocal * item['qty'],
                };
              }).toList(),
              'partnerName': selectedPartnerName,
              'partnerAddress': selectedPartnerAddress,
              'updatedAt': FieldValue.serverTimestamp(),
            });

            print("STEP F - UPDATE SUCCESS");
          } else {
            print("STEP E2 - CREATE MODE");

            await QuotationService.createQuotation(
              companyId: companyId,
              userId: user.uid,
              userName: username,
              partnerName: selectedPartnerName!,
              partnerAddress: selectedPartnerAddress ?? '',
              currency: config['currency'],
              exchangeRate: liveRate ?? rate,
              items: selectedItems,
              priceValidityDays: int.tryParse(validityController.text) ?? 30,
              vatPercent: double.tryParse(vatController.text) ?? 0,
              discountPercent: double.tryParse(discountController.text) ?? 0,
              discountAmount: discountAmount,
              vatAmount: vatAmount,
            );

            print("STEP F2 - CREATE SUCCESS");
          }

          print("STEP G - BEFORE POP");

          if (context.mounted) {
  if (widget.onClose != null) {
    widget.onClose!();
  } else {
    Navigator.pop(context, true);
  }
}

        } catch (e, s) {
          print("🔥 ERROR SAVE: $e");
          print(s);
        }
      },
              child: Text(isEditMode ? 'Save Changes' : 'Create Quotation'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isNegative = false, bool isBold = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 14 : 12,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              color: isNegative ? Colors.red : const Color(0xFF64748B),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 20 : 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? const Color(0xFF2563EB) : (isNegative ? Colors.red : const Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }
}