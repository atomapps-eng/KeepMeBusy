import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'auth_gate.dart';
import 'register_page.dart';
import 'tools/migration_page.dart';
import 'core/session/company_session.dart';
import 'package:provider/provider.dart';
import 'auth_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
// Global navigator key//
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await CompanySession.load();

  // 🔥 Detect screen size sebelum runApp
  final window = WidgetsBinding.instance.platformDispatcher.views.first;
  final logicalSize = window.physicalSize / window.devicePixelRatio;

  if (logicalSize.width >= 800) {
    // Tablet → lock landscape
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  } else {
    // Phone → allow all orientations
    await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthController(),
        ),
      ],
      child: const KeepMeBusyApp(),
    ),
  );
}

// Global logout function
Future<void> globalLogout(BuildContext context) async {
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
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saat logout: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}

class KeepMeBusyApp extends StatelessWidget {
  const KeepMeBusyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
  navigatorKey: navigatorKey,
  scaffoldMessengerKey: rootScaffoldMessengerKey, // 🔥 TAMBAHKAN INI
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