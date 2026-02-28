import 'package:flutter/material.dart';
import 'home_mobile.dart';
import 'home_desktop.dart';

class HomePageAfterLogin extends StatelessWidget {
  const HomePageAfterLogin({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // Tablet landscape & desktop
    if (width >= 800) {
      return const HomeDesktop();
    }

    // Phone
    return const HomeMobile();
  }
}