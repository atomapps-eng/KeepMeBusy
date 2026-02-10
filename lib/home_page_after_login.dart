import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login_page.dart';

import 'pages/common/placeholder_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'pages/settings/settings_page.dart';
import 'core/menu/floating_menu_launcher.dart';
import 'core/menu/menu_registry.dart';
import 'pages/partners/partner_list_page.dart';
import 'pages/spare_part/low_stock_page.dart';

import '../attendance/pages/attendance_page.dart';
import '../attendance/services/attendance_period_helper.dart';
import 'core/menu/desktop_shell.dart';



class HomePageAfterLogin extends StatefulWidget {
  const HomePageAfterLogin({super.key});

  @override
  State<HomePageAfterLogin> createState() => _HomePageAfterLoginState();
}

class _HomePageAfterLoginState extends State<HomePageAfterLogin> {
  int _selectedIndex = 0;
  // ================= LOW STOCK STREAM =================
  Stream<int> lowStockCountStream() {
    return FirebaseFirestore.instance
        .collection('spare_parts')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.where((doc) {
            final data = doc.data();
            final int currentStock = data['currentStock'] ?? 0;
            final int minimumStock = data['minimumStock'] ?? 0;
            return currentStock < minimumStock;
          }).length;
        });
  }
  // ================= LOGOUT =================
  Future<void> _confirmLogout(BuildContext context) async {
    final bool? result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha:0.4),
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
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

  Widget _buildDesktopContent(String displayName, String email) {
  if (_selectedIndex == 0) {
    return _buildDashboardSection(displayName, email);
  }
  if (_selectedIndex == 1) {
    return _buildInventorySection();
  }
  if (_selectedIndex == 2) {
    return _buildMachinerySection();
  }
  if (_selectedIndex == 3) {
    return _buildReportsSection();
  }
  return _buildSettingsSection();
}


@override
Widget build(BuildContext context) {
  return LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth >= 1000) {
        return _buildDesktopHome(context);
      } else {
        return _buildMobileHome(context);
      }
    },
  );
}

Widget _buildMobileHome(BuildContext context) {
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
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildHeader(displayName, email),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildDashboardCards(),
                ),
                const SizedBox(height: 24),

                _CategorySection(
  title: 'Inventory',
  crossAxisCount: 4, // ✅ DIUBAH: JUMLAH MENU
  children: [
   _MenuCard(
  icon: resolveDesktopIcon(
    context: context,
    mobile: Icons.inventory,
    desktop: Icons.inventory_2_rounded,
  ),
  label: 'Database',
  color: Colors.blueGrey,
  onTap: () {
    FloatingMenuLauncher.open(
      context,
      inventoryMenus.first,
    );
  },
),

    _MenuCard(
      icon: Icons.input,
      label: 'Orders In',
      color: Colors.green,
      onTap: () {
  FloatingMenuLauncher.open(
    context,
    inventoryMenus.firstWhere(
      (menu) => menu.label == 'Orders In',
    ),
  );
},
),
    _MenuCard(
      icon: Icons.output_outlined,
      label: 'Orders Out',
      color: Colors.redAccent,
      onTap: () {
  FloatingMenuLauncher.open(
    context,
    inventoryMenus.firstWhere(
      (menu) => menu.label == 'Orders Out',
    ),
  );
},

),
    _MenuCard(
      icon: Icons.groups,
      label: 'Partners',
      color: Colors.deepPurple,
      onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const PartnerListPage(),
    ),
  );
},

),
  ],
),


                  // ===== MACHINERY =====
                  _CategorySection(
  title: 'Machinery',
  crossAxisCount: 4,
  children: [
    _MenuCard(
      icon: Icons.list,
      label: 'Machine List',
      color: Colors.pinkAccent,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const PlaceholderPage(title: 'Machine List'),
          ),
        );
      },
    ),
    _MenuCard(
      icon: Icons.menu_book,
      label: 'Machine Manual',
      color: Colors.teal,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const PlaceholderPage(title: 'Machine Manual'),
          ),
        );
      },
    ),
    _MenuCard(
      icon: Icons.auto_stories,
      label: 'Machine Catalogue',
      color: Colors.indigo,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const PlaceholderPage(title: 'Machine Catalogue'),
          ),
        );
      },
    ),
    _MenuCard(
      icon: Icons.verified,
      label: 'Licenses',
      color: Colors.orange,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const PlaceholderPage(title: 'Licenses'),
          ),
        );
      },
    ),
  ],
),

                  // ===== REPORTS =====
                  _CategorySection(
  title: 'Reports',
  crossAxisCount: 3,
  children: [
    _MenuCard(
      icon: Icons.event_available,
      label: 'Daily Attendance',
      color: Colors.blue,
      onTap: () {
  final user = FirebaseAuth.instance.currentUser!;
  final employeeId = user.displayName!; // ⬅️ INI FIX-NYA

  final now = DateTime.now();
  final period = AttendancePeriodHelper.resolvePeriod(now);

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => AttendancePage(
        employeeId: employeeId,
        period: period,
      ),
    ),
  );
},
),

    _MenuCard(
      icon: Icons.build_circle,
      label: 'Service Report',
      color: Colors.green,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const PlaceholderPage(title: 'Service Report'),
          ),
        );
      },
    ),
    _MenuCard(
      icon: Icons.flight_takeoff,
      label: 'Buss. Trip Report',
      color: Colors.purple,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const PlaceholderPage(title: 'Buss. Trip Report'),
          ),
        );
      },
    ),
  ],
),

                  // ===== SYSTEMS =====
                  _CategorySection(
                    title: 'Systems',
                    crossAxisCount: 2, // ✅ DIUBAH: JUMLAH MENU
                    children: [
                      _MenuCard(
  icon: Icons.settings,
  label: 'Settings',
  color: Colors.grey,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SettingsPage(),
      ),
    );
  },
),

                      _MenuCard(
                        icon: Icons.logout,
                        label: 'Logout',
                        color: Colors.redAccent,
                        onTap: () => _confirmLogout(context),
                      ),
                    ],
                  ),// ⬇️ SALIN SEMUA _CategorySection LU KE SINI
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildDesktopHome(BuildContext context) {
  final user = FirebaseAuth.instance.currentUser;
  final displayName =
      user?.displayName?.isNotEmpty == true ? user!.displayName! : 'User';
  final email = user?.email ?? '';

  return DesktopShell(
    selectedIndex: _selectedIndex,
    onMenuSelected: (index) {
      setState(() => _selectedIndex = index);
    },
    sidebarHeader: Column(
      children: [
        Image.asset('assets/images/Atom.png', height: 48),
        const SizedBox(height: 12),
        Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(
          email,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11),
        ),
      ],
    ),
    content: Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFE0B2), Color(0xFFFFFFFF)],
            ),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: _buildDesktopContent(displayName, email),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}


Widget _buildDashboardSection(String displayName, String email) {
  return Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(24),
        child: _buildHeader(displayName, email),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: _buildDashboardCards(),
      ),
    ],
  );
}

Widget _buildInventorySection() {
  return Column(
    children: [
      _CategorySection(
        title: 'Inventory',
        crossAxisCount: MediaQuery.of(context).size.width >= 1000 ? 2 : 4,
        children: [
           _MenuCard(
  icon: resolveDesktopIcon(
    context: context,
    mobile: Icons.inventory,
    desktop: Icons.inventory_2_rounded,
  ),
  label: 'Database',
  color: Colors.blueGrey,
  onTap: () {
    FloatingMenuLauncher.open(
      context,
      inventoryMenus.first,
    );
  },
),

    _MenuCard(
      icon: Icons.input,
      label: 'Orders In',
      color: Colors.green,
      onTap: () {
  FloatingMenuLauncher.open(
    context,
    inventoryMenus.firstWhere(
      (menu) => menu.label == 'Orders In',
    ),
  );
},
),
    _MenuCard(
      icon: Icons.output_outlined,
      label: 'Orders Out',
      color: Colors.redAccent,
      onTap: () {
  FloatingMenuLauncher.open(
    context,
    inventoryMenus.firstWhere(
      (menu) => menu.label == 'Orders Out',
    ),
  );
},

),
    _MenuCard(
      icon: Icons.groups,
      label: 'Partners',
      color: Colors.deepPurple,
      onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const PartnerListPage(),
    ),
  );
},

),// ⬅️ SALIN MENU INVENTORY LU KE SINI
        ],
      ),
    ],
  );
}

Widget _buildMachinerySection() {
  return Column(
    children: [
      _CategorySection(
        title: 'Machinery',
        crossAxisCount: 2,
        children: [
         _MenuCard(
      icon: Icons.list,
      label: 'Machine List',
      color: Colors.pinkAccent,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const PlaceholderPage(title: 'Machine List'),
          ),
        );
      },
    ),
    _MenuCard(
      icon: Icons.menu_book,
      label: 'Machine Manual',
      color: Colors.teal,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const PlaceholderPage(title: 'Machine Manual'),
          ),
        );
      },
    ),
    _MenuCard(
      icon: Icons.auto_stories,
      label: 'Machine Catalogue',
      color: Colors.indigo,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const PlaceholderPage(title: 'Machine Catalogue'),
          ),
        );
      },
    ),
    _MenuCard(
      icon: Icons.verified,
      label: 'Licenses',
      color: Colors.orange,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const PlaceholderPage(title: 'Licenses'),
          ),
        );
      },
    ), // ⬅️ SALIN MENU MACHINERY LU KE SINI
        ],
      ),
    ],
  );
}

Widget _buildReportsSection() {
  return Column(
    children: [
      _CategorySection(
  title: 'Reports',
  crossAxisCount: 2,
  childAspectRatio: 1.2, // ← LEBIH TINGGI
        children: [
           _MenuCard(
      icon: Icons.event_available,
      label: 'Daily Attendance',
      color: Colors.blue,
      onTap: () {
  final user = FirebaseAuth.instance.currentUser!;
  final employeeId = user.displayName!; // ⬅️ INI FIX-NYA

  final now = DateTime.now();
  final period = AttendancePeriodHelper.resolvePeriod(now);

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => AttendancePage(
        employeeId: employeeId,
        period: period,
      ),
    ),
  );
},
),

    _MenuCard(
      icon: Icons.build_circle,
      label: 'Service Report',
      color: Colors.green,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const PlaceholderPage(title: 'Service Report'),
          ),
        );
      },
    ),
    _MenuCard(
      icon: Icons.flight_takeoff,
      label: 'Buss. Trip Report',
      color: Colors.purple,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const PlaceholderPage(title: 'Buss. Trip Report'),
          ),
        );
      },
    ),// ⬅️ SALIN MENU REPORTS LU KE SINI
        ],
      ),
    ],
  );
}

Widget _buildSettingsSection() {
  return Column(
    children: [
      _CategorySection(
  title: 'Systems',
  crossAxisCount: 2,
  childAspectRatio: 1.4, // ← PALING TINGGI
        children: [
          _MenuCard(
  icon: Icons.settings,
  label: 'Settings',
  color: Colors.grey,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SettingsPage(),
      ),
    );
  },
),

                      _MenuCard(
                        icon: Icons.logout,
                        label: 'Logout',
                        color: Colors.redAccent,
                        onTap: () => _confirmLogout(context),
                      ),// ⬅️ SALIN MENU SETTINGS LU KE SINI
        ],
      ),
    ],
  );
}


Widget _buildHeader(String displayName, String email) {
  final r = ResponsiveScale(context);

  return ClipRRect(
    borderRadius: BorderRadius.circular(r.radius(20)),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: r.spacing(16),
          vertical: r.spacing(14),
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(r.radius(20)),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: r.icon(22),
              backgroundColor: Colors.transparent,
              child: Image.asset(
                'assets/images/Atom.png',
                width: r.icon(28),
              ),
            ),
            SizedBox(width: r.spacing(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: r.font(16),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: r.spacing(2)),
                  Text(
                    email,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: r.font(12),
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.logout, size: r.icon(22)),
              onPressed: () => _confirmLogout(context),
            ),
          ],
        ),
      ),
    ),
  );
}


  // ================= DASHBOARD SUMMARY =================
Widget _buildDashboardCards() {
  return Row(
    children: [
      Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('spare_parts')
              .snapshots(),
          builder: (context, snapshot) {
            final count = snapshot.data?.docs.length ?? 0;

            return _DashboardCard(
              title: 'Spare Parts',
              value: snapshot.connectionState == ConnectionState.waiting
                  ? '-'
                  : count.toString(),
              icon: Icons.inventory_2,
              color: Colors.blueGrey,
            );
          },
        ),
      ),
      const SizedBox(width: 12), // ✅ JAGA JARAK
      Expanded(
  child: StreamBuilder<int>(
    stream: lowStockCountStream(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const _DashboardCard(
          title: 'Low Stock',
          value: '-',
          icon: Icons.warning,
          color: Colors.redAccent,
        );
      }

      if (snapshot.hasError) {
        return const _DashboardCard(
          title: 'Low Stock',
          value: '!',
          icon: Icons.warning,
          color: Colors.redAccent,
        );
      }

      final count = snapshot.data ?? 0;

      return _DashboardCard(
        title: 'Low Stock',
        value: count.toString(),
        icon: Icons.warning,
        color: Colors.redAccent,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const LowStockPage(),
            ),
          );
        },
      );
    },
  ),
),
    ],
  );
}
}

IconData resolveDesktopIcon({
  required BuildContext context,
  required IconData mobile,
  required IconData desktop,
}) {
  final width = MediaQuery.of(context).size.width;
  return width >= 1000 ? desktop : mobile;
}

// ================= CATEGORY SECTION =================
class _CategorySection extends StatelessWidget {
  final String title;
  final int crossAxisCount;
  final double childAspectRatio; // ← TAMBAH
  final List<Widget> children;

  const _CategorySection({
    required this.title,
    required this.crossAxisCount,
    required this.children,
    this.childAspectRatio = 1.0, // ← DEFAULT
  });
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
         LayoutBuilder(
  builder: (context, constraints) {
    final isDesktop = constraints.maxWidth >= 1000;

    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: isDesktop
            ? constraints.maxWidth * 0.75
            : constraints.maxWidth,
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 32,
          crossAxisSpacing: isDesktop ? 48 : 16,
          childAspectRatio: childAspectRatio,
          children: children,
        ),
      ),
    );
  },
),


        ],
      ),
    );
  }
}

// ================= MENU CARD (FULLY RESPONSIVE) =================
class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _MenuCard({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveScale(context);

    return DesktopHoverWrapper(
      child: InkWell(
        borderRadius: BorderRadius.circular(r.radius(16)),
        onTap: onTap,
        hoverColor: color.withValues(alpha: 0.12),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: r.spacing(24),
            horizontal: r.spacing(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: r.icon(56), // ← DINAMIS WINDOW
                color: color,
              ),
              SizedBox(height: r.spacing(16)),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: r.font(14), // ← DINAMIS WINDOW
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================= DASHBOARD CARD (RESPONSIVE) =================
class _DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _DashboardCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveScale(context);

    return InkWell(
      borderRadius: BorderRadius.circular(r.radius(16)),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(r.spacing(16)),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(r.radius(16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: r.icon(32),
              color: color,
            ),
            SizedBox(height: r.spacing(8)),
            Text(
              title,
              style: TextStyle(fontSize: r.font(13)),
            ),
            SizedBox(height: r.spacing(4)),
            Text(
              value,
              style: TextStyle(
                fontSize: r.font(22),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class DesktopHoverWrapper extends StatefulWidget {
  final Widget child;
  const DesktopHoverWrapper({super.key, required this.child});

  @override
  State<DesktopHoverWrapper> createState() => _DesktopHoverWrapperState();
}

class _DesktopHoverWrapperState extends State<DesktopHoverWrapper> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1000;

    if (!isDesktop) return widget.child;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.04 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
  boxShadow: const [],
),
          child: widget.child,
        ),
      ),
    );
  }
}
// ================= RESPONSIVE SCALE (WINDOW AWARE) =================
class ResponsiveScale {
  final double width;
  final double height;

  ResponsiveScale(BuildContext context)
      : width = MediaQuery.of(context).size.width,
        height = MediaQuery.of(context).size.height;

  /// Base desain desktop (aman & stabil)
  static const double baseWidth = 1200;

  /// Scale factor (di-clamp supaya tidak ekstrim)
  double get scale => (width / baseWidth).clamp(0.75, 1.4);

  double icon(double size) => size * scale;
  double font(double size) => size * scale;
  double spacing(double size) => size * scale;
  double radius(double size) => size * scale;
}
