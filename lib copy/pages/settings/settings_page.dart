import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isAdmin = false;

  // ===== IMPORT STATE =====
  bool isImporting = false;
  int importCurrent = 0;
  int importTotal = 0;

  // ===== RESET STATE =====
  bool isResetting = false;
  int resetCurrent = 0;
  int resetTotal = 0;

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    final result = await isCurrentUserAdmin();
    setState(() => isAdmin = result);
  }

  // =========================
  // SNACKBARS
  // =========================
  void _showAdminWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Anda tidak memiliki hak akses untuk menjalankan aksi ini',
        ),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // =========================
  // TEST LOAD JSON
  // =========================
  Future<void> _handleTestLoadJson() async {
    if (!isAdmin) {
      _showAdminWarning();
      return;
    }

    try {
      final jsonString =
          await rootBundle.loadString('assets/data/spare_parts.json');
      final List<dynamic> data = json.decode(jsonString);
      _showSuccess('JSON berhasil dimuat: ${data.length} data');
    } catch (e) {
      _showError('Gagal load JSON: $e');
    }
  }

  // =========================
  // TEST FIRESTORE
  // =========================
  Future<void> _handleTestFirestore() async {
    if (!isAdmin) {
      _showAdminWarning();
      return;
    }

    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('test_connection').doc('ping').set({
        'message': 'hello firestore',
        'timestamp': FieldValue.serverTimestamp(),
      });
      _showSuccess('Firestore connection OK');
    } catch (e) {
      _showError('Firestore connection FAILED: $e');
    }
  }

  // =========================
  // IMPORT DATA (UNCHANGED)
  // =========================
  Future<void> runImportWithProgress() async {
    final jsonString =
        await rootBundle.loadString('assets/data/spare_parts.json');
    final List<dynamic> data = json.decode(jsonString);

    setState(() {
      isImporting = true;
      importCurrent = 0;
      importTotal = data.length;
    });

    final firestore = FirebaseFirestore.instance;

    for (final item in data) {
      final String partCode = item['partCode'];

      final docRef = firestore.collection('spare_parts').doc(partCode);
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
    _showSuccess('Import selesai: $importTotal spare part');
  }

  // =========================
  // RESET ALL DATA WITH PROGRESS
  // =========================
  Future<void> _handleResetAllData() async {
    if (!isAdmin) {
      _showAdminWarning();
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('⚠️ RESET SEMUA DATA'),
        content: const Text(
          'Aksi ini akan MENGHAPUS:\n\n'
          '- Spare Parts\n'
          '- Order In\n'
          '- Order Out\n\n'
          'Tindakan ini TIDAK BISA DIBATALKAN.\n\n'
          'Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('BATAL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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

      _showSuccess('Semua data berhasil dihapus');
    } catch (e) {
      _showError('Gagal reset data: $e');
    } finally {
      setState(() => isResetting = false);
    }
  }

  Future<int> _countCollection(String name) async {
    final snap =
        await FirebaseFirestore.instance.collection(name).get();
    return snap.size;
  }

  Future<void> _deleteCollectionWithProgress(String name) async {
    final firestore = FirebaseFirestore.instance;
    const batchSize = 200;

    while (true) {
      final snapshot =
          await firestore.collection(name).limit(batchSize).get();

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

  @override
  Widget build(BuildContext context) {
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _GlassHeader(
                    title: 'Settings',
                    onBack: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 20),
                  _GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton(
                          onPressed: _handleTestLoadJson,
                          child: const Text('TEST LOAD JSON'),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _handleTestFirestore,
                          child:
                              const Text('TEST FIRESTORE CONNECTION'),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red),
                          onPressed: isImporting
                              ? null
                              : () {
                                  if (!isAdmin) {
                                    _showAdminWarning();
                                    return;
                                  }
                                  confirmImport(
                                    context,
                                    runImportWithProgress,
                                  );
                                },
                          child: const Text('IMPORT SPARE PARTS'),
                        ),
                        if (isImporting) ...[
                          const SizedBox(height: 16),
                          LinearProgressIndicator(
                            value: importTotal == 0
                                ? null
                                : importCurrent / importTotal,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Importing $importCurrent / $importTotal',
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const Divider(height: 32),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black),
                          onPressed:
                              isResetting ? null : _handleResetAllData,
                          child: const Text(
                            'RESET ALL DATA (DANGEROUS)',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        if (isResetting) ...[
                          const SizedBox(height: 16),
                          LinearProgressIndicator(
                            value: resetTotal == 0
                                ? null
                                : resetCurrent / resetTotal,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Deleting $resetCurrent / $resetTotal',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
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
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
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

  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(16),
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
// ADMIN CHECK
// =========================
Future<bool> isCurrentUserAdmin() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null || user.email == null) return false;

  final doc = await FirebaseFirestore.instance
      .collection('admin_whitelist')
      .doc(user.email!.toLowerCase())
      .get();

  return doc.exists && doc.data()?['active'] == true;
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
      content: const Text(
        'This action will add or update spare part master data.\n\n'
        'Current stock will NOT be reset.\n\n'
        'Do you want to continue?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
