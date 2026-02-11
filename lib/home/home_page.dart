import 'package:flutter/material.dart';
import 'home_mobile.dart';
import 'home_desktop.dart';

class HomePageAfterLogin extends StatelessWidget {
  const HomePageAfterLogin({super.key});

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;

    final isDesktopPlatform =
        platform == TargetPlatform.windows ||
        platform == TargetPlatform.macOS ||
        platform == TargetPlatform.linux;

    if (isDesktopPlatform) {
      return const HomeDesktop();
    }

    return const HomeMobile();
  }
}
