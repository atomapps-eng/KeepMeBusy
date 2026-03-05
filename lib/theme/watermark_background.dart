import 'package:flutter/material.dart';

class WatermarkBackground extends StatelessWidget {
  const WatermarkBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Opacity(
          opacity: 0.05, // transparansi watermark
          child: Image.asset(
            'assets/images/Atom.png',
            width: 400,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}