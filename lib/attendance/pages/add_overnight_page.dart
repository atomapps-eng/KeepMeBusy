import 'package:flutter/material.dart';
import '../services/overnight_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../pages/common/app_background_wrapper.dart';
import '../services/overnight_service.dart';
import '../models/overnight_entry.dart';
import '../../services/partner_service.dart';
import '../../models/partner.dart';

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
    selectedCustomerName =
        widget.existingEntry!.customerName;
  }
}


Future<void> _save() async {
  // ===== VALIDASI =====
  if (startDate == null ||
      endDate == null ||
      selectedPartner == null) {
    return;
  }

  if (endDate!.isBefore(startDate!)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('End date cannot be before start date'),
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
  Navigator.pop(context);
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Overnight'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: AppBackgroundWrapper(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _datePicker(
                label: 'Start Date',
                value: startDate,
                onPick: (d) => setState(() => startDate = d),
              ),
              const SizedBox(height: 12),
              _datePicker(
                label: 'End Date',
                value: endDate,
                onPick: (d) => setState(() => endDate = d),
              ),
              const SizedBox(height: 12),

              /// ===== CUSTOMER DROPDOWN (FINAL, AMAN) =====
              StreamBuilder<List<Partner>>(
                stream: PartnerService().getPartners(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const LinearProgressIndicator();
                  }

                  final partners = snapshot.data!;

                  return DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration:
                        const InputDecoration(labelText: 'Customer'),
                    initialValue: selectedCustomerName,
                    items: partners.map((p) {
                      return DropdownMenuItem<String>(
                        value: p.name,
                        child: Text(
                          '${p.name} (${p.category})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (v) {
                      final partner =
                          partners.firstWhere((p) => p.name == v);
                      setState(() {
                        selectedCustomerName = v;
                        selectedPartner = partner;
                      });
                    },
                  );
                },
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSaving ? null : _save,
                  child: isSaving
                      ? const CircularProgressIndicator()
                      : const Text('Save Overnight'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _datePicker({
    required String label,
    required DateTime? value,
    required Function(DateTime) onPick,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(
        value == null
            ? '-'
            : '${value.day}/${value.month}/${value.year}',
      ),
      trailing: const Icon(Icons.date_range),
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2035),
        );
        if (d != null) onPick(d);
      },
    );
  }
}
