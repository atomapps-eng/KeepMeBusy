import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/spare_part.dart';
import 'edit_spare_part_page.dart';

class SparePartDetailPage extends StatelessWidget {
  final SparePart part;

  const SparePartDetailPage({super.key, required this.part});

  // =========================
  // ADMIN CHECK
  // =========================
  Future<bool> _isAdmin() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null || user.email == null) return false;

  final doc = await FirebaseFirestore.instance
      .collection('admin_whitelist')
      .doc(user.email!.toLowerCase())
      .get();

  return doc.exists && doc.data()?['active'] == true;
}


  @override
  Widget build(BuildContext context) {
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== HEADER =====
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Spare Part Detail',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ===== HERO IMAGE =====
                  Center(
                    child: Hero(
                      tag: 'spare-part-image-${part.partCode}',
                      child: _DetailImage(imageUrl: part.imageUrl),
                    ),
                  ),

                  const SizedBox(height: 24),

                  _infoRow('Part Code', part.partCode),
                  _infoRow('Name', part.name),
                  _infoRow('Name (EN)', part.nameEn),
                  _infoRow('Location', part.location),

                  const Divider(height: 32),

                  _infoRow('Initial Stock', part.initialStock.toString()),
                  _infoRow('Current Stock', part.currentStock.toString()),
                  _infoRow('Minimum Stock', part.minimumStock.toString()),

                  const Divider(height: 32),

                  _infoRow(
                    'Category',
                    part.category.name.replaceAll('_', ' '),
                  ),
                  _infoRow(
                    'Origin',
                    part.origin.name.replaceAll('_', ' '),
                  ),

                  const Divider(height: 32),

                  _infoRow(
                    'Weight',
                    '${part.weight} ${part.weightUnit}',
                  ),

                  const SizedBox(height: 28),

                  // ===== ACTIONS =====
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    EditSparePartPage(part: part),
                              ),
                            );

                            if (context.mounted) {
                              Navigator.pop(context, true); // 🔥 auto refresh
                            }
                          },
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.delete),
                          label: const Text('Hapus'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () async {
                            final isAdmin = await _isAdmin();

                            if (!context.mounted) return;

                            if (!isAdmin) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Anda tidak memiliki hak akses untuk menghapus data ini',
                                  ),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }

                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title:
                                    const Text('Hapus Spare Part'),
                                content: Text(
                                  'Yakin ingin menghapus "${part.name}"?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Batal'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Hapus'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm != true) return;

                            await FirebaseFirestore.instance
                                .collection('spare_parts')
                                .doc(part.partCode)
                                .delete();

                            if (context.mounted) {
                              Navigator.pop(context, true); // 🔥 auto refresh
                            }
                          },
                        ),
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

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================
// IMAGE (SAME VISUAL AS EDIT)
// =========================
class _DetailImage extends StatelessWidget {
  final String imageUrl;

  const _DetailImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          color: const Color.fromARGB(255, 243, 228, 172),
          child: AspectRatio(
            aspectRatio: 1,
            child: imageUrl.isNotEmpty
                ? Image.network(imageUrl, fit: BoxFit.contain)
                : const Icon(Icons.inventory, size: 48),
          ),
        ),
      ),
    );
  }
}
