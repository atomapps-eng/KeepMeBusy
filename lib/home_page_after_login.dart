import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';

class HomePageAfterLogin extends StatefulWidget {
  const HomePageAfterLogin({super.key});

  @override
  State<HomePageAfterLogin> createState() => _HomePageAfterLoginState();
}

class _HomePageAfterLoginState extends State<HomePageAfterLogin> {
  int _selectedIndex = 0;

  // ===== WARNA AKSEN PER MENU =====
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
          // ===== BACKGROUND =====
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

          // ===== OVERLAY =====
          Container(
            color: Colors.black.withOpacity(0.05),
          ),

          SafeArea(
            child: Column(
              children: [
                // =========================================
                // HEADER
                // =========================================
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.white.withValues(alpha: 0.25),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
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
                  ),
                ),

                // =========================================
                // BODY (PERSISTENT)
                // =========================================
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: const [
                      Center(child: Text('Spare Part Monitoring')),
                      Center(child: Text('Reports')),
                      Center(child: Text('Machinery')),
                      Center(child: Text('Others')),
                    ],
                  ),
                ),

                // =========================================
                // BOTTOM MENU
                // =========================================
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  child: Container(
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
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.white.withValues(alpha: 0.25),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            children: [
                              _ColoredBottomMenuItem(
                                icon: Icons.inventory_2,
                                label: 'Spare Part',
                                color: _menuColors[0],
                                isActive: _selectedIndex == 0,
                                onTap: () =>
                                    setState(() => _selectedIndex = 0),
                              ),
                              _ColoredBottomMenuItem(
                                icon: Icons.bar_chart,
                                label: 'Reports',
                                color: _menuColors[1],
                                isActive: _selectedIndex == 1,
                                onTap: () =>
                                    setState(() => _selectedIndex = 1),
                              ),
                              _ColoredBottomMenuItem(
                                icon: Icons.precision_manufacturing,
                                label: 'Machinery',
                                color: _menuColors[2],
                                isActive: _selectedIndex == 2,
                                onTap: () =>
                                    setState(() => _selectedIndex = 2),
                              ),
                              _ColoredBottomMenuItem(
                                icon: Icons.more_horiz,
                                label: 'Others',
                                color: _menuColors[3],
                                isActive: _selectedIndex == 3,
                                onTap: () =>
                                    setState(() => _selectedIndex = 3),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// BOTTOM MENU ITEM (WARNA + ANIMASI)
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
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: isActive ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  icon,
                  color: activeColor,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.normal,
                  color: activeColor,
                ),
                child: Text(label),
              ),
              const SizedBox(height: 6),

              // ===== INDICATOR =====
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
