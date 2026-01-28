import 'package:flutter/material.dart';
import '../../models/spare_part.dart';

class SparePartDetailPage extends StatelessWidget {
  final SparePart part;

  const SparePartDetailPage({super.key, required this.part});

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

                  const SizedBox(height: 16),

                  // ===== IMAGE =====
                  if (part.imageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        part.imageUrl,
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.contain,
                      ),
                    ),

                  const SizedBox(height: 20),

                  // ===== BASIC INFO =====
                  _infoRow('Part Code', part.partCode),
                  _infoRow('Name', part.name),
                  _infoRow('Name (EN)', part.nameEn),
                  _infoRow('Location', part.location),

                  const Divider(height: 32),

                  // ===== STOCK INFO =====
                  _infoRow('Initial Stock', part.initialStock.toString()),
                  _infoRow('Current Stock', part.currentStock.toString()),
                  _infoRow('Minimum Stock', part.minimumStock.toString()),

                  const Divider(height: 32),

                  // ===== CATEGORY & ORIGIN (INI YANG ANDA MINTA) =====
                  _infoRow(
                    'Category',
                    part.category.name.replaceAll('_', ' '),
                  ),
                  _infoRow(
                    'Origin',
                    part.origin.name.replaceAll('_', ' '),
                  ),

                  const Divider(height: 32),

                  // ===== WEIGHT =====
                  _infoRow(
                    'Weight',
                    '${part.weight} ${part.weightUnit}',
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
