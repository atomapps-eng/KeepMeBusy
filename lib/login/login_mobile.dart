import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth_gate.dart';
import '../core/session/company_session.dart';
import '../features/auth/select_company_page.dart';

class LoginMobile extends StatefulWidget {
  const LoginMobile({super.key});

  @override
  State<LoginMobile> createState() => _LoginMobileState();
}

class _LoginMobileState extends State<LoginMobile> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool _isLoading = false;
  bool _showCard = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredential();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _showCard = true);
    });
  }

  Future<void> _loadSavedCredential() async {
    final prefs = await SharedPreferences.getInstance();
    emailController.text = prefs.getString('saved_email') ?? '';
    passwordController.text = prefs.getString('saved_password') ?? '';
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (!mounted) return;

      final uid = FirebaseAuth.instance.currentUser!.uid;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      final companyIds = List<String>.from(userDoc['companyIds'] ?? []);

      // 🔥 LOGIC COMPANY ROUTING
      if (CompanySession.selectedCompanyId == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SelectCompanyPage(companyIds: companyIds),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AuthGate()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message ?? 'Login gagal')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFE0B2), Color(0xFFFFFFFF)],
              ),
            ),
          ),
          Positioned(
            top: height * 0.18,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'assets/images/Atom.png',
                height: height * 0.14,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, height * 0.28, 24, 24),
                child: Column(
                  children: [
                    Text(
                      'Welcome Back',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Login to your account',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 32),
                    LoginCard(
                      formKey: _formKey,
                      emailController: emailController,
                      passwordController: passwordController,
                      isLoading: _isLoading,
                      showCard: _showCard,
                      onLogin: _handleLogin,
                      onForgotPassword: _forgotPassword,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _forgotPassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan email terlebih dahulu')),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Email reset terkirim')));
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? 'Terjadi kesalahan')));
    }
  }
}
