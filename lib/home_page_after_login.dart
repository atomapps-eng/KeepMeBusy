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






class HomePageAfterLogin extends StatefulWidget {
  const HomePageAfterLogin({super.key});

  @override
  State<HomePageAfterLogin> createState() => _HomePageAfterLoginState();
}

class _HomePageAfterLoginState extends State<HomePageAfterLogin> {
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
            return currentStock <= minimumStock;
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

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                children: [
                  // ===== HEADER (ASLI ANDA - TIDAK DIUBAH) =====
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildHeader(displayName, email),
                  ),

                  // ===== DASHBOARD SUMMARY (TETAP) =====
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
  icon: Icons.inventory,
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const PlaceholderPage(title: 'Daily Attendance'),
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
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= HEADER (ASLI ANDA) =================
  Widget _buildHeader(String displayName, String email) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha:0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha:0.4)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.transparent,
                child: Image.asset('assets/images/Atom.png', width: 28),
              ),
              const SizedBox(width: 12),
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
                    const SizedBox(height: 2),
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

// ================= CATEGORY SECTION =================
class _CategorySection extends StatelessWidget {
  final String title;
  final int crossAxisCount;
  final List<Widget> children;

  const _CategorySection({
    required this.title,
    required this.crossAxisCount,
    required this.children,
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
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.0, // PADAT & KECIL (SESUAI CONTOH)
            children: children,
          ),
        ],
      ),
    );
  }
}

// ================= MENU CARD (RESPONSIVE ICON) =================
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
    final bool isTablet = MediaQuery.of(context).size.width >= 700;

    return InkResponse(
      onTap: onTap,
      radius: 40,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: isTablet ? 36 : 30,
              color: color,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}




// ================= DASHBOARD CARD =================
class _DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap; // ✅ TAMBAH

  const _DashboardCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap, // ✅ TAMBAH
  });

  @override
  Widget build(BuildContext context) {
    return InkWell( // ✅ BUNGKUS
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha:0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(title),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

