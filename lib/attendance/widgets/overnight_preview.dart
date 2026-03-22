import 'package:flutter/material.dart';
import '../../models/partner.dart';

class OvernightPreview extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final int nights;
  final Partner? partner;
  final Color categoryColor;

  const OvernightPreview({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.nights,
    required this.partner,
    required this.categoryColor,
  });

  @override
  Widget build(BuildContext context) {
    if (startDate == null || endDate == null || partner == null) {
      return const Text('Select data to see preview');
    }

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        children: [
          Text(
            '${startDate!.day}/${startDate!.month} → ${endDate!.day}/${endDate!.month}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$nights nights',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            partner!.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}