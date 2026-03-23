import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pages/common/placeholder_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../pages/settings/settings_page.dart';
import '../pages/partners/partner_list_page.dart';
import '../features/auth/select_company_page.dart';
import '../attendance/pages/attendance_page.dart';
import '../attendance/services/attendance_period_helper.dart';
import '../login/login_page.dart'; 
import '../core/session/company_session.dart';
import '../core/services/company_firestore.dart';
import '../service_report/pages/service_report_list_page.dart';
import '../pages/spare_part/spare_part_list_page.dart';
import '../order_in/order_in_mobile.dart';
import '../order_out/order_out_mobile.dart';
import '../attendance/pages/attendance_user_list_page.dart';
import '../modules/trip/pages/trip_mobile_page.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';

// Enum untuk navigation items
enum MobileNavItem {
  home,
  inventory,
  machinery,
  reports,
  settings,
}

class HomeMobile extends StatefulWidget {
  const HomeMobile({super.key});

  @override
  State<HomeMobile> createState() => _HomeMobileState();
}

class _HomeMobileState extends State<HomeMobile> {
  // State untuk selected menu
  MobileNavItem _currentPage = MobileNavItem.home;

  // ================= LOGOUT =================
  Future<void> _confirmLogout(BuildContext context) async {
    final bool? result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (result == true) {
      CompanySession.selectedCompanyId = null;
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  // Stream untuk company name
  Stream<String> _getCurrentCompanyName() {
    final companyId = CompanySession.selectedCompanyId;
    if (companyId == null) return Stream.value('No Company');
    
    return FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>;
            return data['name'] ?? 'ATOM ${companyId.toUpperCase()}';
          }
          return 'ATOM ${companyId.toUpperCase()}';
        });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName =
        user?.displayName?.isNotEmpty == true ? user!.displayName! : 'User';
    final email = user?.email ?? '';

    return Scaffold(
      body: _buildCurrentPage(displayName, email),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Inventory Button
                _buildNavItem(
                  icon: Icons.inventory,
                  label: 'Inventory',
                  isSelected: _currentPage == MobileNavItem.inventory,
                  onTap: () {
                    setState(() {
                      _currentPage = MobileNavItem.inventory;
                    });
                  },
                ),
                
                // Machinery Button
                _buildNavItem(
                  icon: Icons.precision_manufacturing,
                  label: 'Machinery',
                  isSelected: _currentPage == MobileNavItem.machinery,
                  onTap: () {
                    setState(() {
                      _currentPage = MobileNavItem.machinery;
                    });
                  },
                ),
                
                // Home Button (Center - Larger)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _currentPage = MobileNavItem.home;
                        });
                      },
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF667EEA).withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.home,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Reports Button
                _buildNavItem(
                  icon: Icons.bar_chart,
                  label: 'Reports',
                  isSelected: _currentPage == MobileNavItem.reports,
                  onTap: () {
                    setState(() {
                      _currentPage = MobileNavItem.reports;
                    });
                  },
                ),
                
                // Settings Button
                _buildNavItem(
                  icon: Icons.settings,
                  label: 'Settings',
                  isSelected: _currentPage == MobileNavItem.settings,
                  onTap: () {
                    setState(() {
                      _currentPage = MobileNavItem.settings;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Method untuk menampilkan halaman berdasarkan selected menu
  Widget _buildCurrentPage(String displayName, String email) {
    switch (_currentPage) {
      case MobileNavItem.home:
        return _buildHomePage(displayName, email);
      case MobileNavItem.inventory:
        return _buildInventoryPage();
      case MobileNavItem.machinery:
        return _buildMachineryPage();
      case MobileNavItem.reports:
        return _buildReportsPage();
      case MobileNavItem.settings:
        return _buildSettingsPage();
    }
  }

 

  // ================= HOME PAGE =================
  Widget _buildHomePage(String displayName, String email) {
    return Stack(
      children: [
        // Background
        Container(
          decoration: BoxDecoration(
            gradient: AppTheme.backgroundGradient,
          ),
        ),

        // Watermark Logo
        Positioned.fill(
          child: IgnorePointer(
            child: Center(
              child: Align(
                alignment: const Alignment(0, 0.15),
                child: Opacity(
                  opacity: 0.08,
                  child: Image.asset(
                    'assets/images/Atom.png',
                    width: 320,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        ),

        SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
  bottom: MediaQuery.of(context).padding.bottom + 120,
),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildHeader(displayName, email),
                ),

                // Dashboard Summary
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildDashboardCards(),
                ),

                const SizedBox(height: 24),

                // Inventory Section
                _CategorySection(
                  title: 'Inventory',
                  crossAxisCount: 4,
                  children: [
                    _MenuCard(
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
                    _MenuCard(
                      icon: Icons.input,
                      label: 'Orders In',
                      color: Colors.green,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const OrderInMobile(),
                          ),
                        );
                      },
                    ),
                    _MenuCard(
                      icon: Icons.output_outlined,
                      label: 'Orders Out',
                      color: Colors.redAccent,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const OrderOutMobile(),
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

                // Machinery Section
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
                            builder: (_) => const PlaceholderPage(title: 'Machine List'),
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
                            builder: (_) => const PlaceholderPage(title: 'Machine Manual'),
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
                            builder: (_) => const PlaceholderPage(title: 'Machine Catalogue'),
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
                            builder: (_) => const PlaceholderPage(title: 'Licenses'),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                // Reports Section
                _CategorySection(
                  title: 'Reports',
                  crossAxisCount: 3,
                  children: [
                    _MenuCard(
                      icon: Icons.event_available,
                      label: 'Daily Attendance',
                      color: Colors.blue,
                      onTap: () async {
                        final userProfile = await _getUserProfile();
                        if (userProfile == null) return;
                        final accessLevel = userProfile['accessLevel'];
                        final now = DateTime.now();
                        final period = AttendancePeriodHelper.resolvePeriod(now);

                        if (accessLevel == 'admin_countries') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AttendanceUserListPage(),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AttendancePage(
                                employeeId: FirebaseAuth.instance.currentUser!.uid,
                                period: period,
                              ),
                            ),
                          );
                        }
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
                            builder: (_) => const ServiceReportListPage(),
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
                            builder: (_) => const TripMobilePage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                // Systems Section
                _CategorySection(
                  title: 'Systems',
                  crossAxisCount: 3,
                  spacingTop: 0,     // 🔥 kecilin jarak dari atas
  spacingBottom: 20,
                  children: [
                   _MenuCard(
  icon: Icons.cloud,
  label: 'ATOM Cloud',
  color: Colors.blueAccent,
 onTap: () async {
  final url = Uri.parse('https://cloud.atom.it/');

  // loading
  showGeneralDialog(
  context: context,
  barrierDismissible: false,
  barrierColor: Colors.black.withOpacity(0.3),
  transitionDuration: const Duration(milliseconds: 300),
  pageBuilder: (_, __, ___) {
    return Center(
  child: Column(
    mainAxisSize: MainAxisSize.min, // 🔥 penting biar center bener
    children: [
      Image.asset(
        'assets/images/Atom.png',
        width: 70, // kecilin dikit
      ),
      const SizedBox(height: 16),
      const CircularProgressIndicator(),
      const SizedBox(height: 12),
      const Text(
        'Opening ATOM Cloud...',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14, // 🔥 kecilin biar proporsional
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  ),
);
  },
  transitionBuilder: (_, animation, __, child) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  },
);

await Future.delayed(const Duration(milliseconds: 200));

  try {
    await launchUrl(
      url,
      customTabsOptions: const CustomTabsOptions(
        showTitle: true,
        shareState: CustomTabsShareState.off,
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to open ATOM Cloud')),
    );
  } finally {
    Navigator.pop(context);
  }
},
),
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
    );
  }

  // ================= INVENTORY PAGE =================
  Widget _buildInventoryPage() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: AppTheme.backgroundGradient,
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: Center(
              child: Align(
                alignment: const Alignment(0, 0.15),
                child: Opacity(
                  opacity: 0.08,
                  child: Image.asset(
                    'assets/images/Atom.png',
                    width: 320,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 80),
            child: Column(
              children: [
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Inventory Management',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Manage your spare parts and orders',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _CategorySection(
                  title: 'Inventory Menu',
                  crossAxisCount: 2,
                  children: [
                    _MenuCard(
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
                    _MenuCard(
                      icon: Icons.input,
                      label: 'Orders In',
                      color: Colors.green,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const OrderInMobile(),
                          ),
                        );
                      },
                    ),
                    _MenuCard(
                      icon: Icons.output_outlined,
                      label: 'Orders Out',
                      color: Colors.redAccent,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const OrderOutMobile(),
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
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ================= MACHINERY PAGE =================
  Widget _buildMachineryPage() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: AppTheme.backgroundGradient,
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: Center(
              child: Align(
                alignment: const Alignment(0, 0.15),
                child: Opacity(
                  opacity: 0.08,
                  child: Image.asset(
                    'assets/images/Atom.png',
                    width: 320,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 80),
            child: Column(
              children: [
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Machinery Management',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Manage machines, manuals, and licenses',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _CategorySection(
                  title: 'Machinery Menu',
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
                            builder: (_) => const PlaceholderPage(title: 'Machine List'),
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
                            builder: (_) => const PlaceholderPage(title: 'Machine Manual'),
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
                            builder: (_) => const PlaceholderPage(title: 'Machine Catalogue'),
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
                            builder: (_) => const PlaceholderPage(title: 'Licenses'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ================= REPORTS PAGE =================
  Widget _buildReportsPage() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: AppTheme.backgroundGradient,
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: Center(
              child: Align(
                alignment: const Alignment(0, 0.15),
                child: Opacity(
                  opacity: 0.08,
                  child: Image.asset(
                    'assets/images/Atom.png',
                    width: 320,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 80),
            child: Column(
              children: [
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Reports & Analytics',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Generate and view business reports',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _CategorySection(
                  title: 'Reports Menu',
                  crossAxisCount: 2,
                  children: [
                    _MenuCard(
                      icon: Icons.event_available,
                      label: 'Daily Attendance',
                      color: Colors.blue,
                      onTap: () async {
                        final userProfile = await _getUserProfile();
                        if (userProfile == null) return;
                        final accessLevel = userProfile['accessLevel'];
                        final now = DateTime.now();
                        final period = AttendancePeriodHelper.resolvePeriod(now);

                        if (accessLevel == 'admin_countries') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AttendanceUserListPage(),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AttendancePage(
                                employeeId: FirebaseAuth.instance.currentUser!.uid,
                                period: period,
                              ),
                            ),
                          );
                        }
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
                            builder: (_) => const ServiceReportListPage(),
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
                            builder: (_) => const TripMobilePage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

// ================= SETTINGS PAGE =================
Widget _buildSettingsPage() {
  return Stack(
    children: [
      Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
      ),
      Positioned.fill(
        child: IgnorePointer(
          child: Center(
            child: Align(
              alignment: const Alignment(0, 0.15),
              child: Opacity(
                opacity: 0.08,
                child: Image.asset(
                  'assets/images/Atom.png',
                  width: 320,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
      // Hapus SafeArea, gunakan Padding langsung
      Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top,
          bottom: 100, // Padding bottom besar untuk bottom nav
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Configure system preferences',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _CategorySection(
                title: 'System Menu',
                crossAxisCount: 3,
                children: [
                  _MenuCard(
                    icon: Icons.settings,
                    label: 'Settings',
                    color: Colors.grey,
                    iconSize: 42,
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
                    iconSize: 42,
                    onTap: () => _confirmLogout(context),
                  ),
                ],
              ),
              // SizedBox dengan tinggi yang cukup besar
              const SizedBox(height: 150),
            ],
          ),
        ),
      ),
    ],
  );
}

  // Widget untuk Navigation Item
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected 
                      ? const Color(0xFF667EEA) 
                      : Colors.grey.shade600,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected 
                        ? const Color(0xFF667EEA) 
                        : Colors.grey.shade600,
                  ),
                ),
                if (isSelected)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    width: 20,
                    height: 2,
                    decoration: BoxDecoration(
                      color: const Color(0xFF667EEA),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= HEADER =================
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
                    const SizedBox(height: 2),
                    StreamBuilder<String>(
                      stream: _getCurrentCompanyName(),
                      builder: (context, snapshot) {
                        return Text(
                          snapshot.data ?? 'Loading...',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: Icon(
                    Icons.business,
                    color: const Color.fromARGB(255, 10, 140, 8),
                    size: 27,
                  ),
                  onPressed: () => _switchCompany(context),
                  tooltip: 'Switch Company',
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: AppTheme.errorColor),
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
    final now = DateTime.now();
    final period = AttendancePeriodHelper.resolvePeriod(now);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _DashboardCard(
                title: 'Today Activity',
                subtitle: period,
                icon: Icons.event_available,
                color: Colors.blue,
                onTap: () {
                  final user = FirebaseAuth.instance.currentUser!;
                  final employeeId = user.displayName ?? user.uid;

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
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DashboardCard(
                title: 'Service Report',
                subtitle: 'Create or View',
                icon: Icons.build_circle,
                color: Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ServiceReportListPage(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Method switch company
  Future<void> _switchCompany(BuildContext context) async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      
      final companyIds = List<String>.from(userDoc['companyIds'] ?? []);
      
      if (!mounted) return;
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SelectCompanyPage(
            companyIds: companyIds,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal switch company: $e')),
      );
    }
  }

  Future<Map<String, dynamic>?> _getUserProfile() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    return doc.data();
  }
}

// ================= CATEGORY SECTION =================
class _CategorySection extends StatelessWidget {
  final String title;
  final int crossAxisCount;
  final List<Widget> children;

  // ✅ TAMBAHAN
  final EdgeInsetsGeometry? margin;
  final double spacingTop;
  final double spacingBottom;

  const _CategorySection({
    required this.title,
    required this.crossAxisCount,
    required this.children,
    this.margin,
    this.spacingTop = 16,
    this.spacingBottom = 8,
  });

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: margin ?? EdgeInsets.fromLTRB(16, spacingTop, 16, spacingBottom),
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
            mainAxisSpacing: 10,
crossAxisSpacing: 10,
childAspectRatio: 1.27,
            children: children,
          ),
        ],
      ),
    );
  }
}

// ================= MENU CARD =================
class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
   final double? iconSize;

  const _MenuCard({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final bool isTablet = MediaQuery.of(context).size.width >= 700;
    final double sizeIcon = iconSize ?? (isTablet ? 36 : 30);

    return Center(
  child: Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 70,
        height: 70,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: sizeIcon,
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
    ),
  ),
);
  }
}

// ================= DASHBOARD CARD =================
class _DashboardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _DashboardCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}