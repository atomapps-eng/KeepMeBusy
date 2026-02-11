import 'package:flutter/material.dart';
import 'login_mobile.dart';
import 'login_desktop.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  static const double desktopBreakpoint = 900;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= desktopBreakpoint) {
          return const LoginDesktop();
        }
        return const LoginMobile();
      },
    );
  }
}
