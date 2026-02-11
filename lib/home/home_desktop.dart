import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/menu/floating_menu_launcher.dart';
import '../core/menu/menu_registry.dart';
import '../pages/partners/partner_list_page.dart';
import '../pages/common/placeholder_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../attendance/pages/attendance_page.dart';
import '../attendance/services/attendance_period_helper.dart';
import '../pages/settings/settings_page.dart';


enum DesktopSection {
  dashboard,
  inventory,
  machinery,
  reports,
  systems,
}

class HomeDesktop extends StatefulWidget {
  const HomeDesktop({super.key});

  @override
  State<HomeDesktop> createState() => _HomeDesktopState();
}

class _HomeDesktopState extends State<HomeDesktop> {

  DesktopSection selectedSection = DesktopSection.dashboard;

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

  int _crossAxis(double width) {
  if (width > 1700) return 6;
  if (width > 1400) return 5;
  if (width > 1200) return 4;
  return 3;
}
Widget _buildDesktopInventory() {
  return LayoutBuilder(
    builder: (context, constraints) {

      final crossAxisCount = _crossAxis(constraints.maxWidth);

      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const Text(
                'Inventory',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 32),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                childAspectRatio: 1.2,
                children: [

                  _desktopMenuCard(
                    Icons.inventory,
                    'Database',
                    Colors.blueGrey,
                    () {
                      FloatingMenuLauncher.open(
                        context,
                        inventoryMenus.first,
                      );
                    },
                  ),

                  _desktopMenuCard(
                    Icons.input,
                    'Orders In',
                    Colors.green,
                    () {
                      FloatingMenuLauncher.open(
                        context,
                        inventoryMenus.firstWhere(
                          (m) => m.label == 'Orders In',
                        ),
                      );
                    },
                  ),

                  _desktopMenuCard(
                    Icons.output_outlined,
                    'Orders Out',
                    Colors.redAccent,
                    () {
                      FloatingMenuLauncher.open(
                        context,
                        inventoryMenus.firstWhere(
                          (m) => m.label == 'Orders Out',
                        ),
                      );
                    },
                  ),

                  _desktopMenuCard(
                    Icons.groups,
                    'Partners',
                    Colors.deepPurple,
                    () {
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
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildDesktopMachinery() {
  return LayoutBuilder(
    builder: (context, constraints) {

      final crossAxisCount = _crossAxis(constraints.maxWidth);

      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const Text(
                'Machinery',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 32),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                childAspectRatio: 1.2,
                children: [

                  _desktopMenuCard(
                    Icons.list,
                    'Machine List',
                    Colors.pinkAccent,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const PlaceholderPage(title: 'Machine List'),
                        ),
                      );
                    },
                  ),

                  _desktopMenuCard(
                    Icons.menu_book,
                    'Machine Manual',
                    Colors.teal,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const PlaceholderPage(title: 'Machine Manual'),
                        ),
                      );
                    },
                  ),

                  _desktopMenuCard(
                    Icons.auto_stories,
                    'Machine Catalogue',
                    Colors.indigo,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const PlaceholderPage(title: 'Machine Catalogue'),
                        ),
                      );
                    },
                  ),

                  _desktopMenuCard(
                    Icons.verified,
                    'Licenses',
                    Colors.orange,
                    () {
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
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildDesktopReports() {
  return LayoutBuilder(
    builder: (context, constraints) {

      final crossAxisCount = _crossAxis(constraints.maxWidth);

      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const Text(
                'Reports',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 32),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                childAspectRatio: 1.2,
                children: [

                  _desktopMenuCard(
                    Icons.event_available,
                    'Daily Attendance',
                    Colors.blue,
                    () {

                      final user =
                          FirebaseAuth.instance.currentUser!;

                      final employeeId = user.displayName!;

                      final now = DateTime.now();
                      final period =
                          AttendancePeriodHelper.resolvePeriod(now);

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

                  _desktopMenuCard(
                    Icons.build_circle,
                    'Service Report',
                    Colors.green,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const PlaceholderPage(
                                  title: 'Service Report'),
                        ),
                      );
                    },
                  ),

                  _desktopMenuCard(
                    Icons.flight_takeoff,
                    'Buss. Trip Report',
                    Colors.purple,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const PlaceholderPage(
                                  title: 'Buss. Trip Report'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _confirmLogout(BuildContext context) async {
  final bool? result = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.4),
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
  }
}

Widget _buildDesktopSystems() {
  return LayoutBuilder(
    builder: (context, constraints) {

      final crossAxisCount = _crossAxis(constraints.maxWidth);

      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const Text(
                'Systems',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 32),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                childAspectRatio: 1.2,
                children: [

                  _desktopMenuCard(
                    Icons.settings,
                    'Settings',
                    Colors.grey,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsPage(),
                        ),
                      );
                    },
                  ),

                  _desktopMenuCard(
                    Icons.logout,
                    'Logout',
                    Colors.redAccent,
                    () => _confirmLogout(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _desktopMenuCard(
  IconData icon,
  String label,
  Color color,
  VoidCallback onTap,
) {
  return InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 42, color: color),
          const SizedBox(height: 16),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: _buildContent(),
         ),
        ],
      ),
    );
  }

  Widget _buildContent() {
  switch (selectedSection) {
    case DesktopSection.dashboard:
      return _buildDesktopDashboard();

    case DesktopSection.inventory:
      return _buildDesktopInventory();

    case DesktopSection.machinery:
      return _buildDesktopMachinery();

    case DesktopSection.reports:
      return _buildDesktopReports();

    case DesktopSection.systems:
      return _buildDesktopSystems();
  }
}

  Widget _buildSidebar() {

  final user = FirebaseAuth.instance.currentUser;
  final displayName =
      user?.displayName?.isNotEmpty == true
          ? user!.displayName!
          : 'User';
  final email = user?.email ?? '';

  return Container(
    width: 260,
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
    child: Column(
      children: [

        const SizedBox(height: 32),

        // LOGO
        Image.asset(
          'assets/images/Atom.png',
          width: 60,
        ),

        const SizedBox(height: 12),

        // USER INFO
        Text(
          displayName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        Text(
          email,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),

        const SizedBox(height: 32),

        // MENU ITEMS
        _sidebarItem(Icons.dashboard, 'Dashboard', DesktopSection.dashboard),
        _sidebarItem(Icons.inventory, 'Inventory', DesktopSection.inventory),
        _sidebarItem(Icons.precision_manufacturing, 'Machinery', DesktopSection.machinery),
        _sidebarItem(Icons.bar_chart, 'Reports', DesktopSection.reports),
        _sidebarItem(Icons.settings, 'Systems', DesktopSection.systems),
      ],
    ),
  );
}

Widget _sidebarItem(
  IconData icon,
  String title,
  DesktopSection section,
) {

  final isSelected = selectedSection == section;

  return InkWell(
    onTap: () {
      setState(() {
        selectedSection = section;
      });
    },
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      color: isSelected
          ? Colors.white.withValues(alpha: 0.35)
          : null,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.black87,
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight:
                  isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    ),
  );
}


Widget _buildDesktopDashboard() {
  return SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),

          Row(
            children: [

              // Spare Parts Count
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('spare_parts')
                      .snapshots(),
                  builder: (context, snapshot) {

                    final count =
                        snapshot.data?.docs.length ?? 0;

                    return _summaryCard(
                      'Spare Parts',
                      Icons.inventory_2,
                      Colors.blueGrey,
                      snapshot.connectionState ==
                              ConnectionState.waiting
                          ? '-'
                          : count.toString(),
                    );
                  },
                ),
              ),

              const SizedBox(width: 24),

              // Low Stock Count
              Expanded(
                child: StreamBuilder<int>(
                  stream: lowStockCountStream(),
                  builder: (context, snapshot) {

                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return _summaryCard(
                        'Low Stock',
                        Icons.warning,
                        Colors.redAccent,
                        '-',
                      );
                    }

                    final count = snapshot.data ?? 0;

                    return _summaryCard(
                      'Low Stock',
                      Icons.warning,
                      Colors.redAccent,
                      count.toString(),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  Widget _summaryCard(
  String title,
  IconData icon,
  Color color,
  String value,
) {
  return Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 36, color: color),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}
}
