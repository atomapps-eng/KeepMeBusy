import 'package:cloud_firestore/cloud_firestore.dart';

enum SparePartCategory {
  autoCutting,
  manualCutting;

  @override
  String toString() {
    switch (this) {
      case SparePartCategory.autoCutting:
        return 'AUTO CUTTING';
      case SparePartCategory.manualCutting:
        return 'MANUAL CUTTING';
    }
  }
}

enum SparePartOrigin {
  atomItaly,
  atomShanghai,
  local;

  @override
  String toString() {
    switch (this) {
      case SparePartOrigin.atomItaly:
        return 'ATOM ITALY';
      case SparePartOrigin.atomShanghai:
        return 'ATOM SHANGHAI';
      case SparePartOrigin.local:
        return 'LOCAL';
    }
  }
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
  final double basePriceEur;
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
    this.basePriceEur = 0.0,
    required this.imageUrl,
    this.imageVersion = 0,
    this.category = SparePartCategory.autoCutting,
    this.origin = SparePartOrigin.local,

  });

  factory SparePart.fromFirestore(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;
  return SparePart.fromMap(data, doc.id);
}

factory SparePart.fromJson(Map<String, dynamic> json) {
  return SparePart(
    id: json['id'],
    partCode: json['partCode'],
    name: json['name'],
    nameEn: json['nameEn'],
    location: json['location'],

    stock: json['stock'] ?? 0,
    initialStock: json['initialStock'] ?? 0,
    currentStock: json['currentStock'] ?? 0,
    minimumStock: json['minimumStock'] ?? 0,

    weight: (json['weight'] ?? 0).toDouble(),
    weightUnit: json['weightUnit'] ?? 'Kg',

    basePriceEur: (json['basePriceEur'] ?? 0).toDouble(),

    imageUrl: json['imageUrl'] ?? '',
    imageVersion: json['imageVersion'] ?? 0,

    category: SparePartCategory.values.firstWhere(
      (e) => e.name == json['category'],
      orElse: () => SparePartCategory.autoCutting,
    ),

    origin: SparePartOrigin.values.firstWhere(
      (e) => e.name == json['origin'],
      orElse: () => SparePartOrigin.local,
    ),
  );
}

Map<String, dynamic> toJson() {
  return {
    'id': id,
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

    'basePriceEur': basePriceEur,

    'imageUrl': imageUrl,
    'imageVersion': imageVersion,

    'category': category.name,
    'origin': origin.name,
  };
}

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
      basePriceEur: (data['basePriceEur'] ?? 0).toDouble(),
      imageUrl: (data['imageUrl'] ?? '').toString(),
      imageVersion: _safeInt(data['imageVersion']),

     category: SparePartCategory.values.firstWhere(
  (e) =>
      e.name.replaceAll('_', '').toUpperCase() ==
      (data['category'] ?? '')
          .replaceAll(' ', '')
          .toUpperCase(),
  orElse: () => SparePartCategory.autoCutting,
),

origin: SparePartOrigin.values.firstWhere(
  (e) =>
      e.name.replaceAll('_', '').toUpperCase() ==
      (data['origin'] ?? '')
          .replaceAll(' ', '')
          .toUpperCase(),
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
    'basePriceEur': basePriceEur,
    'imageUrl': imageUrl,
    'imageVersion': imageVersion,
    'category': category.name.toUpperCase(),
    'origin': origin.name.toUpperCase(),
  };
}

}
