import 'package:flutter/material.dart';

class OvernightSummary extends StatelessWidget {
  final int nights;

  const OvernightSummary({
    super.key,
    required this.nights,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withValues(alpha:0.1),
            Colors.purple.withValues(alpha:0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.purple.withValues(alpha:0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha:0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.nights_stay,
              color: Colors.purple.shade700,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Nights',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              Text(
                nights.toString(),
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}