import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../pages/partners/partner_list_page.dart';
import '../pages/common/placeholder_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../attendance/pages/attendance_page.dart';
import '../attendance/services/attendance_period_helper.dart';
import '../pages/settings/settings_page.dart';
import '../pages/spare_part/low_stock_page.dart';
import '../pages/spare_part/spare_part_list_page.dart';
import '../order_in/order_in_desktop.dart';
import '../order_out/order_out_desktop.dart';
import '../core/widgets/draggable_window.dart';
import '../login/login_page.dart'; 
import '../core/session/company_session.dart';
import '../core/services/company_firestore.dart';
import '../features/auth/select_company_page.dart';
import '../services/logout_helper.dart';
import '../theme/app_theme.dart';

enum DesktopSection {
  dashboard,
  inventory,
  machinery,
  reports,
  systems,
}

enum InventoryView {
  menu,
  orderIn,
  orderOut,
}

class HomeDesktop extends StatefulWidget {
  const HomeDesktop({super.key});

  @override
  State<HomeDesktop> createState() => _HomeDesktopState();
}

class _HomeDesktopState extends State<HomeDesktop> {

  DesktopSection selectedSection = DesktopSection.dashboard;
  bool showLowStockOnly = false;

  InventoryView inventoryView = InventoryView.menu;

  Stream<int> lowStockCountStream() {
    return CompanyFirestore
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
                      showGeneralDialog(
  context: context,
  barrierDismissible: true,
  barrierLabel: "Database",
  barrierColor: Colors.black.withValues(alpha: 0.35),
  transitionDuration: const Duration(milliseconds: 200),
  pageBuilder: (_, _, _) {
    return const DraggableResizableWindow(
      title: "Database",
      headerColor: Colors.blueGrey,
      child: SparePartListPage(),
    );
  },
);
setState(() {
  showLowStockOnly = true;
});

                    },
                  ),

 _desktopMenuCard(
  Icons.input,
  'Orders In',
  Colors.green,
  () {
    setState(() {
      inventoryView = InventoryView.orderIn;
    });
  },
),

_desktopMenuCard(
  Icons.output_outlined,
  'Orders Out',
  Colors.redAccent,
  () {
    setState(() {
      inventoryView = InventoryView.orderOut;
    });
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

Widget _buildInventoryContent() {
  switch (inventoryView) {
    case InventoryView.menu:
      return _buildDesktopInventory();

    case InventoryView.orderIn:
      return const OrderInDesktop();

    case InventoryView.orderOut:
  return const OrderOutDesktop();
  }
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
        // Contoh di HomePage
ElevatedButton(
  onPressed: () => LogoutHelper.logout(context),
  child: Text('Logout'),
)
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
  if (result == true) {
  print("LOGOUT PRESSED");
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
      
      child: Container(
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: color.withValues(alpha: 0.12),
    borderRadius: BorderRadius.circular(16),
  ),
  child: Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 42, color: color),
        const SizedBox(height: 16),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  ),
),

    ),
  );
}
  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) {
    return const SizedBox.shrink();
  }

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
  return _buildInventoryContent();


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
  final displayName = user?.displayName?.isNotEmpty == true
      ? user!.displayName!
      : 'User';
  final email = user?.email ?? '';
  final companyId = CompanySession.selectedCompanyId;

  return Container(
    width: 280, // Lebar sedikit ditambah
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFFFE0B2),
          Colors.white,
        ],
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(2, 0),
        ),
      ],
    ),
    child: Column(
      children: [
        // Logo Aplikasi
        Container(
          padding: const EdgeInsets.only(top: 28, bottom: 16),
          child: Image.asset(
            'assets/images/Atom.png',
            width: 70,
            fit: BoxFit.contain,
          ),
        ),

        // COMPANY INFO CARD - EYE CATCHING
        if (companyId != null)
          FutureBuilder<Map<String, dynamic>>(
            future: _getSelectedCompanyInfo(),
            builder: (context, snapshot) {
              final companyColor = snapshot.data?['color'] ?? 
                  _getColorForCompany(companyId);
             String companyName;

if (snapshot.data != null && snapshot.data!['displayName'] != null) {
  // Gunakan displayName dari Firestore jika ada
  companyName = snapshot.data!['displayName'];
} else {
  // FORMAT ULANG LANGSUNG DI SINI
  final rawName = companyId.toUpperCase();
  
  // Logika khusus untuk menambahkan spasi
  if (rawName.contains('ATOM')) {
    // Pisahkan "ATOM" dari sisanya
    if (rawName == 'ATOM') {
      companyName = 'ATOM';
    } else {
      // Cari posisi "ATOM" dan ambil sisanya
      final withoutAtom = rawName.replaceAll('ATOM', '').trim();
      companyName = 'ATOM $withoutAtom';
    }
  } else {
    companyName = 'ATOM $rawName';
  }
  
  // Bersihkan dari spasi berlebih
  companyName = companyName.replaceAll(RegExp(r'\s+'), ' ').trim();
}


              final flag = snapshot.data?['flag'] ?? 
                  _getFlagForCompany(companyId);

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      companyColor.withOpacity(0.15),
                      companyColor.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: companyColor.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: companyColor.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Flag/Logo besar
                    // Flag/Logo besar - Gunakan flag dari snapshot atau emoji
Container(
  width: 48,
  height: 48,
  decoration: BoxDecoration(
    color: companyColor.withOpacity(0.15),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: companyColor.withOpacity(0.3),
      width: 1,
    ),
  ),
  child: Center(
    child: Text(
      snapshot.data?['flag'] ?? _getFlagEmoji(companyId),
      style: const TextStyle(fontSize: 28),
    ),
  ),
),
                    const SizedBox(width: 12),
                    
                    // Company details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Active Company',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.black54.withOpacity(0.8),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            companyName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Active',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

        // User Info
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                child: Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                email,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black54,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        // Action Buttons (Switch Company & Logout)
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      final uid = FirebaseAuth.instance.currentUser!.uid;
                      final userDoc = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .get();
                      final companyIds =
                          List<String>.from(userDoc['companyIds'] ?? []);

                      if (!mounted) return;

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SelectCompanyPage(
                            companyIds: companyIds,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.business,
                            size: 16,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Switch',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _confirmLogout(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.logout,
                            size: 16,
                            color: Colors.red.shade400,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Logout',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.red.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const Divider(
          thickness: 1,
          height: 24,
        ),

        // Menu Items
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              _sidebarItem(
                Icons.dashboard_outlined,
                Icons.dashboard,
                'Dashboard',
                DesktopSection.dashboard,
              ),
              _sidebarItem(
                Icons.inventory_outlined,
                Icons.inventory,
                'Inventory',
                DesktopSection.inventory,
              ),
              _sidebarItem(
                Icons.precision_manufacturing_outlined,
                Icons.precision_manufacturing,
                'Machinery',
                DesktopSection.machinery,
              ),
              _sidebarItem(
                Icons.bar_chart_outlined,
                Icons.bar_chart,
                'Reports',
                DesktopSection.reports,
              ),
              _sidebarItem(
                Icons.settings_outlined,
                Icons.settings,
                'Systems',
                DesktopSection.systems,
              ),
            ],
          ),
        ),
        
        // Version Info
        Container(
          padding: const EdgeInsets.all(16),
          child: Text(
            'v1.0.0',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
          ),
        ),
      ],
    ),
  );
}


Widget _sidebarItem(
  IconData outlinedIcon,
  IconData filledIcon,
  String title,
  DesktopSection section,
) {
  final isSelected = selectedSection == section;

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            selectedSection = section;
            if (section == DesktopSection.inventory) {
              inventoryView = InventoryView.menu;
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    width: 1,
                  )
                : null,
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? filledIcon : outlinedIcon,
                size: 20,
                color: isSelected
                    ? AppTheme.primaryColor
                    : Colors.black54,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? AppTheme.textPrimary : Colors.black54,
                ),
              ),
              if (isSelected) ...[
                const Spacer(),
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildDesktopDashboard() {
  return StreamBuilder<QuerySnapshot>(
    stream: CompanyFirestore
        .collection('spare_parts')
        .snapshots(),
    builder: (context, snapshot) {

      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (snapshot.hasError) {
        return const Center(
          child: Text('Data error. Contact IT.'),
        );
      }

      final docs = snapshot.data?.docs ?? [];

      int totalItems = docs.length;
      int lowStock = 0;
      double totalValue = 0;

      for (var doc in docs) {
        final data = doc.data() as Map<String, dynamic>;

        int stock = data['currentStock'] ?? 0;
        int min = data['minimumStock'] ?? 0;
        double price =
            (data['price'] ?? 0).toDouble();

        if (stock < min) {
          lowStock++;
        }

        totalValue += stock * price;
      }

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

Expanded(
  child: InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: () {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: "SpareParts",
    barrierColor: Colors.black.withValues(alpha: 0.35),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, anim1, anim2) {
      return const DraggableResizableWindow(
  title: "Spare Parts",
  headerColor: Colors.blueGrey,
  child: SparePartListPage(),
);
    },
  );
},

    child: _summaryCard(
      'Spare Parts',
      Icons.inventory_2,
      Colors.blueGrey,
      totalItems.toString(),
    ),
  ),
),


                  const SizedBox(width: 24),

                  Expanded(
  child: InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: () {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: "LowStock",
    barrierColor: Colors.black.withValues(alpha: 0.35),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, anim1, anim2) {
      return const DraggableResizableWindow(
  title: "Low Stock",
  headerColor: Colors.redAccent,
  child: LowStockPage(),
);
    },
  );
},

    child: _summaryCard(
      'Low Stock',
      Icons.warning,
      Colors.redAccent,
      lowStock.toString(),
    ),
  ),
),

                  const SizedBox(width: 24),

                  Expanded(
                    child: _summaryCard(
                      'Inventory Value',
                      Icons.attach_money,
                      Colors.green,
                      totalValue.toStringAsFixed(0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

Container(
  height: 220,
  padding: const EdgeInsets.all(24),
  decoration: BoxDecoration(
    color: Colors.grey.withValues(alpha: 0.05),
    borderRadius: BorderRadius.circular(16),
  ),
  child: _buildMiniChart(totalItems, lowStock),
),

            ],
          ),
        ),
      );
    },
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
Widget _buildMiniChart(int total, int low) {
  final safeTotal = total == 0 ? 1 : total;
  final normal = safeTotal - low;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Stock Distribution',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 24),
      Expanded(
        child: Row(
          children: [
            Expanded(
              flex: normal <= 0 ? 1 : normal,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: low <= 0 ? 1 : low,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Normal: $normal"),
          Text("Low: $low"),
        ],
      ),
    ],
  );
}
Future<Map<String, dynamic>> _getSelectedCompanyInfo() async {
  final companyId = CompanySession.selectedCompanyId;
  if (companyId == null) return {};

  try {
    // Ambil data perusahaan dari Firestore
    final doc = await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .get();

    if (doc.exists) {
      return doc.data() as Map<String, dynamic>;
    }
  } catch (e) {
    print('Error fetching company info: $e');
  }

  // Fallback ke data lokal jika tidak ada di Firestore
  final rawName = companyId.toUpperCase();
  
  // PERBAIKAN: Format nama dengan spasi yang benar
  String displayName;
  
  // Cek apakah companyId sudah mengandung "ATOM" di dalamnya
  if (rawName.startsWith('ATOM')) {
    // Jika sudah ada ATOM, pisahkan ATOM dan sisanya
    if (rawName == 'ATOM') {
      displayName = 'ATOM';
    } else {
      // Contoh: "ATOMINDONESIA" -> "ATOM INDONESIA"
      final withoutAtom = rawName.substring(4); // Hapus "ATOM"
      displayName = 'ATOM $withoutAtom';
    }
  } else {
    // Jika belum ada ATOM, tambahkan ATOM dengan spasi
    displayName = 'ATOM $rawName';
  }
  
  return {
    'name': companyId.toUpperCase(),
    'displayName': displayName, // Sudah dengan spasi
    'flag': _getFlagForCompany(companyId),
    'color': _getColorForCompany(companyId),
  };
}

String _getFlagForCompany(String companyId) {
  switch (companyId.toLowerCase()) {
    case 'indonesia': return '🇮🇩';
    case 'india': return '🇮🇳';
    case 'vietnam': return '🇻🇳';
    default: return '🏢';
  }
}

Color _getColorForCompany(String companyId) {
  switch (companyId.toLowerCase()) {
    case 'indonesia': return const Color(0xFFFF6B6B);
    case 'india': return const Color(0xFFFFA06B);
    case 'vietnam': return const Color(0xFF6BCBFF);
    case 'singapore': return const Color(0xFFFFD93D);
    case 'malaysia': return const Color(0xFF6B8CFF);
    case 'thailand': return const Color(0xFFFF6B9D);
    default: return AppTheme.primaryColor;
  }
}
// Tambahkan fungsi ini di dalam _HomeDesktopState
String _getFlagEmoji(String companyId) {
  switch (companyId.toLowerCase()) {
    case 'indonesia':
    case 'atomindonesia':
    case 'indonesia atom':
      return '🇮🇩';
      
    case 'india':
    case 'atomindia':
    case 'india atom':
      return '🇮🇳';
      
    case 'vietnam':
    case 'atomvietnam':
    case 'vietnam atom':
      return '🇻🇳';
      
    default:
      final lowerId = companyId.toLowerCase();
      if (lowerId.contains('indonesia')) return '🇮🇩';
      if (lowerId.contains('india')) return '🇮🇳';
      if (lowerId.contains('vietnam')) return '🇻🇳';    
      return '🏢';
  }
}
}


