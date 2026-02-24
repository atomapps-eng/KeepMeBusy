import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/company_firestore.dart';
import '../../features/admin/pages/admin_analytics_page.dart';
import '../../../models/read_tracker_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with TickerProviderStateMixin {
  bool isAdmin = false;
  bool _isCheckingAdmin = true;
  String? _userEmail;
  String _debugMessage = '';
  
  // Animation controllers
  late AnimationController _fadeInController;
  late Animation<double> _fadeInAnimation;

  // ===== IMPORT STATE =====
  bool isImporting = false;
  int importCurrent = 0;
  int importTotal = 0;

  // ===== RESET STATE =====
  bool isResetting = false;
  int resetCurrent = 0;
  int resetTotal = 0;

  // ===== EXPANDED SECTIONS =====
  bool _isTestingExpanded = true;
  bool _isDataManagementExpanded = false;
  bool _isDangerZoneExpanded = false;

  @override
  void initState() {
    super.initState();
    _getUserEmail();
    _checkAdmin();
    
    _fadeInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeInAnimation = CurvedAnimation(
      parent: _fadeInController,
      curve: Curves.easeOut,
    );
    _fadeInController.forward();
  }

  @override
  void dispose() {
    _fadeInController.dispose();
    super.dispose();
  }

  void _getUserEmail() {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      _userEmail = user?.email;
    });
  }

  // =========================
  // ADMIN CHECK - FIXED VERSION
  // =========================
Future<bool> isCurrentUserAdmin() async {
  final user = FirebaseAuth.instance.currentUser;
  
  print('===== ADMIN CHECK DEBUG =====');
  print('Current user: ${user?.email}');
  
  if (user == null || user.email == null) {
    print('ERROR: No user logged in or no email');
    return false;
  }
  
  final userEmail = user.email!.toLowerCase().trim();
  print('Checking admin for email: "$userEmail"');
  
  try {
    // Gunakan collection admin_whitelist
    final docRef = FirebaseFirestore.instance
        .collection('admin_whitelist')  // ← Pakai admin_whitelist
        .doc(userEmail);
    
    print('Document path: admin_whitelist/$userEmail');
    
    final doc = await docRef.get();
    
    print('Document exists: ${doc.exists}');
    
    if (doc.exists) {
      print('Document data: ${doc.data()}');
      
      // Cek apakah ada field active
      final data = doc.data();
      if (data != null && data.containsKey('active')) {
        final isActive = data['active'] == true;
        print('Active field value: ${data['active']}');
        print('Active field type: ${data['active'].runtimeType}');
        print('Is active: $isActive');
        return isActive;
      }
      
      // Jika tidak ada field active, anggap true karena dokumennya exist
      print('No active field, but document exists - treating as admin');
      return true;
    } else {
      print('Email not found in admin_whitelist');
      
      // Tampilkan semua dokumen yang ada untuk debugging
      print('\nListing all documents in admin_whitelist:');
      final snapshot = await FirebaseFirestore.instance
          .collection('admin_whitelist')
          .get();
      
      print('Total documents: ${snapshot.docs.length}');
      for (var doc in snapshot.docs) {
        print(' - Document ID: "${doc.id}", Data: ${doc.data()}');
      }
      
      return false;
    }
  } catch (e) {
    print('ERROR checking admin: $e');
    print('Stack trace: ${StackTrace.current}');
    return false;
  }
}

  Future<void> _checkAdmin() async {
    setState(() {
      _isCheckingAdmin = true;
      _debugMessage = 'Checking admin status...';
    });
    
    try {
      final result = await isCurrentUserAdmin();
      print('Admin check result: $result');
      
      setState(() {
        isAdmin = result;
        _isCheckingAdmin = false;
        _debugMessage = result ? '✓ Admin access granted' : '✗ Admin access denied';
      });
    } catch (e) {
      print('Error in _checkAdmin: $e');
      setState(() {
        isAdmin = false;
        _isCheckingAdmin = false;
        _debugMessage = 'Error: $e';
      });
    }
  }

  Future<void> _refreshAdminStatus() async {
    await _checkAdmin();
  }

  // =========================
  // SNACKBARS WITH STYLE
  // =========================
  void _showStyledSnackbar(String message, {bool isError = false, bool isWarning = false}) {
    final color = isError ? Colors.red : (isWarning ? Colors.orange : Colors.green);
    final icon = isError ? Icons.error_outline : (isWarning ? Icons.warning_amber_rounded : Icons.check_circle_outline);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // =========================
  // TEST LOAD JSON
  // =========================
  Future<void> _handleTestLoadJson() async {
    print('Test Load JSON clicked');
    if (!isAdmin) {
      _showStyledSnackbar('Anda tidak memiliki hak akses', isWarning: true);
      return;
    }

    try {
      final jsonString = await rootBundle.loadString('assets/data/spare_parts.json');
      final List<dynamic> data = json.decode(jsonString);
      _showStyledSnackbar('JSON berhasil dimuat: ${data.length} data');
    } catch (e) {
      print('Error loading JSON: $e');
      _showStyledSnackbar('Gagal load JSON: $e', isError: true);
    }
  }

  // =========================
  // TEST FIRESTORE
  // =========================
  Future<void> _handleTestFirestore() async {
    print('Test Firestore clicked');
    if (!isAdmin) {
      _showStyledSnackbar('Anda tidak memiliki hak akses', isWarning: true);
      return;
    }

    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('test_connection').doc('ping').set({
        'message': 'hello firestore',
        'timestamp': FieldValue.serverTimestamp(),
      });
      _showStyledSnackbar('Firestore connection OK');
    } catch (e) {
      print('Error testing Firestore: $e');
      _showStyledSnackbar('Firestore connection FAILED: $e', isError: true);
    }
  }

  // =========================
  // IMPORT DATA
  // =========================
  Future<void> runImportWithProgress() async {
    final jsonString = await rootBundle.loadString('assets/data/spare_parts.json');
    final List<dynamic> data = json.decode(jsonString);

    setState(() {
      isImporting = true;
      importCurrent = 0;
      importTotal = data.length;
    });

    for (final item in data) {
      final String partCode = item['partCode'];
      final docRef = CompanyFirestore.doc('spare_parts', partCode);
      final docSnap = await docRef.get();

      if (!docSnap.exists) {
        await docRef.set({
          'partCode': partCode,
          'name': item['name'],
          'nameEn': item['nameEn'],
          'location': item['location'],
          'category': item['category'],
          'origin': item['origin'],
          'initialStock': item['initialStock'],
          'currentStock': item['initialStock'],
          'minimumStock': item['minimumStock'],
          'weight': item['weight'],
          'weightUnit': item['weightUnit'],
          'imageUrl': item['imageUrl'],
          'active': item['active'],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await docRef.update({
          'name': item['name'],
          'nameEn': item['nameEn'],
          'location': item['location'],
          'category': item['category'],
          'origin': item['origin'],
          'minimumStock': item['minimumStock'],
          'weight': item['weight'],
          'weightUnit': item['weightUnit'],
          'imageUrl': item['imageUrl'],
          'active': item['active'],
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      setState(() => importCurrent++);
    }

    setState(() => isImporting = false);
    _showStyledSnackbar('Import selesai: $importTotal spare part');
  }

  // =========================
  // RESET ALL DATA
  // =========================
  Future<void> _handleResetAllData() async {
    if (!isAdmin) {
      _showStyledSnackbar('Anda tidak memiliki hak akses', isWarning: true);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text('⚠️ RESET SEMUA DATA'),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Aksi ini akan MENGHAPUS:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildBulletPoint('Spare Parts', Icons.inventory),
              _buildBulletPoint('Order In', Icons.shopping_cart),
              _buildBulletPoint('Order Out', Icons.outbox),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tindakan ini TIDAK BISA DIBATALKAN',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('BATAL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('HAPUS SEMUA'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      isResetting = true;
      resetCurrent = 0;
      resetTotal = 0;
    });

    try {
      resetTotal += await _countCollection('spare_parts');
      resetTotal += await _countCollection('order_in');
      resetTotal += await _countCollection('order_out');

      await _deleteCollectionWithProgress('spare_parts');
      await _deleteCollectionWithProgress('order_in');
      await _deleteCollectionWithProgress('order_out');

      _showStyledSnackbar('Semua data berhasil dihapus');
    } catch (e) {
      _showStyledSnackbar('Gagal reset data: $e', isError: true);
    } finally {
      setState(() => isResetting = false);
    }
  }

  Widget _buildBulletPoint(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  Future<int> _countCollection(String name) async {
    final collection = name == 'spare_parts'
        ? CompanyFirestore.collection('spare_parts')
        : FirebaseFirestore.instance.collection(name);
    final snap = await collection.get();
    return snap.size;
  }

  Future<void> _deleteCollectionWithProgress(String name) async {
    final firestore = FirebaseFirestore.instance;
    const batchSize = 200;

    while (true) {
      final collection = name == 'spare_parts'
          ? CompanyFirestore.collection('spare_parts')
          : firestore.collection(name);

      final snapshot = await collection.limit(batchSize).get();

      if (snapshot.docs.isEmpty) break;

      final batch = firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      setState(() {
        resetCurrent += snapshot.docs.length;
      });
    }
  }

  // =========================
  // SECTION HEADER WIDGET
  // =========================
  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (color ?? Colors.blue).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color ?? Colors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              AnimatedRotation(
                turns: isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================
  // PROGRESS INDICATOR
  // =========================
  Widget _buildProgressIndicator({
    required int current,
    required int total,
    required String label,
    required Color color,
  }) {
    final progress = total == 0 ? 0.0 : current / total;
    
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$current / $total',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('Building SettingsPage, isAdmin: $isAdmin, isChecking: $_isCheckingAdmin');
    
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFFFE0B2),
                  const Color(0xFFFFF3E0),
                  const Color(0xFFFFFFFF),
                ],
              ),
            ),
          ),
          
          // Background Pattern
          Positioned.fill(
            child: CustomPaint(
              painter: BackgroundPatternPainter(),
            ),
          ),

          SafeArea(
            child: _isCheckingAdmin 
              ? const Center(child: CircularProgressIndicator())
              : FadeTransition(
                  opacity: _fadeInAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        _GlassHeader(
                          title: 'Settings',
                          onBack: () => Navigator.pop(context),
                        ),
                        
                        const SizedBox(height: 24),

                        // Admin Status Card
                        _GlassCard(
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isAdmin ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isAdmin ? Icons.admin_panel_settings : Icons.person,
                                      color: isAdmin ? Colors.green : Colors.grey,
                                      size: 30,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isAdmin ? 'Administrator' : 'Regular User',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Email: $_userEmail',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _debugMessage,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isAdmin ? Colors.green : Colors.red,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.refresh),
                                    onPressed: _refreshAdminStatus,
                                    tooltip: 'Refresh admin status',
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 20),
                              
                              // Admin Analytics Button
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isAdmin 
                                      ? [Colors.purple.shade300, Colors.purple.shade700]
                                      : [Colors.grey.shade300, Colors.grey.shade700],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: isAdmin ? () {
                                    print('Navigating to AdminAnalyticsPage');
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const AdminAnalyticsPage(),
                                      ),
                                    );
                                  } : null,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.analytics, 
                                          color: isAdmin ? Colors.white : Colors.grey.shade400, 
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'ADMIN ANALYTICS DASHBOARD',
                                        style: TextStyle(
                                          color: isAdmin ? Colors.white : Colors.grey.shade400,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              
                              if (ReadTrackerService().isTracking) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.green),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Analytics Tracking Active',
                                        style: TextStyle(color: Colors.green),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),

                        // Main Settings Card
                        _GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Testing Section
                              _buildSectionHeader(
                                title: 'Testing & Diagnostics',
                                icon: Icons.science,
                                isExpanded: _isTestingExpanded,
                                color: Colors.blue,
                                onTap: () => setState(() => _isTestingExpanded = !_isTestingExpanded),
                              ),
                              
                              if (_isTestingExpanded) ...[
                                const SizedBox(height: 12),
                                
                                // Test Load JSON Button
                                _buildActionButton(
                                  label: 'Test Load JSON',
                                  icon: Icons.file_open,
                                  color: Colors.blue,
                                  onPressed: isAdmin ? _handleTestLoadJson : null,
                                  isEnabled: isAdmin,
                                ),
                                
                                const SizedBox(height: 8),
                                
                                // Test Firestore Button
                                _buildActionButton(
                                  label: 'Test Firestore Connection',
                                  icon: Icons.cloud,
                                  color: Colors.blue,
                                  onPressed: isAdmin ? _handleTestFirestore : null,
                                  isEnabled: isAdmin,
                                ),
                              ],

                              const Divider(height: 24),

                              // Data Management Section
                              _buildSectionHeader(
                                title: 'Data Management',
                                icon: Icons.storage,
                                isExpanded: _isDataManagementExpanded,
                                color: Colors.orange,
                                onTap: () => setState(() => _isDataManagementExpanded = !_isDataManagementExpanded),
                              ),
                              
                              if (_isDataManagementExpanded) ...[
                                const SizedBox(height: 12),
                                _buildActionButton(
                                  label: 'Import Spare Parts',
                                  icon: Icons.download,
                                  color: Colors.green,
                                  onPressed: (isImporting || !isAdmin) ? null : () {
                                    confirmImport(context, runImportWithProgress);
                                  },
                                  isEnabled: !isImporting && isAdmin,
                                  isLoading: isImporting,
                                ),
                                
                                if (isImporting) ...[
                                  const SizedBox(height: 8),
                                  _buildProgressIndicator(
                                    current: importCurrent,
                                    total: importTotal,
                                    label: 'Importing Spare Parts',
                                    color: Colors.green,
                                  ),
                                ],
                              ],

                              const Divider(height: 24),

                              // Danger Zone
                              _buildSectionHeader(
                                title: 'Danger Zone',
                                icon: Icons.warning,
                                isExpanded: _isDangerZoneExpanded,
                                color: Colors.red,
                                onTap: () => setState(() => _isDangerZoneExpanded = !_isDangerZoneExpanded),
                              ),
                              
                              if (_isDangerZoneExpanded) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 20),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Reset All Data',
                                              style: TextStyle(
                                                color: Colors.red.shade700,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'This action will permanently delete all spare parts, order in, and order out data.',
                                        style: TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                      const SizedBox(height: 12),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                        onPressed: (isResetting || !isAdmin) ? null : _handleResetAllData,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              if (isResetting)
                                                const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              else
                                                const Icon(Icons.delete_forever),
                                              const SizedBox(width: 8),
                                              Text(isResetting ? 'Resetting...' : 'RESET ALL DATA'),
                                            ],
                                          ),
                                        ),
                                      ),
                                      if (isResetting) ...[
                                        const SizedBox(height: 8),
                                        _buildProgressIndicator(
                                          current: resetCurrent,
                                          total: resetTotal,
                                          label: 'Deleting Data',
                                          color: Colors.red,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  // =========================
  // ACTION BUTTON WIDGET
  // =========================
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    Color? color,
    bool isEnabled = true,
    bool isLoading = false,
  }) {
    final bool canPress = isEnabled && onPressed != null && !isLoading;
    
    return Opacity(
      opacity: canPress ? 1.0 : 0.5,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: canPress ? onPressed : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: (color ?? Colors.blue).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (color ?? Colors.blue).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, color: (color ?? Colors.blue).withOpacity(canPress ? 1 : 0.5), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: (color ?? Colors.blue).withOpacity(canPress ? 1 : 0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (isLoading)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: color ?? Colors.blue,
                      ),
                    ),
                  if (!isEnabled && !isLoading && !isAdmin)
                    Icon(Icons.lock, color: Colors.grey, size: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =========================
// BACKGROUND PATTERN
// =========================
class BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final double spacing = 30;
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// =========================
// GLASS HEADER
// =========================
class _GlassHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _GlassHeader({
    required this.title,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, size: 20),
                  onPressed: onBack,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================
// GLASS CARD
// =========================
class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const _GlassCard({
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// =========================
// CONFIRM IMPORT
// =========================
void confirmImport(
  BuildContext context,
  Future<void> Function() onConfirm,
) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Confirm Import'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('This action will:'),
          SizedBox(height: 8),
          Text('• Add new spare parts', style: TextStyle(fontSize: 14)),
          Text('• Update existing spare parts', style: TextStyle(fontSize: 14)),
          Text('• Preserve current stock levels', style: TextStyle(fontSize: 14)),
          SizedBox(height: 16),
          Text('Do you want to continue?'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          child: const Text('IMPORT'),
        ),
      ],
    ),
  );
}