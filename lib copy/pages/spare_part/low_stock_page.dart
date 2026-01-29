import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/spare_part.dart';
import '../spare_part/edit_spare_part_page.dart';

class LowStockPage extends StatelessWidget {
  const LowStockPage({super.key});

  // ================= HEADER (GLASS MERAH) =================
  Widget _buildLowStockHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.blueGrey),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Low Stock Parts',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ===== BACKGROUND GRADIENT (KONSISTEN) =====
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFCDD2), // merah lembut
                  Color(0xFFFFFFFF),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildLowStockHeader(context),

                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('spare_parts')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (!snapshot.hasData ||
                          snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text('Tidak ada spare part'),
                        );
                      }

                      final lowStockDocs =
                          snapshot.data!.docs.where((doc) {
                        final data =
                            doc.data() as Map<String, dynamic>;

                        final int currentStock =
                            (data['currentStock'] ?? 0) as int;
                        final int minimumStock =
                            (data['minimumStock'] ?? 0) as int;

                        return currentStock < minimumStock;
                      }).toList();

                      if (lowStockDocs.isEmpty) {
                        return const Center(
                          child: Text(
                            'Tidak ada spare part dengan status low stock',
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: lowStockDocs.length,
                        itemBuilder: (context, index) {
                          final doc = lowStockDocs[index];
                          final data =
                              doc.data() as Map<String, dynamic>;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: ListTile(
                              leading: const Icon(
                                Icons.warning,
                                color: Colors.redAccent,
                              ),

                              title: Text(
                                data['partCode'] ?? '-',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              subtitle: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(data['nameEn'] ?? ''),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Stock: ${data['currentStock']} / Min: ${data['minimumStock']}',
                                    style:
                                        const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),

                              // ✅ TAP → EDIT SPARE PART
                             onTap: () {
  final data = doc.data() as Map<String, dynamic>;

  final part = SparePart(
    id: doc.id,
    partCode: data['partCode'] ?? '',
    name: data['name'] ?? '',
    nameEn: data['nameEn'] ?? '',
    location: data['location'] ?? '',
    stock: data['stock'] ?? 0,
    initialStock: data['initialStock'] ?? 0,
    currentStock: data['currentStock'] ?? 0,
    minimumStock: data['minimumStock'] ?? 0,
    weight: (data['weight'] ?? 0).toDouble(),
    weightUnit: data['weightUnit'] ?? 'pcs',
    imageUrl: data['imageUrl'] ?? '',
  );

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => EditSparePartPage(
        part: part, // ✅ SESUAI
      ),
    ),
  );
},

                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
