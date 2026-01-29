import 'dart:ui';
import 'package:flutter/material.dart';

class MachineryPage extends StatelessWidget {
  const MachineryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.1,
        children: const [
          _GlassMachineryMenuCard(
            icon: Icons.precision_manufacturing,
            label: 'Machine List',
            color: Colors.blueGrey,
          ),
          _GlassMachineryMenuCard(
            icon: Icons.menu_book,
            label: 'Machine Manual',
            color: Colors.green,
          ),
          _GlassMachineryMenuCard(
            icon: Icons.inventory_2,
            label: 'Machine Catalogue',
            color: Colors.deepPurple,
          ),
          _GlassMachineryMenuCard(
            icon: Icons.verified_user,
            label: 'Licenses',
            color: Colors.redAccent,
          ),
        ],
      ),
    );
  }
}

// =====================================================
// GLASS MACHINERY MENU CARD
// ICON DIMENSION = SPARE PART & REPORTS
// =====================================================
class _GlassMachineryMenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _GlassMachineryMenuCard({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        splashColor: color.withValues(alpha:0.15),
        highlightColor: color.withValues(alpha:0.08),
        onTap: () {
          debugPrint('$label tapped');
          // nanti: navigasi ke halaman detail
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.12),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ===== ICON (JANGAN DIUBAH DIMENSI) =====
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: Icon(
                          icon,
                          color: color,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ===== LABEL =====
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: color.withValues(alpha:0.85),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ===== INDICATOR =====
                    Container(
                      width: 28,
                      height: 3,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha:0.6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
