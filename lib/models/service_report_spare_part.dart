class ServiceReportSparePart {
  final String partCode;
  final String name;
  final int qty;
  final int currentStock;
  final String location;

  ServiceReportSparePart({
    required this.partCode,
    required this.name,
    required this.qty,
    required this.currentStock,
    required this.location,
  });

  Map<String, dynamic> toMap() {
    return {
      'partCode': partCode,
      'name': name,
      'qty': qty,
      'currentStock': currentStock,
      'location': location,
    };
  }

  factory ServiceReportSparePart.fromMap(Map<String, dynamic> map) {
    return ServiceReportSparePart(
      partCode: map['partCode'] ?? '',
      name: map['name'] ?? '',
      qty: _safeInt(map['qty']),
      currentStock: _safeInt(map['currentStock']),
      location: map['location'] ?? '',
    );
  }

  static int _safeInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}
