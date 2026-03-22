// === STEP 1: ROLE SERVICE START ===

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
//
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
    final role = data['role'];
    final accessLevel = data['accessLevel'];

    // ✅ PRIORITAS 1
    if (role == 'super_admin') {
      return UserRole.superAdmin;
    }

    // ✅ PRIORITAS 2
    if (accessLevel == 'admin_countries') {
      return UserRole.admin;
    }

    return UserRole.user;
  } catch (e) {
    return UserRole.user;
  }
}
}

// === STEP 1: ROLE SERVICE END ===