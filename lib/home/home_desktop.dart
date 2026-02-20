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
import '../pages/spare_part/low_stock_page.dart';
import '../pages/spare_part/spare_part_list_page.dart';
import '../order_in/order_in_desktop.dart';
import '../order_out/order_out_desktop.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
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

        const SizedBox(height: 28),

        Image.asset(
          'assets/images/Atom.png',
          width: 60,
        ),

        const SizedBox(height: 14),

        Text(
          displayName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 2),

        Text(
          email,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),

        const SizedBox(height: 24),

        const Divider(
          thickness: 1,
          height: 1,
        ),

        const SizedBox(height: 12),

        Expanded(
          child: ListView(
            children: [
              _sidebarItem(Icons.dashboard, 'Dashboard', DesktopSection.dashboard),
              _sidebarItem(Icons.inventory, 'Inventory', DesktopSection.inventory),
              _sidebarItem(Icons.precision_manufacturing, 'Machinery', DesktopSection.machinery),
              _sidebarItem(Icons.bar_chart, 'Reports', DesktopSection.reports),
              _sidebarItem(Icons.settings, 'Systems', DesktopSection.systems),
            ],
          ),
        ),
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

    if (section == DesktopSection.inventory) {
      inventoryView = InventoryView.menu;
    }
  });
},

    hoverColor: Colors.black.withValues(alpha: 0.05),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.white.withValues(alpha: 0.8)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isSelected
            ? const Border(
                left: BorderSide(
                  color: Colors.deepOrange,
                  width: 4,
                ),
              )
            : null,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isSelected
                ? Colors.deepOrange
                : Colors.black87,
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.normal,
              color: Colors.black,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildDesktopDashboard() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
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
      return _DraggableResizableWindow(
        title: "Spare Parts",
        child: const SparePartListPage(),
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
      return _DraggableResizableWindow(
        title: "Low Stock",
        child: const LowStockPage(),
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
}

class _DraggableResizableWindow extends StatefulWidget {
  final String title;
  final Widget child;

  const _DraggableResizableWindow({
    required this.title,
    required this.child,
  });

  @override
  State<_DraggableResizableWindow> createState() =>
      _DraggableResizableWindowState();
}

class _DraggableResizableWindowState
    extends State<_DraggableResizableWindow> {

      bool _initialized = false;

  double width = 900;
  double height = 550;
  double top = 120;
  double left = 200;

  @override
Widget build(BuildContext context) {

  final screenSize = MediaQuery.of(context).size;

  // Hitung posisi tengah saat pertama kali render
  if (!_initialized) {
    left = (screenSize.width - width) / 2;
    top = (screenSize.height - height) / 2;
    _initialized = true;
  }

  return Stack(
    children: [
      Positioned(
        top: top,
        left: left,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Column(
                children: [
                  GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        left += details.delta.dx;
                        top += details.delta.dy;
                      });
                    },
                    child: Container(
                      height: 50,
                      color: Colors.blueGrey,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close,
                                color: Colors.white),
                            onPressed: () =>
                                Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Expanded(
                    child: widget.child,
                  ),

                  Align(
                    alignment: Alignment.bottomRight,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          width += details.delta.dx;
                          height += details.delta.dy;

                          if (width < 600) width = 600;
                          if (height < 400) height = 400;
                        });
                      },
                      child: Container(
                        width: 20,
                        height: 20,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.drag_handle,
                          size: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

}

