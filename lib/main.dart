import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme/app_theme.dart';
import 'auth_gate.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const KeepMeBusyApp());
}

class KeepMeBusyApp extends StatelessWidget {
  const KeepMeBusyApp({super.key});

  @override
Widget build(BuildContext context) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Keep Me Busy',
    theme: AppTheme. lightTheme,
    home: const AuthGate(),
  );
}
}
