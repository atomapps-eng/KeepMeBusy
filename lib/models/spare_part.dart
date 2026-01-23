class SparePart {
  final String partCode;
  final String name;
  final String nameEn;
  final String location;
  final int stock;
  final double weight;
  final String weightUnit;
  final String imageUrl; // ✅ hanya satu kali

  SparePart({
    required this.partCode,
    required this.name,
    required this.nameEn,
    required this.location,
    required this.stock,
    required this.weight,
    required this.weightUnit,
    required this.imageUrl, // ✅ hanya satu kali
  });

  factory SparePart.fromFirestore(Map<String, dynamic> data) {
    return SparePart(
      partCode: data['partCode'] ?? '',
      name: data['name'] ?? '',
      nameEn: data['nameEn'] ?? '',
      location: data['location'] ?? '',
      stock: data['stock'] ?? 0,
      weight: (data['weight'] ?? 0).toDouble(),
      weightUnit: data['weightUnit'] ?? 'Kg',
      imageUrl: data['imageUrl'] ?? '', // ✅ hanya satu kali
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'partCode': partCode,
      'name': name,
      'nameEn': nameEn,
      'location': location,
      'stock': stock,
      'weight': weight,
      'weightUnit': weightUnit,
      'imageUrl': imageUrl,
    };
  }
}
