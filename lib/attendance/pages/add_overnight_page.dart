import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/overnight_helper.dart';
import '../../pages/common/app_background_wrapper.dart';
import '../services/overnight_service.dart';
import '../models/overnight_entry.dart';
import '../../models/partner.dart';
import '../../pages/partners/partner_list_page.dart';
import 'dart:async';

class AddOvernightPage extends StatefulWidget {
  final String employeeId;
  final String period;
  final OvernightEntry? existingEntry;
  final String? docId;

  const AddOvernightPage({
    super.key,
    required this.employeeId,
    required this.period,
    this.existingEntry,
    this.docId,
  });

  @override
  State<AddOvernightPage> createState() => _AddOvernightPageState();
}

class _AddOvernightPageState extends State<AddOvernightPage> {
  DateTime? startDate;
  DateTime? endDate;

  String? selectedCustomerName;
  Partner? selectedPartner;

  bool isSaving = false;

  @override
  void initState() {
    super.initState();

    // JIKA MODE EDIT
    if (widget.existingEntry != null) {
      startDate = widget.existingEntry!.startDate;
      endDate = widget.existingEntry!.endDate;
      selectedCustomerName = widget.existingEntry!.customerName;
    }
  }

  Future<void> _save() async {
    // ===== VALIDASI =====
    if (startDate == null || endDate == null || selectedPartner == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all fields'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (endDate!.isBefore(startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End date cannot be before start date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ===== BUILD ENTRY =====
    final entry = OvernightEntry(
      id: widget.docId ?? '',
      startDate: startDate!,
      endDate: endDate!,
      totalNights: OvernightHelper.calculateTotalNights(
        startDate!,
        endDate!,
      ),
      customerName: selectedPartner!.name,
      customerCategory: selectedPartner!.category,
      period: widget.period,
    );

    setState(() => isSaving = true);

    // ===== ADD vs EDIT =====
    try {
      if (widget.docId == null) {
        // MODE ADD
        await OvernightService().addOvernight(
          employeeId: widget.employeeId,
          entry: entry,
        );
      } else {
        // MODE EDIT
        await OvernightService().updateOvernight(
          employeeId: widget.employeeId,
          docId: widget.docId!,
          entry: entry,
        );
      }

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.docId == null 
                ? 'Overnight added successfully' 
                : 'Overnight updated successfully'
          ),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => isSaving = false);
    }
  }

  int _calculateNights() {
    if (startDate == null || endDate == null) return 0;
    if (endDate!.isBefore(startDate!)) return 0;
    return OvernightHelper.calculateTotalNights(startDate!, endDate!);
  }

  String _getCategoryIcon(String? category) {
    if (category == null) return '🌍';
    return category.toLowerCase() == 'domestic' ? '🏠' : '✈️';
  }

  Color _getCategoryColor(String? category) {
    if (category == null) return Colors.grey;
    return category.toLowerCase() == 'domestic' ? Colors.teal : Colors.purple;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final categoryColor = _getCategoryColor(selectedPartner?.category);
    final nights = _calculateNights();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.withValues(alpha:0.2),
                    Colors.purple.withValues(alpha:0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.purple.withValues(alpha:0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.hotel,
                color: Colors.purple,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.existingEntry == null
                      ? 'Add Overnight'
                      : 'Edit Overnight',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.period,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.purple.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha:0.2),
                Colors.white.withValues(alpha:0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha:0.3)),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: AppBackgroundWrapper(
        padding: const EdgeInsets.all(16),
        child: isDesktop 
            ? _buildDesktopLayout(categoryColor, nights)
            : _buildMobileLayout(categoryColor, nights),
      ),
    );
  }

  Widget _buildDesktopLayout(Color categoryColor, int nights) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEFT SIDEBAR - FORM
        Container(
          width: 450,
          margin: const EdgeInsets.only(right: 16),
          child: _glass(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.withValues(alpha:0.2),
                            Colors.purple.withValues(alpha:0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        color: Colors.purple,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Overnight Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Start Date
                _buildDesktopDateField(
                  label: 'Start Date',
                  value: startDate,
                  icon: Icons.calendar_today,
                  color: Colors.blue,
                  onTap: () async {
                    final d = await showDatePickerOverlay(
  context: context,
  initialDate: startDate ?? DateTime.now(),
);
                    if (d != null) setState(() => startDate = d);
                  },
                ),

                const SizedBox(height: 12),

                // End Date
                _buildDesktopDateField(
                  label: 'End Date',
                  value: endDate,
                  icon: Icons.calendar_month,
                  color: Colors.orange,
                  onTap: () async {
                   final d = await showDatePickerOverlay(
  context: context,
  initialDate: endDate ?? DateTime.now(),
);
                    if (d != null) setState(() => endDate = d);
                  },
                ),

                const SizedBox(height: 16),

                // Customer Selection
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        categoryColor.withValues(alpha:0.1),
                        categoryColor.withValues(alpha:0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: categoryColor.withValues(alpha:0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.business, size: 16, color: categoryColor),
                          const SizedBox(width: 8),
                          Text(
                            'Customer',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: categoryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final partner = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PartnerListPage(
                                selectionMode: true,
                              ),
                            ),
                          );

                          if (partner != null && partner is Partner) {
                            setState(() {
                              selectedPartner = partner;
                              selectedCustomerName = partner.name;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha:0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: categoryColor.withValues(alpha:0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (selectedPartner != null) ...[
                                      Text(
                                        selectedPartner!.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            _getCategoryIcon(selectedPartner!.category),
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            selectedPartner!.category,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: categoryColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ] else
                                      const Text(
                                        'Select Customer',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color.fromARGB(255, 197, 234, 150),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 14,
                                color: categoryColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Summary
                Container(
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
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha:0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.nights_stay,
                          color: Colors.purple.shade700,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Nights',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              nights.toString(),
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey.shade400),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: isSaving ? null : _save,
                        child: isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Save Overnight'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // RIGHT CONTENT - PREVIEW
        Expanded(
          child: _glass(
  SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.withValues(alpha:0.2),
                            Colors.purple.withValues(alpha:0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.visibility,
                        color: Colors.purple,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Preview',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Expanded(
                  child: Center(
                    child: Container(
                      width: 320,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.withValues(alpha:0.1),
                            Colors.purple.withValues(alpha:0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.purple.withValues(alpha:0.3),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.purple.withValues(alpha:0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.hotel,
                              size: 48,
                              color: Colors.purple.shade700,
                            ),
                          ),
                          const SizedBox(height: 20),

                          if (startDate != null && endDate != null) ...[
                            Text(
                              '${startDate!.day}/${startDate!.month}/${startDate!.year}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Icon(
                              Icons.arrow_downward,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${endDate!.day}/${endDate!.month}/${endDate!.year}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.purple.withValues(alpha:0.2),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                '$nights nights',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple.shade700,
                                ),
                              ),
                            ),
                          ] else
                            const Text(
                              'Select dates to see preview',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),

                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),

                          if (selectedPartner != null) ...[
                            Text(
                              selectedPartner!.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: categoryColor.withValues(alpha:0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                selectedPartner!.category,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: categoryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ] else
                            const Text(
                              'Select a customer',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(Color categoryColor, int nights) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Form Card
          _glass(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.withValues(alpha:0.2),
                            Colors.purple.withValues(alpha:0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        color: Colors.purple,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Overnight Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Start Date
                _buildMobileDateField(
                  label: 'Start Date',
                  value: startDate,
                  icon: Icons.calendar_today,
                  color: Colors.blue,
                  onTap: () async {
                    final d = await showDialog<DateTime>(
  context: context,
  useRootNavigator: true,
  barrierDismissible: true,
  builder: (context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 400,
          child: DatePickerDialog(
            initialDate: startDate ?? DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2035),
          ),
        ),
      ),
    );
  },
);
                    if (d != null) setState(() => startDate = d);
                  },
                ),

                const SizedBox(height: 12),

                // End Date
                _buildMobileDateField(
                  label: 'End Date',
                  value: endDate,
                  icon: Icons.calendar_month,
                  color: Colors.orange,
                  onTap: () async {
                    final d = await showDialog<DateTime>(
  context: context,
  useRootNavigator: true,
  barrierDismissible: true,
  builder: (context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 400,
          child: DatePickerDialog(
            initialDate: endDate ?? DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2035),
          ),
        ),
      ),
    );
  },
);
                    if (d != null) setState(() => endDate = d);
                  },
                ),

                const SizedBox(height: 16),

                // Customer Selection
InkWell(
  onTap: () async {
    final partner = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PartnerListPage(
          selectionMode: true,
        ),
      ),
    );

    if (partner != null && partner is Partner) {
      setState(() {
        selectedPartner = partner;
        selectedCustomerName = partner.name;
      });
    }
  },
  child: Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          categoryColor.withValues(alpha:0.15),
          categoryColor.withValues(alpha:0.08),
        ],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: categoryColor.withValues(alpha:0.4),
      ),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: categoryColor.withValues(alpha:0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.business,
            color: categoryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customer',
                style: TextStyle(
                  fontSize: 11,
                  color: categoryColor.withValues(alpha:0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                selectedPartner?.name ?? 'Select Customer',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selectedPartner != null
                      ? FontWeight.w600
                      : FontWeight.w500,
                  color: selectedPartner != null
                      ? categoryColor
                      : categoryColor.withValues(alpha:0.7),
                ),
              ),
              if (selectedPartner != null) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      _getCategoryIcon(selectedPartner!.category),
                      style: const TextStyle(fontSize: 11),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      selectedPartner!.category,
                      style: TextStyle(
                        fontSize: 11,
                        color: categoryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: categoryColor,
        ),
      ],
    ),
  ),
),

                const SizedBox(height: 20),

                // Nights Summary
                Container(
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Nights',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
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
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Action Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha:0.2),
                  Colors.white.withValues(alpha:0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha:0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey.shade400),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: isSaving ? null : _save,
                    child: isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save'),
                  ),
                ),
              ],
            ),
          ),

          // Preview Card (Mobile)
          if (startDate != null && endDate != null && selectedPartner != null) ...[
            const SizedBox(height: 16),
            _glass(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.purple.withValues(alpha:0.2),
                              Colors.purple.withValues(alpha:0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.visibility,
                          color: Colors.purple,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Preview',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Container(
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                const Text(
                                  'From',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${startDate!.day}/${startDate!.month}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.purple.withValues(alpha:0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_forward,
                                size: 16,
                                color: Colors.purple,
                              ),
                            ),
                            Column(
                              children: [
                                const Text(
                                  'To',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${endDate!.day}/${endDate!.month}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              selectedPartner!.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: categoryColor.withValues(alpha:0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$nights nights',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: categoryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<DateTime?> showDatePickerOverlay({
  required BuildContext context,
  required DateTime initialDate,
}) async {
  final overlay = Overlay.of(context, rootOverlay: true);
  late OverlayEntry entry;

  DateTime? selectedDate;

  entry = OverlayEntry(
    builder: (context) {
      return Positioned.fill(
        child: Material(
          color: Colors.black.withOpacity(0.3),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 400,
                maxHeight: 500,
              ),
              child: Material(
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: DatePickerDialog(
                  initialDate: initialDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                  onDatePickerModeChange: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  overlay.insert(entry);

  // 🔥 Tunggu user pilih dari Navigator root
  final result = await Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder(
      opaque: false,
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    ),
  );

  entry.remove();

  return result as DateTime?;
}

  Widget _buildDesktopDateField({
    required String label,
    required DateTime? value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
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
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha:0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value == null
                        ? 'Select date'
                        : '${value.day}/${value.month}/${value.year}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: value == null ? FontWeight.normal : FontWeight.w600,
                      color: value == null ? Colors.grey : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: color,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileDateField({
    required String label,
    required DateTime? value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha:0.1),
              color.withValues(alpha:0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
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
                    style: TextStyle(
                      fontSize: 11,
                      color: color,
                    ),
                  ),
                  Text(
                    value == null
                        ? 'Select date'
                        : '${value.day}/${value.month}/${value.year}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: value == null ? FontWeight.normal : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: color,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// =======================================================
// UI HELPERS
// =======================================================
Widget _glass(Widget child) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha:0.3),
              Colors.white.withValues(alpha:0.15),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha:0.4)),
        ),
        child: child,
      ),
    ),
  );
}