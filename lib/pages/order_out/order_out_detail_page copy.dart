import 'package:flutter/material.dart';

class OrderOutDetailPage extends StatelessWidget {
  const OrderOutDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Out Detail'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER CARD
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'ORDER OUT NUMBER',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // INFO SECTION
            const Text('Date : -'),
            const Text('Location : -'),
            const Text('Client : -'),
            const Text('Status : -'),

            const SizedBox(height: 16),
            const Divider(),

            // ITEM LIST PLACEHOLDER
            const Text(
              'Items',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            ListTile(
              title: const Text('SPARE PART NAME'),
              subtitle: const Text('Location: -'),
              trailing: const Text('Qty: 0'),
            ),

            const SizedBox(height: 16),
            const Divider(),

            // SUMMARY
            const Text(
              'Summary',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Total Item : 0'),
            const Text('Total Qty : 0'),

            const SizedBox(height: 24),

            // ACTION BUTTON PLACEHOLDER
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    child: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
