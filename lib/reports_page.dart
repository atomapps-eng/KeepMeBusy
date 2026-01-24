import 'package:flutter/material.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.15,
        children: const [
          _ReportMenuCard(
            icon: Icons.fact_check,
            label: 'Daily Attendance',
            color: Colors.blueGrey,
          ),
          _ReportMenuCard(
            icon: Icons.build_circle,
            label: 'Service Reports',
            color: Colors.green,
          ),
          _ReportMenuCard(
            icon: Icons.flight_takeoff,
            label: 'Business Trip Report',
            color: Colors.redAccent,
          ),
        ],
      ),
    );
  }
}

// =====================================================
// REPORT MENU CARD (ORIGINAL ICON DIMENSION PRESERVED)
// =====================================================
class _ReportMenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ReportMenuCard({
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
        onTap: () {
          debugPrint('$label tapped');
          // nanti navigasi ke halaman detail
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
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.30),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha:0.40),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ===== ICON (TIDAK DIUBAH) =====
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
)              ,


                const SizedBox(height: 12),

                // ===== LABEL =====
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
