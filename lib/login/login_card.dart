import 'dart:ui';
import 'package:flutter/material.dart';

class LoginCard extends StatelessWidget {
  final GlobalKey<FormState>? formKey;
  final TextEditingController? emailController;
  final TextEditingController? passwordController;
  final bool isLoading;
  final bool showCard;
  final VoidCallback? onLogin;
  final VoidCallback? onForgotPassword;

  const LoginCard({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.showCard,
    required this.onLogin,
    required this.onForgotPassword,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      opacity: showCard ? 1 : 0,
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
  key: formKey,
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [

      // EMAIL
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

      // PASSWORD
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

      // LOGIN BUTTON
      SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: isLoading ? null : onLogin,
          child: isLoading
              ? const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                )
              : const Text('Login'),
        ),
      ),

      const SizedBox(height: 12),

      // REGISTER
      TextButton(
        onPressed: () {
          Navigator.pushNamed(context, '/register');
        },
        child: const Text('Register'),
      ),

      // FORGOT PASSWORD
      TextButton(
        onPressed: onForgotPassword,
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
