class QuotationModel {
  final String id;
  final String quotationNumber;
  final String companyId;

  final String createdBy;
  final String createdByName;

  final String status;

  final DateTime? submittedAt;
  final String? submittedBy;

  final DateTime? approvedAt;
  final String? approvedBy;

  final DateTime? rejectedAt;
  final String? rejectedBy;
  final String? rejectionNote;

  final String currency;
  final double exchangeRate;

  final List<QuotationItem> items;
  final double totalAmount;

  final DateTime createdAt;
  final DateTime updatedAt;

  final String partnerName;
final String partnerAddress;

  QuotationModel({
    required this.id,
    required this.quotationNumber,
    required this.companyId,
    required this.createdBy,
    required this.createdByName,
    required this.status,
    this.submittedAt,
    this.submittedBy,
    this.approvedAt,
    this.approvedBy,
    this.rejectedAt,
    this.rejectedBy,
    this.rejectionNote,
    required this.currency,
    required this.exchangeRate,
    required this.items,
    required this.totalAmount,
    required this.createdAt,
    required this.updatedAt,
    required this.partnerName,
required this.partnerAddress,
  });

  factory QuotationModel.fromMap(String id, Map<String, dynamic> map) {
    return QuotationModel(
      id: id,
      quotationNumber: map['quotationNumber'] ?? '',
      companyId: map['companyId'] ?? '',
      createdBy: map['createdBy'] ?? '',
      createdByName: map['createdByName'] ?? '',
      status: map['status'] ?? 'draft',

      submittedAt: map['submittedAt']?.toDate(),
      submittedBy: map['submittedBy'],

      approvedAt: map['approvedAt']?.toDate(),
      approvedBy: map['approvedBy'],

      rejectedAt: map['rejectedAt']?.toDate(),
      rejectedBy: map['rejectedBy'],
      rejectionNote: map['rejectionNote'],

      currency: map['currency'] ?? 'EUR',
      exchangeRate: (map['exchangeRate'] ?? 1).toDouble(),

      items: (map['items'] as List? ?? [])
          .map((e) => QuotationItem.fromMap(e))
          .toList(),

      totalAmount: (map['totalAmount'] ?? 0).toDouble(),

      createdAt: map['createdAt'].toDate(),
      updatedAt: map['updatedAt'].toDate(),

      partnerName: map['partnerName'] ?? '',
partnerAddress: map['partnerAddress'] ?? '',
    );
  }
}

class QuotationItem {
  final String partId;
  final String partCode;
  final String partName;

  final int qty;
  final int stock;

  final double priceEur;
  final double priceLocal;
  final double total;

  QuotationItem({
    required this.partId,
    required this.partCode,
    required this.partName,
    required this.qty,
    required this.stock,
    required this.priceEur,
    required this.priceLocal,
    required this.total,
  });

  factory QuotationItem.fromMap(Map<String, dynamic> map) {
    return QuotationItem(
      partId: map['partId'] ?? '',
      partCode: map['partCode'] ?? '',
      partName: map['partName'] ?? '',
      qty: map['qty'] ?? 0,
      stock: map['stock'] ?? 0,
      priceEur: (map['priceEur'] ?? 0).toDouble(),
      priceLocal: (map['priceLocal'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
    );
  }
}