import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'login/login_page.dart';
import 'home/home_page.dart';
import '../features/auth/select_company_page.dart';
import 'core/session/company_session.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {

  String? _lastUid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          _lastUid = null;
          CompanySession.clear();
          return const LoginPage();
        }

        // 🔥 DETEKSI USER BERUBAH
        if (_lastUid != user.uid) {
          CompanySession.clear();
          _lastUid = user.uid;
        }

        return _buildUserCompanyLayer(user);
      },
    );
  }

  Widget _buildUserCompanyLayer(User user) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text("User doc missing")),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final companies = List<String>.from(data['companyIds'] ?? []);

        if (companies.isEmpty) {
          return const Scaffold(
            body: Center(child: Text("No company assigned")),
          );
        }

        // 🔥 VALIDASI SESSION
        final current = CompanySession.selectedCompanyId;

        if (current != null && !companies.contains(current)) {
          CompanySession.clear();
        }

        if (companies.length == 1) {
          CompanySession.selectedCompanyId = companies.first;
          return const HomePageAfterLogin();
        }

        if (CompanySession.selectedCompanyId != null) {
          return const HomePageAfterLogin();
        }

        return SelectCompanyPage(companyIds: companies);
      },
    );
  }
}