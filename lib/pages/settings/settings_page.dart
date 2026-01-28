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

  bool isImporting = false;
  int importCurrent = 0;
  int importTotal = 0;

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    final result = await isCurrentUserAdmin();
    setState(() {
      isAdmin = result;
    });
  }

  // =========================
  // RUN IMPORT WITH PROGRESS
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

      setState(() {
        importCurrent++;
      });
    }

    setState(() {
      isImporting = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Import completed')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton(
            onPressed: testLoadJson,
            child: const Text('TEST LOAD JSON'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: testFirestoreConnection,
            child: const Text('TEST FIRESTORE CONNECTION'),
          ),

          // =========================
          // IMPORT SECTION (ADMIN)
          // =========================
          if (isAdmin) ...[
            const Divider(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: isImporting
                  ? null
                  : () => confirmImport(context, runImportWithProgress),
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
          ],

          const Divider(height: 32),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('About App'),
          ),
          const ListTile(
            leading: Icon(Icons.language),
            title: Text('Language'),
          ),
          const ListTile(
            leading: Icon(Icons.verified),
            title: Text('License Info'),
          ),
        ],
      ),
    );
  }
}

// ======================================================
// CONFIRM IMPORT DIALOG
// ======================================================
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

// ======================================================
// ADMIN CHECK
// ======================================================
Future<bool> isCurrentUserAdmin() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null || user.email == null) return false;

  final doc = await FirebaseFirestore.instance
      .collection('admin_whitelist')
      .doc(user.email!.toLowerCase())
      .get();

  return doc.exists && doc.data()?['active'] == true;
}

// ======================================================
// TEST JSON
// ======================================================
Future<void> testLoadJson() async {
  final jsonString =
      await rootBundle.loadString('assets/data/spare_parts.json');
  final List<dynamic> data = json.decode(jsonString);

  debugPrint('TOTAL PART: ${data.length}');
}

// ======================================================
// TEST FIRESTORE
// ======================================================
Future<void> testFirestoreConnection() async {
  final firestore = FirebaseFirestore.instance;

  await firestore.collection('test_connection').doc('ping').set({
    'message': 'hello firestore',
    'timestamp': FieldValue.serverTimestamp(),
  });

  debugPrint('FIRESTORE CONNECTED');
}
