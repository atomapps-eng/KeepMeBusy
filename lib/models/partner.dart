import 'package:cloud_firestore/cloud_firestore.dart';

class Partner {
  final String id;
  final String name;
  final String address;
  final double? lat;
  final double? lng;
  final String? phone;
  final String? email;
  final String logoUrl;

  // ⬇️ BUAT NULLABLE
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  Partner({
    required this.id,
    required this.name,
    required this.address,
    this.lat,
    this.lng,
    this.phone,
    this.email,
    required this.logoUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory Partner.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Partner(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      lat: (data['lat'] as num?)?.toDouble(),
      lng: (data['lng'] as num?)?.toDouble(),
      phone: data['phone'],
      email: data['email'],
      logoUrl: data['logoUrl'] ?? '',
      createdAt: data['createdAt'],
      updatedAt: data['updatedAt'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'address': address,
      'lat': lat,
      'lng': lng,
      'phone': phone,
      'email': email,
      'logoUrl': logoUrl,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
