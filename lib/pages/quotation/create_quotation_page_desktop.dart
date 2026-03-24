import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../core/session/company_session.dart';
import '../../services/quotation_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../pages/partners/partner_list_page.dart';
import '../spare_part/spare_part_list_page.dart';
import '../../services/exchange_rate_service.dart';
import 'package:intl/intl.dart';

class CreateQuotationPageDesktop extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const CreateQuotationPageDesktop({
    super.key,
    this.initialData,
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
    final discountPercent =
        double.tryParse(discountController.text) ?? 0;

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

  @override
  Widget build(BuildContext context) {

    final companyId = CompanySession.selectedCompanyId!;
    final config =
        QuotationService.getCurrencyConfig(companyId);
    final rate = config['rate'];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: Row(
          children: [

            // 🔽 LEFT FORM
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [

                    Row(
                      children: [
                        const Icon(Icons.add, color: Colors.white),
                        const SizedBox(width: 10),
                        Text(
                          isEditMode
                              ? "Edit Quotation"
                              : "Create Quotation",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Expanded(
                      child: ListView(
                        children: [

                          _buildPartner(),
                          const SizedBox(height: 12),

                          _buildAddItem(),
                          const SizedBox(height: 12),

                          if (selectedItems.isNotEmpty)
                            _buildPricing(rate),

                          const SizedBox(height: 12),

                          Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.white.withOpacity(0.95),
    borderRadius: BorderRadius.circular(16),
  ),
  child: _buildTable(rate),
),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 🔽 RIGHT SUMMARY
            Expanded(
              flex: 3,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [

    const Text(
      "Summary",
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    ),

    const SizedBox(height: 20),

    _row("Subtotal", format(subtotal)),

    if (discountAmount > 0)
      _row(
        "Discount",
        "-${format(discountAmount)}",
        color: Colors.red,
      ),

    if (vatAmount > 0)
      _row(
        "VAT",
        format(vatAmount),
      ),

    const Divider(),

    _row(
      "TOTAL",
      format(totalAmount),
      isBold: true,
    ),
  ],
),

                    const Divider(),

                    Text(
                      "TOTAL: ${format(totalAmount)}",
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),

                    const Spacer(),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
  backgroundColor: const Color(0xFF2563EB),
  foregroundColor: Colors.white,
  padding: const EdgeInsets.symmetric(vertical: 14),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
),
                      onPressed: (selectedItems.isEmpty ||
        selectedPartnerName == null ||
        hasOverStock)
    ? null
                          : () async {

                              final user =
                                  FirebaseAuth.instance.currentUser!;

                              final userDoc =
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(user.uid)
                                      .get();

                              final username =
                                  userDoc['username'] ?? '-';

                              await QuotationService.createQuotation(
                                companyId: companyId,
                                userId: user.uid,
                                userName: username,
                                partnerName: selectedPartnerName!,
                                partnerAddress:
                                    selectedPartnerAddress ?? '',
                                currency: config['currency'],
                                exchangeRate: liveRate ?? rate,
                                items: selectedItems,
                                priceValidityDays:
                                    int.tryParse(
                                            validityController.text) ??
                                        30,
                                vatPercent: double.tryParse(
                                        vatController.text) ??
                                    0,
                                discountPercent:
                                    double.tryParse(
                                            discountController.text) ??
                                        0,
                                discountAmount: discountAmount,
                                vatAmount: vatAmount,
                              );

                              if (context.mounted) Navigator.pop(context);
                            },
                      child: const Text("Create Quotation"),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartner() {
    return ListTile(
      tileColor: Colors.white,
      title: Text(selectedPartnerName ?? "Select Partner"),
      subtitle: Text(selectedPartnerAddress ?? ""),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const PartnerListPage(selectionMode: true),
          ),
        );

        if (result != null) {
          setState(() {
            selectedPartnerName = result.name;
            selectedPartnerAddress = result.address;
          });
        }
      },
    );
  }

  Widget _buildAddItem() {
    return ListTile(
      tileColor: Colors.white,
      leading: const Icon(Icons.add),
      title: const Text("Add Spare Part"),
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const SparePartListPage(selectionMode: true),
          ),
        );

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

final companyId = CompanySession.selectedCompanyId!;
final config = QuotationService.getCurrencyConfig(companyId);
_recalculateTotal(liveRate ?? config['rate']);
        }
      },
    );
  }

  Widget _buildPricing(double rate) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: vatController,
            decoration: const InputDecoration(labelText: "VAT"),
            onChanged: (_) => _recalculateTotal(rate),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: discountController,
            decoration:
                const InputDecoration(labelText: "Discount"),
            onChanged: (_) => _recalculateTotal(rate),
          ),
        ),
      ],
    );
  }

Widget _buildTable(double rate) {
  if (selectedItems.isEmpty) {
    return const Text("No items selected");
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      const Text(
        "Items",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),

      const SizedBox(height: 10),

      DataTable(
        columnSpacing: 20,
        columns: const [
          DataColumn(label: Text("Part")),
          DataColumn(label: Text("Qty")),
          DataColumn(label: Text("Stock")),
          DataColumn(label: Text("Price")),
          DataColumn(label: Text("Total")),
          DataColumn(label: Text("Action")),
        ],
        rows: selectedItems.map((item) {
          final qty = item['qty'];
          final stock = item['stock'];
          final isOverStock = qty > stock;

          final priceLocal =
              item['priceEur'] * (liveRate ?? rate);
          final total = priceLocal * qty;

          return DataRow(
            color: isOverStock
                ? MaterialStateProperty.all(
                    Colors.red.withOpacity(0.05))
                : null,
            cells: [

              DataCell(Text(item['partName'])),

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
                    ),
                    Text(qty.toString()),
                    IconButton(
                      icon: const Icon(Icons.add, size: 16),
                      onPressed: () {
                        setState(() {
                          item['qty']++;
                        });
                        _recalculateTotal(liveRate ?? rate);
                      },
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
              DataCell(Text(format(total))),

              DataCell(
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
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
    ],
  );
}
  
}

Widget _row(String label, String value,
    {bool isBold = false, Color? color}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
      ],
    ),
  );
}