import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../pages/partners/partner_list_page.dart';
import '../pages/common/placeholder_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../attendance/pages/attendance_page.dart';
import '../attendance/services/attendance_period_helper.dart';
import '../pages/settings/settings_page.dart';
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
import '../../../models/read_tracker_service.dart';
import '../services/activity_service.dart';
import 'package:flutter/services.dart';

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

  List<Map<String, dynamic>> _recentActivities = [];
  final FocusNode _focusNode = FocusNode();

  // Tips bergantian (rotating tips)
  final List<String> _proTips = [
    'Use keyboard shortcuts: Ctrl+N for new order, Ctrl+F for search',
    'Double-click on any item to view details',
    'You can drag and drop files to upload attachments',
    'Use Ctrl+S to quickly access settings',
    'Right-click on tables for more options',
  ];

  int _currentTipIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadActivities(); 
    // Rotate tips every 10 seconds
    _startTipRotation();
  }

  Future<void> _loadActivities() async {
    final activities = await ActivityService.getActivities();
    if (mounted) {
      setState(() {
        _recentActivities = activities;
      });
    }
  }

  void _startTipRotation() {
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _currentTipIndex = (_currentTipIndex + 1) % _proTips.length;
        });
        _startTipRotation();
      }
    });
  }

// TAMBAHKAN METHOD INI UNTUK HANDLE KEYBOARD SHORTCUT
void _handleKeyPress(RawKeyEvent event) {
  if (!event.isControlPressed) return; // Hanya respons jika Ctrl ditekan

  // Log untuk debugging
  print('Key pressed: ${event.logicalKey.keyLabel}, Ctrl: ${event.isControlPressed}');

  // Ctrl + N : New Order In
  if (event.logicalKey == LogicalKeyboardKey.keyN) {  // <-- PERBAIKAN DI SINI
    print('Ctrl+N pressed - Opening Order In');
    setState(() {
      selectedSection = DesktopSection.inventory;
      inventoryView = InventoryView.orderIn;
    });
    
    // Record activity
    ActivityService.addActivity(
      icon: Icons.input,
      title: 'Used shortcut: New Order In (Ctrl+N)',
      color: Colors.green,
    ).then((_) => _loadActivities());
  }
  
  // Ctrl + M : New Order Out
  else if (event.logicalKey == LogicalKeyboardKey.keyM) {  // <-- PERBAIKAN DI SINI
    print('Ctrl+M pressed - Opening Order Out');
    setState(() {
      selectedSection = DesktopSection.inventory;
      inventoryView = InventoryView.orderOut;
    });
    
    // Record activity
    ActivityService.addActivity(
      icon: Icons.output,
      title: 'Used shortcut: New Order Out (Ctrl+M)',
      color: Colors.redAccent,
    ).then((_) => _loadActivities());
  }
  
  // Ctrl + F : Search (Open Spare Parts)
  else if (event.logicalKey == LogicalKeyboardKey.keyF) {  // <-- PERBAIKAN DI SINI
    print('Ctrl+F pressed - Opening Spare Parts');
    _openSpareParts();
  }
  
  // Ctrl + A : Attendance
  else if (event.logicalKey == LogicalKeyboardKey.keyA) {  // <-- PERBAIKAN DI SINI
    print('Ctrl+A pressed - Opening Attendance');
    _openAttendance();
  }
  
  // Ctrl + S : Settings
  else if (event.logicalKey == LogicalKeyboardKey.keyS) {  // <-- PERBAIKAN DI SINI
    print('Ctrl+S pressed - Opening Settings');
    _openSettings();
  }
  
  // Ctrl + D : Dashboard
  else if (event.logicalKey == LogicalKeyboardKey.keyD) {  // <-- PERBAIKAN DI SINI
    print('Ctrl+D pressed - Going to Dashboard');
    setState(() {
      selectedSection = DesktopSection.dashboard;
    });
  }
  
  // Ctrl + I : Inventory
  else if (event.logicalKey == LogicalKeyboardKey.keyI) {  // <-- PERBAIKAN DI SINI
    print('Ctrl+I pressed - Going to Inventory');
    setState(() {
      selectedSection = DesktopSection.inventory;
      inventoryView = InventoryView.menu;
    });
  }
  
  // Ctrl + R : Reports
  else if (event.logicalKey == LogicalKeyboardKey.keyR) {  // <-- PERBAIKAN DI SINI
    print('Ctrl+R pressed - Going to Reports');
    setState(() {
      selectedSection = DesktopSection.reports;
    });
  }
  
  // Ctrl + ? : Show Help (perbaikan untuk tombol ?)
  else if (event.logicalKey == LogicalKeyboardKey.slash && event.isShiftPressed) {  // <-- PERBAIKAN DI SINI
    print('Ctrl+? pressed - Showing Help');
    _showKeyboardShortcutsHelp();
  }
}

  Stream<int> lowStockCountStream() {
    return CompanyFirestore
        .collection('dashboard')
        .doc('stats')
        .snapshots()
        .map((doc) {
          final data = doc.data();
          return data?['lowStock'] ?? 0;
        });
  }

  int _crossAxis(double width) {
    if (width > 1700) return 6;
    if (width > 1400) return 5;
    if (width > 1200) return 4;
    return 3;
  }

  // ==================== WELCOME SCREEN (Pengganti Dashboard) ====================
  Widget _buildDesktopWelcome() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header dengan Gradient
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.15),
                    AppTheme.primaryColor.withOpacity(0.05),
                    Colors.white,
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back, ${_getDisplayName()}!',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getGreeting(),
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _getFormattedDate(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/Atom.png',
                      width: 70,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Quick Actions Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      selectedSection = DesktopSection.inventory;
                    });
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Quick Actions Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 800 ? 4 : 2;
                
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.3,
                  children: [
                    _quickActionCard(
                      Icons.add_shopping_cart,
                      'New Order In',
                      Colors.green,
                      () => setState(() {
                        selectedSection = DesktopSection.inventory;
                        inventoryView = InventoryView.orderIn;
                      }),
                    ),
                    _quickActionCard(
                      Icons.remove_shopping_cart,
                      'New Order Out',
                      Colors.redAccent,
                      () => setState(() {
                        selectedSection = DesktopSection.inventory;
                        inventoryView = InventoryView.orderOut;
                      }),
                    ),
                    _quickActionCard(
                      Icons.inventory,
                      'Check Stock',
                      Colors.blueGrey,
                      _openSpareParts,
                    ),
                    _quickActionCard(
                      Icons.event_available,
                      'Attendance',
                      Colors.blue,
                      _openAttendance,
                    ),
                    _quickActionCard(
                      Icons.groups,
                      'Partners',
                      Colors.deepPurple,
                      _openPartners,
                    ),
                    _quickActionCard(
                      Icons.precision_manufacturing,
                      'Machinery',
                      Colors.pinkAccent,
                      () => setState(() {
                        selectedSection = DesktopSection.machinery;
                      }),
                    ),
                    _quickActionCard(
                      Icons.bar_chart,
                      'Reports',
                      Colors.orange,
                      () => setState(() {
                        selectedSection = DesktopSection.reports;
                      }),
                    ),
                    _quickActionCard(
                      Icons.settings,
                      'Settings',
                      Colors.grey,
                      _openSettings,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),

            // Two Column Layout untuk Recent Activities dan Tips
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Recent Activities (Left Column)
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recent Activities',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade100,
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: _recentActivities.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Text('No recent activities'),
                              ),
                            )
                          : Column(
                              children: _recentActivities.map((activity) {
                                return Column(
                                  children: [
                                    _activityItem(
                                      activity['icon'],
                                      activity['title'],
                                      activity['time'],
                                      activity['color'],
                                    ),
                                    if (activity != _recentActivities.last)
                                      const Divider(height: 24),
                                  ],
                                );
                              }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                
                // Tips & Updates (Right Column)
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tips & Updates',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.amber.shade100,
                              Colors.amber.shade50,
                              Colors.white,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.amber.shade200,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.shade100,
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade200,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.lightbulb,
                                    color: Colors.amber.shade800,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Pro Tip',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _proTips[_currentTipIndex],
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: List.generate(
                                _proTips.length,
                                (index) => Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(left: 4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: index == _currentTipIndex
                                        ? Colors.amber.shade800
                                        : Colors.amber.shade200,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Keyboard Shortcuts Preview
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Keyboard Shortcuts',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _shortcutItem('Ctrl + N', 'New Order In'),
                            const SizedBox(height: 8),
                            _shortcutItem('Ctrl + M', 'New Order Out'),
                            const SizedBox(height: 8),
                            _shortcutItem('Ctrl + F', 'Search'),
                            const SizedBox(height: 8),
                            _shortcutItem('Ctrl + ?', 'Help'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Footer dengan Statistik Singkat (tanpa stream)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _footerStatItem(
                    Icons.inventory,
                    'Total Items',
                    '2,847',
                    Colors.blueGrey,
                  ),
                  _footerStatItem(
                    Icons.warning,
                    'Low Stock',
                    '23',
                    Colors.redAccent,
                  ),
                  _footerStatItem(
                    Icons.attach_money,
                    'Today\'s Value',
                    'Rp 45.2M',
                    Colors.green,
                  ),
                  _footerStatItem(
                    Icons.people,
                    'Active Users',
                    '12',
                    Colors.purple,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== HELPER METHODS ====================
  String _getDisplayName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      return user.displayName!.split(' ').first;
    }
    return 'User';
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning! Ready to start the day?';
    if (hour < 17) return 'Good afternoon! Hope you\'re having a productive day.';
    return 'Good evening! Wrapping up for the day?';
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  // ==================== UI COMPONENTS ====================
  Widget _quickActionCard(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade100,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activityItem(IconData icon, String title, String time, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            size: 18,
            color: Colors.grey.shade400,
          ),
        ],
      ),
    );
  }

  Widget _shortcutItem(String key, String description) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            key,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            description,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _footerStatItem(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==================== ORIGINAL METHODS (TIDAK BERUBAH) ====================
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
                          barrierColor: Colors.black.withOpacity(0.35),
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      String pageName = '';
      String collection = '';
      
      switch (inventoryView) {
        case InventoryView.menu:
          pageName = 'Inventory Menu';
          collection = 'spare_parts';
          break;
        case InventoryView.orderIn:
          pageName = 'Order In';
          collection = 'order_in';
          break;
        case InventoryView.orderOut:
          pageName = 'Order Out';
          collection = 'order_out';
          break;
      }
      
      ReadTrackerService().trackRead(
        page: pageName,
        collection: collection,
        operation: 'view',
        documentsCount: 0,
      );
    });

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
                        final user = FirebaseAuth.instance.currentUser!;
                        final employeeId = user.displayName!;
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
                    _desktopMenuCard(
                      Icons.build_circle,
                      'Service Report',
                      Colors.green,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const PlaceholderPage(title: 'Service Report'),
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
                                const PlaceholderPage(title: 'Buss. Trip Report'),
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
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => LogoutHelper.logout(context),
            child: const Text('Logout'),
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
                      _openSettings,
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
            color: color.withOpacity(0.12),
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

  WidgetsBinding.instance.addPostFrameCallback((_) {
    ReadTrackerService().trackRead(
      page: 'HomeDesktop',
      collection: 'multiple',
      operation: 'page_view',
      documentsCount: 0,
    );
  });

  // UBAH RETURN MENJADI RawKeyboardListener
  return RawKeyboardListener(
    focusNode: _focusNode,
    onKey: _handleKeyPress,
    autofocus: true, // Penting! Agar bisa menerima keyboard input
    child: Scaffold(
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildContent() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      String pageName = '';
      String collection = '';
      
      switch (selectedSection) {
        case DesktopSection.dashboard:
          pageName = 'Dashboard Section';
          collection = 'spare_parts';
          break;
        case DesktopSection.inventory:
          pageName = 'Inventory Section';
          collection = 'spare_parts';
          break;
        case DesktopSection.machinery:
          pageName = 'Machinery Section';
          collection = 'machinery';
          break;
        case DesktopSection.reports:
          pageName = 'Reports Section';
          collection = 'attendance';
          break;
        case DesktopSection.systems:
          pageName = 'Systems Section';
          collection = 'settings';
          break;
      }
      
      ReadTrackerService().trackRead(
        page: pageName,
        collection: collection,
        operation: 'section_view',
        documentsCount: 0,
      );
    });

    switch (selectedSection) {
      case DesktopSection.dashboard:
        return _buildDesktopWelcome(); // GANTI DENGAN WELCOME SCREEN

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
      width: 280,
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

          // COMPANY INFO CARD
          if (companyId != null)
            FutureBuilder<Map<String, dynamic>>(
              future: _getSelectedCompanyInfo(),
              builder: (context, snapshot) {
                final companyColor = snapshot.data?['color'] ?? 
                    _getColorForCompany(companyId);
                String companyName;

                if (snapshot.data != null && snapshot.data!['displayName'] != null) {
                  companyName = snapshot.data!['displayName'];
                } else {
                  final rawName = companyId.toUpperCase();
                  
                  if (rawName.contains('ATOM')) {
                    if (rawName == 'ATOM') {
                      companyName = 'ATOM';
                    } else {
                      final withoutAtom = rawName.replaceAll('ATOM', '').trim();
                      companyName = 'ATOM $withoutAtom';
                    }
                  } else {
                    companyName = 'ATOM $rawName';
                  }
                  
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

  // ==================== ACTION METHODS ====================
  void _openSpareParts() async {
  // Record activity (TAMBAHKAN 3 BARIS INI)
  await ActivityService.addActivity(
    icon: Icons.inventory,
    title: 'Viewed spare parts',
    color: Colors.blueGrey,
  );
  
  // Refresh recent activities (TAMBAHKAN INI)
  await _loadActivities();
  
  // Buka dialog (CODE YANG SUDAH ADA)
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: "SpareParts",
    barrierColor: Colors.black.withOpacity(0.35),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (_, __, ___) {
      return const DraggableResizableWindow(
        title: "Spare Parts",
        headerColor: Colors.blueGrey,
        child: SparePartListPage(),
      );
    },
  );
}

  void _openAttendance() async {
  // Record activity (TAMBAHKAN 3 BARIS INI)
  await ActivityService.addActivity(
    icon: Icons.event_available,
    title: 'Opened attendance page',
    color: Colors.blue,
  );
  
  // Refresh recent activities (TAMBAHKAN INI)
  await _loadActivities();
  
  final user = FirebaseAuth.instance.currentUser!;
  final employeeId = user.displayName!;
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
}


  void _openPartners() async {
  // Record activity (TAMBAHKAN 3 BARIS INI)
  await ActivityService.addActivity(
    icon: Icons.groups,
    title: 'Viewed partners list',
    color: Colors.deepPurple,
  );
  
  // Refresh recent activities (TAMBAHKAN INI)
  await _loadActivities();
  
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const PartnerListPage(),
    ),
  );
}

  void _openSettings() async {
  // Record activity (TAMBAHKAN 3 BARIS INI)
  await ActivityService.addActivity(
    icon: Icons.settings,
    title: 'Opened settings',
    color: Colors.grey,
  );
  
  // Refresh recent activities (TAMBAHKAN INI)
  await _loadActivities();
  
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const SettingsPage(),
    ),
  );
}
  // ==================== COMPANY INFO METHODS (TIDAK BERUBAH) ====================
  Future<Map<String, dynamic>> _getSelectedCompanyInfo() async {
    final companyId = CompanySession.selectedCompanyId;
    if (companyId == null) return {};

    try {
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

    final rawName = companyId.toUpperCase();
    
    String displayName;
    
    if (rawName.startsWith('ATOM')) {
      if (rawName == 'ATOM') {
        displayName = 'ATOM';
      } else {
        final withoutAtom = rawName.substring(4);
        displayName = 'ATOM $withoutAtom';
      }
    } else {
      displayName = 'ATOM $rawName';
    }
    
    return {
      'name': companyId.toUpperCase(),
      'displayName': displayName,
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
  // TAMBAHKAN METHOD UNTUK MENAMPILKAN HELP
void _showKeyboardShortcutsHelp() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.keyboard, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          const Text('Keyboard Shortcuts'),
        ],
      ),
      content: Container(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildShortcutListItem('Ctrl + N', 'New Order In'),
            const Divider(),
            _buildShortcutListItem('Ctrl + M', 'New Order Out'),
            const Divider(),
            _buildShortcutListItem('Ctrl + F', 'Search Spare Parts'),
            const Divider(),
            _buildShortcutListItem('Ctrl + A', 'Attendance'),
            const Divider(),
            _buildShortcutListItem('Ctrl + S', 'Settings'),
            const Divider(),
            _buildShortcutListItem('Ctrl + D', 'Dashboard'),
            const Divider(),
            _buildShortcutListItem('Ctrl + I', 'Inventory'),
            const Divider(),
            _buildShortcutListItem('Ctrl + R', 'Reports'),
            const Divider(),
            _buildShortcutListItem('Ctrl + ?', 'Show this help'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

Widget _buildShortcutListItem(String key, String description) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: Text(
            key,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(description),
        ),
      ],
    ),
  );
}
}