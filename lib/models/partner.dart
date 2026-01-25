import 'package:cloud_firestore/cloud_firestore.dart';

class Partner {
  final String id; // Firestore auto ID
  final String name;
  final String address;
  final double lat;
  final double lng;
  final String logoUrl;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  Partner({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.logoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Partner.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Partner(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      lat: (data['geo']?['lat'] ?? 0).toDouble(),
      lng: (data['geo']?['lng'] ?? 0).toDouble(),
      logoUrl: data['logoUrl'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'geo': {
        'lat': lat,
        'lng': lng,
      },
      'logoUrl': logoUrl,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
