class SparePart {
  final String partCode;
  final String name;
  final String nameEn;
  final String location;
  final int stock; // LEGACY - jangan dipakai untuk logic baru
  final int initialStock;
  final int currentStock;
  final double weight;
  final String weightUnit;
  final String imageUrl;
  final int imageVersion;

  SparePart({
    required this.partCode,
    required this.name,
    required this.nameEn,
    required this.location,
    required this.stock,
    required this.initialStock,   // ⬅️ baru
    required this.currentStock,   // ⬅️ baru
    required this.weight,
    required this.weightUnit,
    required this.imageUrl,
    this.imageVersion = 0,
  });

  factory SparePart.fromMap(Map<String, dynamic> data, String id) {
    return SparePart(
      partCode: (data['partCode'] ?? id).toString(),
      name: (data['name'] ?? '').toString(),
      nameEn: (data['nameEn'] ?? '').toString(),
      location: (data['location'] ?? '').toString(),

      // ✅ SAFE PARSING (INI KUNCI FIX ERROR)
      stock: _safeInt(data['stock']),
      initialStock: data['initialStock'] ?? data['stock'] ?? 0,
      currentStock: data['currentStock'] ?? data['stock'] ?? 0,

      weight: _safeDouble(data['weight']),

      weightUnit: (data['weightUnit'] ?? 'Kg').toString(),
      imageUrl: (data['imageUrl'] ?? '').toString(),
      imageVersion: _safeInt(data['imageVersion']),
    );
  }

  static int _safeInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _safeDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}
