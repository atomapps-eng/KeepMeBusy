import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/session/company_session.dart';
import '../auth_gate.dart'; // Tambahkan import ini

class LogoutHelper {
  static Future<void> logout(BuildContext context) async {
    try {
      // Clear session dulu
      await CompanySession.clear();
      
      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();
      
      if (context.mounted) {
        // Push replacement with AuthGate
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (route) => false,
        );
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Berhasil logout'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Logout error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saat logout: $e')),
        );
      }
    }
  }
}