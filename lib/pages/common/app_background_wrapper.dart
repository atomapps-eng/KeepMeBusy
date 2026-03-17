import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AppBackgroundWrapper extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const AppBackgroundWrapper({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ===== BACKGROUND GRADIENT (SAMA DENGAN HOME) =====
          Container(
            decoration: BoxDecoration(
  gradient: AppTheme.backgroundGradient,
),
          ),

          SafeArea(
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
