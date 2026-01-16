import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLoading = false;

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
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
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
  // CEK EMAIL DI WHITELIST
  // =====================================================
  Future<bool> _isEmailWhitelisted(String email) async {
    final doc = await FirebaseFirestore.instance
        .collection('whitelist_emails')
        .doc(email.toLowerCase())
        .get();

    if (!doc.exists) return false;
    final data = doc.data();
    if (data == null) return false;

    return data['active'] == true;
  }

  // =====================================================
  // CEK USERNAME DUPLIKAT
  // =====================================================
  Future<bool> _isUsernameAvailable(String username) async {
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: username.toLowerCase())
        .limit(1)
        .get();

    return query.docs.isEmpty;
  }

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // =====================================================
  // REGISTER LOGIC
  // =====================================================
  Future<void> _register() async {
    final username = usernameController.text.trim();
    final email = emailController.text.trim().toLowerCase();
    final password = passwordController.text.trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      showGlassSnackBar(
        'Username, email, dan password wajib diisi',
        backgroundColor: Colors.orange,
      );
      return;
    }

    setState(() => _isLoading = true);

    // CEK USERNAME DUPLIKAT
    ('CHECK USERNAME START');
    final isUsernameFree = await _isUsernameAvailable(username);
    if (!mounted) return;

    if (!isUsernameFree) {
      setState(() => _isLoading = false);
      showGlassSnackBar(
        'Username sudah digunakan. Silakan pilih yang lain.',
        backgroundColor: Colors.orange,
      );
      return;
    }

    try {
      final isAllowed = await _isEmailWhitelisted(email);
      if (!mounted) return;

      if (!isAllowed) {
        setState(() => _isLoading = false);
        showGlassSnackBar(
          'Email ini tidak diizinkan untuk mendaftar. Silakan hubungi admin.',
          backgroundColor: Colors.red,
        );
        return;
      }

      // CREATE USER
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final currentUser = FirebaseAuth.instance.currentUser;

      // SIMPAN KE FIRESTORE
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .set({
        'username': username.toLowerCase(),
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // SET DISPLAY NAME
      await currentUser.updateDisplayName(username);
      await currentUser.reload();

      // LOGOUT
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      setState(() => _isLoading = false);

      showGlassSnackBar(
        'Registrasi berhasil. Silakan login.',
        backgroundColor: Colors.green,
      );

      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      showGlassSnackBar(
        e.message ?? 'Register gagal',
        backgroundColor: Colors.red,
      );
    }
  }

  // =====================================================
  // UI
  // =====================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Register'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
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
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Create Account',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontFamily: 'Roboto'),
                        ),
                        const SizedBox(height: 24),

                        TextFormField(
                          controller: usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email),
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock),
                          ),
                        ),
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _register,
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  )
                                : const Text('Register'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
