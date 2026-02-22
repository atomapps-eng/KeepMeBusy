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

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  String? _lastUid;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Reset state saat app kembali ke foreground
    if (state == AppLifecycleState.resumed) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Handle loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Handle error
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${snapshot.error}'),
                  ElevatedButton(
                    onPressed: () {
                      FirebaseAuth.instance.signOut();
                    },
                    child: const Text('Logout'),
                  ),
                ],
              ),
            ),
          );
        }

        final user = snapshot.data;

        // KALO USER NULL -> LOGIN PAGE
        if (user == null) {
          // Reset semua state
          _lastUid = null;
          
          // Clear session secara async
          WidgetsBinding.instance.addPostFrameCallback((_) {
            CompanySession.clear();
          });
          
          // Gunakan key yang berbeda untuk force rebuild
          return const LoginPage(key: ValueKey('login_page'));
        }

        // USER TIDAK NULL -> CEK PERUBAHAN UID
        if (_lastUid != user.uid) {
          _lastUid = user.uid;
          // Clear session untuk user baru
          CompanySession.clear();
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
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Error atau data tidak ada
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("User document not found"),
                  ElevatedButton(
                    onPressed: () {
                      FirebaseAuth.instance.signOut();
                    },
                    child: const Text('Logout'),
                  ),
                ],
              ),
            ),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final companies = List<String>.from(data['companyIds'] ?? []);

        if (companies.isEmpty) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("No company assigned"),
                  ElevatedButton(
                    onPressed: () {
                      FirebaseAuth.instance.signOut();
                    },
                    child: const Text('Logout'),
                  ),
                ],
              ),
            ),
          );
        }

        // Validasi session
        final current = CompanySession.selectedCompanyId;
        if (current != null && !companies.contains(current)) {
          CompanySession.clear();
        }

        // Single company - langsung ke home
        if (companies.length == 1) {
          return FutureBuilder(
            future: CompanySession.setCompany(companies.first),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              return const HomePageAfterLogin(key: ValueKey('home_page'));
            },
          );
        }

        // Multiple companies - pilih dulu
        if (CompanySession.selectedCompanyId != null) {
          return const HomePageAfterLogin(key: ValueKey('home_page'));
        }

        return SelectCompanyPage(
          key: ValueKey('select_company_${companies.length}'),
          companyIds: companies,
        );
      },
    );
  }
}