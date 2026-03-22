import 'package:flutter/material.dart';

class OvernightDateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const OvernightDateField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha:0.1),
              color.withValues(alpha:0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha:0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 11, color: color),
                  ),
                  Text(
                    value == null
                        ? 'Select date'
                        : '${value!.day}/${value!.month}/${value!.year}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          value == null ? FontWeight.normal : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down, color: color),
          ],
        ),
      ),
    );
  }
}