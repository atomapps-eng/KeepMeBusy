import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/session/company_session.dart';
import '../../services/quotation_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../pages/partners/partner_list_page.dart';
import '../spare_part/spare_part_list_page.dart';
import '../../services/exchange_rate_service.dart';
import '../../theme/app_theme.dart';
import 'package:intl/intl.dart';

class CreateQuotationPage extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const CreateQuotationPage({
    super.key,
    this.initialData,
  });

  @override
  State<CreateQuotationPage> createState() => _CreateQuotationPageState();
}

class _CreateQuotationPageState extends State<CreateQuotationPage> {
  double? liveRate;
  bool get isEditMode => widget.initialData != null;
  final Map<String, TextEditingController> qtyControllers = {};
  final TextEditingController validityController = TextEditingController(text: '30');
  final TextEditingController vatController = TextEditingController(text: '0');
  final TextEditingController discountController = TextEditingController(text: '0');
  String? selectedPartnerName;
  String? selectedPartnerAddress;
  final List<Map<String, dynamic>> selectedItems = [];

  String safeString(dynamic value) => (value ?? '').toString();
int safeInt(dynamic value) => (value ?? 0) as int;
double safeDouble(dynamic value) => (value ?? 0).toDouble();
  
  bool get hasOverStock {
    return selectedItems.any(
      (item) => item['qty'] > item['stock'],
    );
  }

  double totalAmount = 0;
  double subtotal = 0;
  double discountAmount = 0;
  double vatAmount = 0;

  void _recalculateTotal(double exchangeRate) {
    double calcSubtotal = 0;

    for (var item in selectedItems) {
      final qty = item['qty'] ?? 0;
      final price = item['priceEur'] ?? 0;
      calcSubtotal += qty * price * exchangeRate;
    }

    final vatPercent = double.tryParse(vatController.text) ?? 0;
    final discountPercent = double.tryParse(discountController.text) ?? 0;

    final calcDiscount = calcSubtotal * (discountPercent / 100);
    final afterDiscount = calcSubtotal - calcDiscount;
    final calcVat = afterDiscount * (vatPercent / 100);
    final finalTotal = afterDiscount + calcVat;

    setState(() {
      subtotal = calcSubtotal;
      discountAmount = calcDiscount;
      vatAmount = calcVat;
      totalAmount = finalTotal;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadRate();

   if (isEditMode) {
  final data = widget.initialData ?? {};

  selectedPartnerName = (data['partnerName'] ?? '').toString();
  selectedPartnerAddress = (data['partnerAddress'] ?? '').toString();

  final items = (data['items'] ?? []) as List;

  for (var item in items) {
    final partId = item['partId'] ?? '';

    qtyControllers[partId] = TextEditingController(
      text: (item['qty'] ?? 0).toString(),
    );

    selectedItems.add({
      'partId': item['partId'] ?? '',
      'partCode': item['partCode'] ?? '',
      'partName': item['partName'] ?? '',
      'qty': item['qty'] ?? 0,
      'stock': item['stock'] ?? 0,
      'priceEur': item['priceEur'] ?? 0,
    });
  }

  _recalculateTotal(
    liveRate ??
        (QuotationService.getCurrencyConfig(
          CompanySession.selectedCompanyId!,
        )['rate'] as double),
  );
}
  }

  @override
  void dispose() {
    validityController.dispose();
    vatController.dispose();
    discountController.dispose();
    for (var controller in qtyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _formatCurrency(double amount) {
    final companyId = CompanySession.selectedCompanyId!;
    final config = QuotationService.getCurrencyConfig(companyId);
    final currency = config['currency'];
    
    final formatter = NumberFormat.currency(
      locale: 'id',
      symbol: '$currency ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final companyId = CompanySession.selectedCompanyId!;
    final config = QuotationService.getCurrencyConfig(companyId);
    final currency = config['currency'];
    final rate = config['rate'];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isEditMode ? Icons.edit_note : Icons.add,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              isEditMode ? 'Edit Quotation' : 'Create Quotation',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        leading: Container(
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
        child: SafeArea(
          child: Column(
            children: [
              // Static Sections (tidak ikut scroll)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  children: [
                    _buildPartnerSection(),
                    const SizedBox(height: 12),
                    _buildAddItemsButton(),
                    if (selectedItems.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildPricingControls(currency, rate),
                    ],
                  ],
                ),
              ),
              
              // Scrollable Selected Items Section
              if (selectedItems.isNotEmpty)
                Expanded(
                  child: _buildSelectedItemsSection(currency, rate),
                ),
              
              // Bottom Bar (selalu di bawah)
              if (selectedItems.isNotEmpty)
                _buildBottomBar(currency),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPartnerSection() {
    return Container(
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
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PartnerListPage(selectionMode: true),
              ),
            );

            if (result != null) {
              setState(() {
                selectedPartnerName = result.name;
                selectedPartnerAddress = result.address;
              });
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                const SizedBox(width: 12),
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
    );
  }

  Widget _buildAddItemsButton() {
    return Container(
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
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SparePartListPage(selectionMode: true),
              ),
            );

            if (result != null) {
              final part = result;
              setState(() {
                qtyControllers[part.id] = TextEditingController(text: '1');
                selectedItems.add({
                  'partId': part.id,
                  'partCode': part.partCode,
                  'partName': part.name,
                  'qty': 1,
                  'stock': (part.currentStock ?? 0) as int,
                  'priceEur': part.basePriceEur,
                });
              });
              final companyId = CompanySession.selectedCompanyId!;
              final config = QuotationService.getCurrencyConfig(companyId);
              final rate = config['rate'];
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
    );
  }

  Widget _buildSelectedItemsSection(String currency, double rate) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: selectedItems.length,
        itemBuilder: (context, index) {
          final item = selectedItems[index];
          final qty = item['qty'];
          final stock = item['stock'];
          final isOverStock = qty > stock;
          final priceLocal = (item['priceEur'] ?? 0) * (liveRate ?? rate);
          final totalPrice = priceLocal * qty;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isOverStock 
                  ? Colors.red.withOpacity(0.05) 
                  : Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isOverStock 
                    ? Colors.red.withOpacity(0.3) 
                    : Colors.grey.shade200,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200.withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
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
                            item['partName'],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isOverStock ? Colors.red : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item['partCode'],
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          if (isOverStock)
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                '⚠️ Exceeds available stock',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatCurrency(totalPrice),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@ ${_formatCurrency(priceLocal)}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 18),
                      onPressed: () {
                        setState(() {
                          item['qty']--;
                          if (item['qty'] <= 0) {
                            selectedItems.remove(item);
                            qtyControllers.remove(item['partId']);
                          } else {
                            qtyControllers[item['partId']]!.text = item['qty'].toString();
                          }
                        });
                        final companyId = CompanySession.selectedCompanyId!;
                        final config = QuotationService.getCurrencyConfig(companyId);
                        final rate = config['rate'];
                        _recalculateTotal(liveRate ?? rate);
                      },
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                    ),
                    Container(
                      width: 50,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      alignment: Alignment.center,
                      child: Text(
                        item['qty'].toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 18),
                      onPressed: () {
                        setState(() {
                          if (item['qty'] < item['stock']) {
                            item['qty']++;
                          }
                          qtyControllers[item['partId']]!.text = item['qty'].toString();
                        });
                        final companyId = CompanySession.selectedCompanyId!;
                        final config = QuotationService.getCurrencyConfig(companyId);
                        final rate = config['rate'];
                        _recalculateTotal(liveRate ?? rate);
                      },
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          selectedItems.remove(item);
                          qtyControllers.remove(item['partId']);
                        });
                        final companyId = CompanySession.selectedCompanyId!;
                        final config = QuotationService.getCurrencyConfig(companyId);
                        final rate = config['rate'];
                        _recalculateTotal(liveRate ?? rate);
                      },
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPricingControls(String currency, double rate) {
    return Container(
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
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: validityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Validity (days)',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  isDense: true,
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
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  isDense: true,
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
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(String currency) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.98),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Amount',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatCurrency(totalAmount),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: (selectedItems.isEmpty || selectedPartnerName == null || hasOverStock)
                    ? null
                    : () async {
                        if (hasOverStock) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Cannot save: Over stock detected"),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        final user = FirebaseAuth.instance.currentUser!;
                        final userDoc = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .get();

                        final userData = userDoc.data() as Map<String, dynamic>;
                        final username = userData['username'] ?? 'Unknown';
                        final companyId = CompanySession.selectedCompanyId!;
                        final config = QuotationService.getCurrencyConfig(companyId);
                        final rate = config['rate'];

                        if (isEditMode) {
                          final processedItems = selectedItems.map((item) {
                            final qty = item['qty'] ?? 0;
                            final priceEur = (item['priceEur'] ?? 0).toDouble();
                            final priceLocal = priceEur * (liveRate ?? rate);
                            final total = priceLocal * qty;

                            return {
                              'partId': item['partId'],
                              'partCode': item['partCode'],
                              'partName': item['partName'],
                              'qty': qty,
                              'stock': item['stock'],
                              'priceEur': priceEur,
                              'priceLocal': priceLocal,
                              'total': total,
                            };
                          }).toList();

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
                            'items': processedItems,
                            'partnerName': selectedPartnerName,
                            'partnerAddress': selectedPartnerAddress,
                            'updatedAt': FieldValue.serverTimestamp(),
                          });
                        } else {
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
                        }

                        if (context.mounted) Navigator.pop(context);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(isEditMode ? Icons.save : Icons.send, size: 18),
                    const SizedBox(width: 8),
                    Text(isEditMode ? 'Save Changes' : 'Create Quotation'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadRate() async {
    try {
      final rate = await ExchangeRateService.getEurToIdr();
      setState(() {
        liveRate = rate;
      });
    } catch (e) {
      print("Error load rate: $e");
    }
  }
}