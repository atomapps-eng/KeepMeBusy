import 'package:cloud_firestore/cloud_firestore.dart';

// lib/models/user_model.dart
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role; // super_admin / admin / user
  final String position; // technician / dll
  final List<String> companyIds;
  final bool active;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.position,
    required this.companyIds,
    required this.active,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'user',
      position: data['position'] ?? '',
      companyIds: List<String>.from(data['companyIds'] ?? []),
      active: data['active'] ?? true,
    );
  }
}