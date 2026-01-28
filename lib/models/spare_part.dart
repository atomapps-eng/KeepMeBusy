enum SparePartCategory {
  autoCutting,
  manualCutting,
}

enum SparePartOrigin {
  atomItaly,
  atomShanghai,
  local,
}

class SparePart {
  final String id;
  final String partCode;
  final String name;
  final String nameEn;
  final String location;
  final int stock; // LEGACY - jangan dipakai untuk logic baru
  final int initialStock;
  final int currentStock;
  final int minimumStock;
  final double weight;
  final String weightUnit;
  final String imageUrl;
  final int imageVersion;
  final SparePartCategory category;
  final SparePartOrigin origin;


  SparePart({
    required this.id,
    required this.partCode,
    required this.name,
    required this.nameEn,
    required this.location,
    required this.stock,
    required this.initialStock,   // ⬅️ baru
    required this.currentStock,
    required this.minimumStock,   // ⬅️ baru
    required this.weight,
    required this.weightUnit,
    required this.imageUrl,
    this.imageVersion = 0,
    this.category = SparePartCategory.autoCutting,
    this.origin = SparePartOrigin.local,

  });

  factory SparePart.fromMap(Map<String, dynamic> data, String id) {
    return SparePart(
      id: id,
      partCode: (data['partCode'] ?? id).toString(),
      name: (data['name'] ?? '').toString(),
      nameEn: (data['nameEn'] ?? '').toString(),
      location: (data['location'] ?? '').toString(),

      // ✅ SAFE PARSING (INI KUNCI FIX ERROR)
      stock: _safeInt(data['stock']),
      initialStock: data['initialStock'] ?? data['stock'] ?? 0,
      currentStock: data['currentStock'] ?? data['stock'] ?? 0,
      minimumStock: (data['minimumStock'] ?? 0) as int,
      weight: _safeDouble(data['weight']),

      weightUnit: (data['weightUnit'] ?? 'Kg').toString(),
      imageUrl: (data['imageUrl'] ?? '').toString(),
      imageVersion: _safeInt(data['imageVersion']),

      category: SparePartCategory.values.firstWhere(
     (e) => e.name.toUpperCase() == (data['category'] ?? 'AUTO_CUTTING'),
     orElse: () => SparePartCategory.autoCutting,
     ),

     origin: SparePartOrigin.values.firstWhere(
     (e) => e.name.toUpperCase() == (data['origin'] ?? 'LOCAL'),
     orElse: () => SparePartOrigin.local,
     ),

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

Map<String, dynamic> toMap() {
  return {
    'partCode': partCode,
    'name': name,
    'nameEn': nameEn,
    'location': location,
    'stock': stock,
    'initialStock': initialStock,
    'currentStock': currentStock,
    'minimumStock': minimumStock,
    'weight': weight,
    'weightUnit': weightUnit,
    'imageUrl': imageUrl,
    'imageVersion': imageVersion,
    'category': category.name.toUpperCase(),
    'origin': origin.name.toUpperCase(),
  };
}

}
