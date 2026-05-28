import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  static final _firestore = FirebaseFirestore.instance;

  static Future<bool> isAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final uidDoc = await _firestore
        .collection('admin_whitelist')
        .doc(user.uid)
        .get();

    if (uidDoc.exists && uidDoc.data()?['active'] == true) return true;

    final email = user.email?.toLowerCase().trim();
    if (email == null || email.isEmpty) return false;

    final emailDoc = await _firestore
        .collection('admin_whitelist')
        .doc(email)
        .get();

    return emailDoc.exists && emailDoc.data()?['active'] == true;
  }
}
