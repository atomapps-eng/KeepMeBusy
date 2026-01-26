import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LowStockPage extends StatelessWidget {
  const LowStockPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Low Stock Parts'),
        backgroundColor: Colors.redAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('spare_parts')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Terjadi kesalahan'));
          }

          final docs = snapshot.data?.docs ?? [];

          // ===============================
          // FILTER LOW STOCK
          // ===============================
          final lowStockParts = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;

            final int currentStock =
                (data['currentStock'] ?? 0) as int;
            final int minimumStock =
                (data['minimumStock'] ?? 0) as int;

            return currentStock <= minimumStock;
          }).toList();

          if (lowStockParts.isEmpty) {
            return const Center(
              child: Text('Tidak ada spare part low stock'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: lowStockParts.length,
            itemBuilder: (context, index) {
              final data =
                  lowStockParts[index].data() as Map<String, dynamic>;

              final String partCode = data['partCode'] ?? '-';
              final String nameEn = data['nameEn'] ?? '';
              final int currentStock = data['currentStock'] ?? 0;
              final int minimumStock = data['minimumStock'] ?? 0;

              return Card(
                color: Colors.red.shade50,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(
                    Icons.warning,
                    color: Colors.redAccent,
                  ),
                  title: Text(
                    partCode,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(nameEn),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Stock: $currentStock',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        'Min: $minimumStock',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
