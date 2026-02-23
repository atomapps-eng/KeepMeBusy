import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_card.dart';

class LoginDesktop extends StatefulWidget {
  const LoginDesktop({super.key});

  @override
  State<LoginDesktop> createState() => _LoginDesktopState();
}

class _LoginDesktopState extends State<LoginDesktop> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool _isLoading = false;
  final bool _showCard = true;

  // Di login_desktop.dart, perbaiki _handleLogin:
Future<void> _handleLogin() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  try {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );
    
    // Login sukses, AuthGate akan otomatis menangani navigasi
    // Tidak perlu navigasi manual
    
  } on FirebaseAuthException catch (e) {
    String message = 'Login gagal';
    if (e.code == 'user-not-found') {
      message = 'Email tidak terdaftar';
    } else if (e.code == 'wrong-password') {
      message = 'Password salah';
    } else if (e.code == 'invalid-email') {
      message = 'Email tidak valid';
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  } catch (e) {
    print("ERROR: $e");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final sidebarWidth = (width * 0.28).clamp(280.0, 420.0);
        final cardMaxWidth = width < 1200 ? 420.0 : 520.0;

        return Scaffold(
          body: Row(
            children: [
              Container(
                width: sidebarWidth,
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
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/Atom.png',
                        height: sidebarWidth * 0.45,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Welcome Back',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Login to your account',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: cardMaxWidth),
                    child: LoginCard(
                      formKey: _formKey,
                      emailController: emailController,
                      passwordController: passwordController,
                      isLoading: _isLoading,
                      showCard: _showCard,
                      onLogin: _handleLogin,
                      onForgotPassword: _forgotPassword,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
    await FirebaseAuth.instance
        .sendPasswordResetEmail(email: email);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Email reset terkirim')),
    );
  } on FirebaseAuthException catch (e) {
     print("AUTH ERROR: ${e.code}");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.message ?? 'Terjadi kesalahan')),
    );
  }
  catch (e) {
  print("UNKNOWN ERROR: $e");
}
}
@override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
