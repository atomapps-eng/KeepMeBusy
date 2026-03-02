import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  static final _firestore = FirebaseFirestore.instance;

  static Future<bool> isAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final doc = await _firestore
        .collection('admin_whitelist')
        .doc(user.uid)
        .get();

    if (!doc.exists) return false;

    final data = doc.data();
    return data?['active'] == true;
  }
}