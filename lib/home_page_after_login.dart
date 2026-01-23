import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login_page.dart';
import 'reports_page.dart';
import 'machinery_page.dart';
import 'pages/spare_part/spare_part_list_page.dart'; // ✅ tambahkan ini

// =====================================================
// HOME PAGE AFTER LOGIN
// =====================================================
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

  // =====================================================
  // LOGOUT CONFIRMATION
  // =====================================================
  Future<void> _confirmLogout(BuildContext context) async {
    final bool? result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Logout',
      barrierColor: Colors.black.withOpacity(0.3),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(color: Colors.black.withOpacity(0.1)),
            ),
            Center(
              child: Container(
                width: 320,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.25)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.logout, size: 36, color: Colors.white),
                    const SizedBox(height: 16),
                    const Text(
                      'Confirm Logout',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Are you sure you want to log out?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                        ),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Logout'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await FirebaseAuth.instance.signOut();
      if (!context.mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  // =====================================================
  // BUILD
  // =====================================================
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName =
        user?.displayName?.isNotEmpty == true ? user!.displayName! : 'User';
    final email = user?.email ?? '';

    return Scaffold(
      body: Stack(
        children: [
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
          IgnorePointer(
            ignoring: true,
            child: Container(
              color: Colors.black.withOpacity(0.05),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildHeader(displayName, email),
                ),
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: const [
                      SparePartMonitoringPage(),
                      ReportsPage(),
                      MachineryPage(),
                      Center(child: Text('Others')),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  child: _buildBottomMenu(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // HEADER
  // =====================================================
  Widget _buildHeader(String displayName, String email) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.35)),
          ),
          child: Row(
            children: [
              Image.asset('assets/images/Atom.png', width: 52, height: 52),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayName,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(email,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => _confirmLogout(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================
  // BOTTOM MENU
  // =====================================================
  Widget _buildBottomMenu() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.35)),
          ),
          child: Row(
            children: [
              _BottomItem(
                icon: Icons.inventory_2,
                label: 'Spare Part',
                color: _menuColors[0],
                active: _selectedIndex == 0,
                onTap: () => setState(() => _selectedIndex = 0),
              ),
              _BottomItem(
                icon: Icons.bar_chart,
                label: 'Reports',
                color: _menuColors[1],
                active: _selectedIndex == 1,
                onTap: () => setState(() => _selectedIndex = 1),
              ),
              _BottomItem(
                icon: Icons.precision_manufacturing,
                label: 'Machinery',
                color: _menuColors[2],
                active: _selectedIndex == 2,
                onTap: () => setState(() => _selectedIndex = 2),
              ),
              _BottomItem(
                icon: Icons.more_horiz,
                label: 'Others',
                color: _menuColors[3],
                active: _selectedIndex == 3,
                onTap: () => setState(() => _selectedIndex = 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================
// SPARE PART MONITORING PAGE
// =====================================================
class SparePartMonitoringPage extends StatelessWidget {
  const SparePartMonitoringPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _GlassMenuCard(
          icon: Icons.inventory,
          label: 'Database',
          color: Colors.blueGrey,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SparePartListPage(),
              ),
            );
          },
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
    );
  }
}

// =====================================================
// GLASS MENU CARD (UPDATED)
// =====================================================
class _GlassMenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _GlassMenuCard({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        splashColor: color.withOpacity(0.15),
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.35)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 42, color: color),
                  const SizedBox(height: 12),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
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
class _BottomItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  const _BottomItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color c = active ? color : Colors.black54;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: c),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                color: c,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
