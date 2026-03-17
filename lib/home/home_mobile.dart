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

class HomeMobile extends StatefulWidget {
  const HomeMobile({super.key});

  @override
  State<HomeMobile> createState() => _HomeMobileState();
}

class _HomeMobileState extends State<HomeMobile> {
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
            backgroundColor: AppTheme.errorColor, // 🔴 merah
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

// Di dalam _HomeMobileState
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

// ================= DASHBOARD STATS STREAM =================
Stream<Map<String, dynamic>> dashboardStatsStream() {
  return CompanyFirestore
      .collection('dashboard')
      .doc('stats')
      .snapshots()
      .map((doc) {
        if (!doc.exists) {
          return {
            'totalItems': 0,
            'lowStock': 0,
            'totalValue': 0,
          };
        }

        final data = doc.data() as Map<String, dynamic>;

        return {
          'totalItems': data['totalItems'] ?? 0,
          'lowStock': data['lowStock'] ?? 0,
          'totalValue': data['totalValue'] ?? 0,
        };
      });
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
            decoration: BoxDecoration(
              gradient: AppTheme.backgroundGradient,
            ),
          ),

           // ===== WATERMARK LOGO =====
    Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: Align(
      alignment: const Alignment(0, 0.15),
          child: Opacity(
            opacity: 0.08, // transparansi watermark
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
              padding: const EdgeInsets.only(bottom: 8),
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
      onTap: () async {

  final userProfile = await _getUserProfile();

  if (userProfile == null) {
    print("USER PROFILE NULL");
    return;
  }

  final accessLevel = userProfile['accessLevel'];

  print("ACCESS LEVEL = $accessLevel");

  final now = DateTime.now();
  final period = AttendancePeriodHelper.resolvePeriod(now);

  if (accessLevel == 'admin_countries') {

    print("OPEN ADMIN PAGE");

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AttendanceUserListPage(),
      ),
    );

  } else {

    print("OPEN NORMAL ATTENDANCE");

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
}
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
            builder: (_) =>
                 const TripMobilePage()
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
                    // Setelah Text(email)
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

               // SWITCH COMPANY BUTTON
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
// Tambahkan method ini di dalam class _HomeMobileState
Future<void> _switchCompany(BuildContext context) async {
  try {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    
    final companyIds = List<String>.from(userDoc['companyIds'] ?? []);
    
    if (!mounted) return;
    
    // Navigasi ke SelectCompanyPage
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SelectCompanyPage(
          companyIds: companyIds,
        ),
      ),
    );
  } catch (e) {
    print('Error switching company: $e');
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

  const _CategorySection({
    required this.title,
    required this.crossAxisCount,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
      if (FirebaseAuth.instance.currentUser == null) {
    return const SizedBox.shrink();
  }
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
        padding: const EdgeInsets.only(top: 4),
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

