import 'package:flutter/material.dart';
import '../models/trip_expense_model.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

class ExpenseDetailPage extends StatelessWidget {
  final TripExpense expense;
  final String tripId;

  const ExpenseDetailPage({
    super.key,
    required this.expense,
    required this.tripId,
  });

  Future<void> downloadFile(String url) async {
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {

    final isPdf = expense.receiptUrl.contains(".pdf");

    return Scaffold(
      appBar: AppBar(
        title: const Text("Expense Detail"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              expense.category,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text("Amount: ${expense.amount} ${expense.currency}"),

            const SizedBox(height: 10),

            Text("Description: ${expense.description}"),

            const SizedBox(height: 20),

            if (expense.receiptUrl.isNotEmpty) ...[

              const Text(
                "Receipt",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              if (!isPdf)
                Image.network(
                  expense.receiptUrl,
                  height: 250,
                ),

              if (isPdf)
                const Icon(
                  Icons.picture_as_pdf,
                  size: 80,
                  color: Colors.red,
                ),

              const SizedBox(height: 20),

              ElevatedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text("Download Receipt"),
                onPressed: () {
                  downloadFile(expense.receiptUrl);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}