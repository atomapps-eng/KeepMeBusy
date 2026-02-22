import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'auth_gate.dart';
import 'register_page.dart';
import 'tools/migration_page.dart';
import 'core/session/company_session.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await CompanySession.load();

  runApp(const KeepMeBusyApp());
}

class KeepMeBusyApp extends StatelessWidget {
  const KeepMeBusyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Keep Me Busy',
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
      routes: {
        '/register': (_) => const RegisterPage(),
        '/migration': (_) => const MigrationPage(),
      },
    );
  }
}