// === STEP 1: ROLE SERVICE START ===

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum UserRole {
  superAdmin,
  admin,
  user,
}

class RoleService {
  static Future<UserRole> getUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return UserRole.user;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return UserRole.user;

      final data = userDoc.data()!;
      final companyIds = List<String>.from(data['companyIds'] ?? []);

      final hasIndonesia =
          companyIds.any((e) => e.toLowerCase().contains('indonesia'));
      final hasIndia =
          companyIds.any((e) => e.toLowerCase().contains('india'));
      final hasVietnam =
          companyIds.any((e) => e.toLowerCase().contains('vietnam'));

      if (hasIndonesia && hasIndia && hasVietnam) {
        return UserRole.superAdmin;
      }

      final adminDoc = await FirebaseFirestore.instance
          .collection('admin_whitelist')
          .doc(user.email!.toLowerCase())
          .get();

      if (adminDoc.exists) {
        return UserRole.admin;
      }

      return UserRole.user;
    } catch (e) {
      return UserRole.user;
    }
  }
}

// === STEP 1: ROLE SERVICE END ===