import 'package:flutter/material.dart';
import '../services/service_report_firestore.dart';
import '../../core/session/company_session.dart';

class ServiceReportFormPage extends StatefulWidget {
  const ServiceReportFormPage({super.key});

  @override
  State<ServiceReportFormPage> createState() =>
      _ServiceReportFormPageState();
}

class _ServiceReportFormPageState
    extends State<ServiceReportFormPage> {
  // BASIC
  DateTime? startDate;
  DateTime? endDate;
  String? factory;
  String? endCustomer;
  final customerCodeController = TextEditingController();

  // MACHINE
  final machineController = TextEditingController();
  final serialController = TextEditingController();
  final assetController = TextEditingController();

  // DESCRIPTION
  final problemController = TextEditingController();
  final activityController = TextEditingController();
  final noteController = TextEditingController();

  // TECHNICIAN
  String? tech1;
  String? tech2;
  String? tech3;

  // CUSTOMER
  final customerNameController = TextEditingController();

  // SPARE PART
  List<Map<String, dynamic>> spareParts = [];

  // DUMMY DATA
  final partners = ["PT ORISOL", "PT POUCHEN", "PT ATOM"];
  final technicians = ["Basuki", "Agus", "Rudi"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(title: const Text("Service Report Form")),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 900;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _card(_basicInfo(isDesktop)),
                const SizedBox(height: 20),
                _card(_machineSection(isDesktop)),
                const SizedBox(height: 20),
                _card(_descriptionSection()),
                const SizedBox(height: 20),
                _card(_sparePartSection()),
                const SizedBox(height: 20),
                _card(_noteSection()),
                const SizedBox(height: 20),
                _card(_technicianSection()),
                const SizedBox(height: 20),
                _card(_signatureSection()),
                const SizedBox(height: 20),
                _card(_mediaSection()),
                const SizedBox(height: 30),
                _actionButtons(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _card(Widget child) {
    return Card(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    );
  }

  // ================= BASIC INFO =================

  Widget _basicInfo(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("BASIC INFORMATION",
            style:
                TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        isDesktop
            ? Row(
                children: [
                  Expanded(child: _datePicker("Start Date", true)),
                  const SizedBox(width: 16),
                  Expanded(child: _datePicker("End Date", false)),
                ],
              )
            : Column(
                children: [
                  _datePicker("Start Date", true),
                  _datePicker("End Date", false),
                ],
              ),
        const SizedBox(height: 16),
        DropdownButtonFormField(
          value: factory,
          items: partners
              .map((e) =>
                  DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (val) => setState(() => factory = val),
          decoration: const InputDecoration(labelText: "Factory"),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField(
          value: endCustomer,
          items: partners
              .map((e) =>
                  DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (val) =>
              setState(() => endCustomer = val),
          decoration:
              const InputDecoration(labelText: "End Customer"),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: customerCodeController,
          decoration:
              const InputDecoration(labelText: "Customer Code"),
        ),
      ],
    );
  }

  Widget _datePicker(String label, bool isStart) {
    return TextButton(
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
          initialDate: DateTime.now(),
        );
        if (picked != null) {
          setState(() {
            if (isStart) {
              startDate = picked;
            } else {
              endDate = picked;
            }
          });
        }
      },
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          "$label: ${isStart ? startDate ?? '-' : endDate ?? '-'}",
        ),
      ),
    );
  }

  // ================= MACHINE =================

  Widget _machineSection(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("MACHINE INFORMATION",
            style:
                TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        TextField(
          controller: machineController,
          decoration:
              const InputDecoration(labelText: "Machine"),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: serialController,
          decoration:
              const InputDecoration(labelText: "Serial Number"),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: assetController,
          decoration:
              const InputDecoration(labelText: "Asset Number"),
        ),
      ],
    );
  }

  // ================= DESCRIPTION =================

  Widget _descriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("PROBLEM DESCRIPTION",
            style:
                TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        TextField(
          controller: problemController,
          maxLines: 4,
        ),
        const SizedBox(height: 16),
        const Text("ACTIVITY",
            style:
                TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        TextField(
          controller: activityController,
          maxLines: 4,
        ),
      ],
    );
  }

  // ================= SPARE PART =================

  Widget _sparePartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("SPARE PART DURING SERVICE",
            style:
                TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _addSparePartDialog,
          child: const Text("+ Add Spare Part"),
        ),
        const SizedBox(height: 16),
        ...spareParts.map((part) => ListTile(
              title: Text(part["name"]),
              subtitle:
                  Text("Qty: ${part["qty"]}"),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  setState(() {
                    spareParts.remove(part);
                  });
                },
              ),
            ))
      ],
    );
  }

  void _addSparePartDialog() {
    final qtyController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Spare Part"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("RAM Module"),
            TextField(
              controller: qtyController,
              decoration:
                  const InputDecoration(labelText: "Qty"),
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                spareParts.add({
                  "name": "RAM Module",
                  "qty": qtyController.text
                });
              });
              Navigator.pop(context);
            },
            child: const Text("Add"),
          )
        ],
      ),
    );
  }

  // ================= TECHNICIAN =================

  Widget _technicianSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("TECHNICIANS",
            style:
                TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        DropdownButtonFormField(
          value: tech1,
          items: technicians
              .map((e) =>
                  DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (val) =>
              setState(() => tech1 = val),
          decoration:
              const InputDecoration(labelText: "Technician 1"),
        ),
        if (tech1 != null) ...[
          const SizedBox(height: 16),
          DropdownButtonFormField(
            value: tech2,
            items: technicians
                .map((e) =>
                    DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (val) =>
                setState(() => tech2 = val),
            decoration: const InputDecoration(
                labelText: "Technician 2"),
          ),
        ],
        if (tech2 != null) ...[
          const SizedBox(height: 16),
          DropdownButtonFormField(
            value: tech3,
            items: technicians
                .map((e) =>
                    DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (val) =>
                setState(() => tech3 = val),
            decoration: const InputDecoration(
                labelText: "Technician 3"),
          ),
        ],
      ],
    );
  }

  // ================= SIGNATURE =================

  Widget _signatureSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text("CUSTOMER SIGNATURE",
            style:
                TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        SizedBox(height: 12),
        SizedBox(
          height: 150,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.fromBorderSide(
                  BorderSide(color: Colors.grey)),
            ),
            child: Center(child: Text("Signature Area")),
          ),
        )
      ],
    );
  }

  // ================= MEDIA =================

  Widget _mediaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("MEDIA",
            style:
                TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: List.generate(
              4,
              (index) => Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                        border: Border.all(
                            color: Colors.grey)),
                    child: const Icon(Icons.camera_alt),
                  )),
        )
      ],
    );
  }

  // ================= ACTION =================

  Widget _actionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton(
            onPressed: _saveDraft,
            child: const Text("Save Draft")),
        const SizedBox(width: 16),
        ElevatedButton(
            onPressed: () {},
            child: const Text("Submit")),
      ],
    );
  }
  Widget _noteSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "NOTE FOR CUSTOMER",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: noteController,
        maxLines: 4,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: "Write note for customer...",
        ),
      ),
    ],
  );
}
Future<void> _saveDraft() async {
  print("Selected company: ${CompanySession.selectedCompanyId}");
  try {
    await ServiceReportFirestore.createServiceReport(
      data: {
        "startDate": startDate,
        "endDate": endDate,
        "factory": factory,
        "endCustomer": endCustomer,
        "customerCode": customerCodeController.text,
        "machine": machineController.text,
        "serialNumber": serialController.text,
        "assetNumber": assetController.text,
        "problemDescription": problemController.text,
        "activity": activityController.text,
        "spareParts": spareParts,
        "technicians": [tech1, tech2, tech3]
            .where((e) => e != null)
            .toList(),
        "note": noteController.text,
        "customerName": customerNameController.text,
      },
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Draft Saved")),
    );

    Navigator.pop(context);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: $e")),
    );
  }
}
}