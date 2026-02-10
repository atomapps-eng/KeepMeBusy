import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'register_page.dart';
import 'home_page_after_login.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLoading = false;
  bool _showCard = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredential();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() => _showCard = true);
      }
    });
  }

  // =====================================================
  // LOAD SAVED CREDENTIAL
  // =====================================================
  Future<void> _loadSavedCredential() async {
    final prefs = await SharedPreferences.getInstance();
    emailController.text = prefs.getString('saved_email') ?? '';
    passwordController.text = prefs.getString('saved_password') ?? '';
  }

  // =====================================================
  // GLASS SNACKBAR
  // =====================================================
  void showGlassSnackBar(
    String message, {
    Color backgroundColor = Colors.white,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: backgroundColor.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // FORGOT PASSWORD
  // =====================================================
  Future<void> _forgotPassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      showGlassSnackBar(
        'Silakan masukkan email terlebih dahulu',
        backgroundColor: Colors.orange,
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Email terkirim'),
          content: const Text(
            'Link reset password telah dikirim ke email Anda.\n'
            'Silakan cek inbox atau folder spam.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      showGlassSnackBar(
        e.message ?? 'Gagal mengirim email reset password',
        backgroundColor: Colors.red,
      );
    }
  }

  // =====================================================
  // LOGIN HANDLER (LOGIC ASLI ANDA)
  // =====================================================
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final navigator = Navigator.of(context);

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_email', emailController.text.trim());
      await prefs.setString('saved_password', passwordController.text.trim());

      if (!mounted) return;

      setState(() => _isLoading = false);

      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (_) => const HomePageAfterLogin(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      showGlassSnackBar(
        e.message ?? 'Login gagal',
        backgroundColor: Colors.red,
      );
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // =====================================================
  // RESPONSIVE ROOT
  // =====================================================
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return _buildDesktopLogin(context);
        } else {
          return _buildMobileLogin(context);
        }
      },
    );
  }

  // =====================================================
  // MOBILE LOGIN (UI ASLI ANDA — TIDAK DIUBAH)
  // =====================================================
  Widget _buildMobileLogin(BuildContext context) {
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
                colors: [
                  Color(0xFFFFE0B2),
                  Color(0xFFFFFFFF),
                ],
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
                    _loginCard(context),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // DESKTOP LOGIN (WINDOWS STYLE)
  // =====================================================
  Widget _buildDesktopLogin(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 320,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFE0B2),
                  Color(0xFFFFFFFF),
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/Atom.png', height: 120),
                const SizedBox(height: 24),
                const Text(
                  'Welcome Back',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Login to your account',
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: _loginCard(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // LOGIN CARD (DIPAKAI MOBILE & DESKTOP)
  // =====================================================
  Widget _loginCard(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      opacity: _showCard ? 1 : 0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black12),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email wajib diisi';
                      }
                      if (!value.contains('@')) {
                        return 'Format email tidak valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password wajib diisi';
                      }
                      if (value.length < 6) {
                        return 'Minimal 6 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            )
                          : const Text('Login'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RegisterPage(),
                        ),
                      );
                    },
                    child: const Text('Register'),
                  ),
                  TextButton(
                    onPressed: _forgotPassword,
                    child: const Text('Forgot Password?'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
