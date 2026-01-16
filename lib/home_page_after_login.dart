import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:inventory_app/machinery_page.dart';

import 'login_page.dart';
import 'reports_page.dart';

class HomePageAfterLogin extends StatefulWidget {
  const HomePageAfterLogin({super.key});

  @override
  State<HomePageAfterLogin> createState() => _HomePageAfterLoginState();
}

class _HomePageAfterLoginState extends State<HomePageAfterLogin> {
  int _selectedIndex = 0;

  final List<Color> _menuColors = [
    Colors.blueGrey,
    Colors.blue,
    Colors.brown,
    Colors.blueAccent,
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName =
        user?.displayName?.isNotEmpty == true ? user!.displayName! : 'User';
    final email = user?.email ?? '';
    return Scaffold(
      body: Stack(
        children: [
          // ================= BACKGROUND =================
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFE0B2),
                  Color(0xFFFFFFFF),
                ],
              ),
            ),
          ),

          // ================= OVERLAY =================
          IgnorePointer(
            ignoring: true,
            child: Container(
              color: Colors.black.withOpacity(0.05),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ================= HEADER =================
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildHeader(displayName, email),
                ),

                // ================= BODY =================
                Expanded(
  child: AnimatedSwitcher(
    duration: const Duration(milliseconds: 300), // ← lebih lambat
    switchInCurve: Curves.easeOutCubic,           // ← lebih lembut
    switchOutCurve: Curves.easeInCubic,
    transitionBuilder: (child, animation) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(
            begin: 0.985, // ← sangat halus (sebelumnya 0.98)
            end: 1.0,
          ).animate(animation),
          child: child,
        ),
      );
    },
    child: IndexedStack(
      key: ValueKey(_selectedIndex),
      index: _selectedIndex,
      children: const [
        SparePartMonitoringPage(), // 0
        ReportsPage(),             // 1
        MachineryPage(),           // 2
        Center(child: Text('Others')), // 3
      ],
    ),
  ),
),

                // ================= BOTTOM MENU =================
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  child: _buildBottomMenu(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= HEADER =================
  Widget _buildHeader(String displayName, String email) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.35),
              ),
            ),
            child: Row(
              children: [
                Image.asset(
                  'assets/images/Atom.png',
                  width: 52,
                  height: 52,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (!context.mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginPage(),
                      ),
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= BOTTOM MENU =================
  Widget _buildBottomMenu(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.35),
              ),
            ),
            child: Row(
              children: [
                // ===== SPARE PART =====
                _ColoredBottomMenuItem(
                  icon: Icons.inventory_2,
                  label: 'Spare Part',
                  color: _menuColors[0],
                  isActive: _selectedIndex == 0,
                  onTap: () => setState(() => _selectedIndex = 0),
                ),

                // ===== REPORTS (OUTSIDE HOME) =====
                _ColoredBottomMenuItem(
  icon: Icons.bar_chart,
  label: 'Reports',
  color: _menuColors[1],
  isActive: _selectedIndex == 1,
  onTap: () {
    setState(() => _selectedIndex = 1);
  },
),

                // ===== MACHINERY =====
                _ColoredBottomMenuItem(
  icon: Icons.precision_manufacturing,
  label: 'Machinery',
  color: _menuColors[2],
  isActive: _selectedIndex == 2,
  onTap: () => setState(() => _selectedIndex = 2),
),

                // ===== OTHERS =====
                _ColoredBottomMenuItem(
  icon: Icons.more_horiz,
  label: 'Others',
  color: _menuColors[3],
  isActive: _selectedIndex == 3,
  onTap: () => setState(() => _selectedIndex = 3),
),

              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================
// SPARE PART MONITORING (4 MENU GRID – RESTORED)
// =====================================================
class SparePartMonitoringPage extends StatelessWidget {
  const SparePartMonitoringPage({super.key});

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
          _GlassMenuCard(
            icon: Icons.inventory,
            label: 'Database',
            color: Colors.blueGrey,
          ),
          _GlassMenuCard(
            icon: Icons.input,
            label: 'Orders In',
            color: Colors.green,
          ),
          _GlassMenuCard(
            icon: Icons.output,
            label: 'Orders Out',
            color: Colors.redAccent,
          ),
          _GlassMenuCard(
            icon: Icons.groups,
            label: 'Partners',
            color: Colors.deepPurple,
          ),
        ],
      ),
    );
  }
}

// =====================================================
// GLASS MENU CARD (SPARE PART)
// =====================================================
class _GlassMenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _GlassMenuCard({
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
        splashColor: color.withOpacity(0.15),
        highlightColor: color.withOpacity(0.08),
        onTap: () {
          debugPrint('$label tapped');
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
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
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: color.withOpacity(0.85),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 28,
                      height: 3,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.6),
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


// =====================================================
// BOTTOM MENU ITEM
// =====================================================
class _ColoredBottomMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  const _ColoredBottomMenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color activeColor = isActive ? color : Colors.black54;

    return Expanded(
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: activeColor),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.normal,
                  color: activeColor,
                ),
              ),
              const SizedBox(height: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 3,
                width: isActive ? 22 : 6,
                decoration: BoxDecoration(
                  color: isActive ? color : Colors.black26,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
