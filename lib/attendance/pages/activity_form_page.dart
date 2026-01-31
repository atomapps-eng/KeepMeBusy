import 'package:flutter/material.dart';
import '../../pages/common/app_background_wrapper.dart';

class ActivityEntry {
  final DateTime date;
  final String factoryClient;
  final String machine;
  final String serialNumber;
  final String activityType;
  final String description;
  final String status;
  final String note;

  ActivityEntry({
    required this.date,
    required this.factoryClient,
    required this.machine,
    required this.serialNumber,
    required this.activityType,
    required this.description,
    required this.status,
    required this.note,
  });
}

class ActivityFormPage extends StatefulWidget {
  final DateTime attendanceDate;      // ✅ dari attendance
  final String factoryClientName;     // ✅ NAMA customer

  const ActivityFormPage({
    super.key,
    required this.attendanceDate,
    required this.factoryClientName,
  });

  @override
  State<ActivityFormPage> createState() => _ActivityFormPageState();
}

class _ActivityFormPageState extends State<ActivityFormPage> {
  late DateTime date; // ✅ langsung terisi

  String activityType = 'service';
  String status = 'paid';

  final machineCtrl = TextEditingController();
  final serialCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // ✅ FIX POINT 1
    date = widget.attendanceDate;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add Activity'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        extendBodyBehindAppBar: true,
        body: AppBackgroundWrapper(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ================= DATE =================
                ListTile(
                  title: Text(
                    date.toString().split(' ').first,
                  ),
                  trailing: const Icon(Icons.date_range),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      initialDate: date,
                    );
                    if (picked != null) {
                      setState(() {
                        date = picked;
                      });
                    }
                  },
                ),

                // ================= FACTORY / CLIENT (NAME) =================
                TextFormField(
                  initialValue: widget.factoryClientName,
                  readOnly: true,
                ),
                const SizedBox(height: 16),

                _field(machineCtrl, 'Machine'),
const SizedBox(height: 12),

_field(serialCtrl, 'Serial Number'),
const SizedBox(height: 16),

DropdownButtonFormField<String>(
  value: activityType,
  decoration: const InputDecoration(labelText: 'Activity'),
  items: const [
    'service',
    'maintenance',
    'remote',
    'installation',
    'training',
    'general visit',
    'meeting',
  ]
      .map(
        (e) => DropdownMenuItem(value: e, child: Text(e)),
      )
      .toList(),
  onChanged: (v) => setState(() => activityType = v!),
),

const SizedBox(height: 16),

_field(descCtrl, 'Activity Description', lines: 2),
const SizedBox(height: 16),

DropdownButtonFormField<String>(
  value: status,
  decoration: const InputDecoration(labelText: 'Status'),
  items: const [
    DropdownMenuItem(value: 'paid', child: Text('Paid')),
    DropdownMenuItem(value: 'warranty', child: Text('Warranty')),
  ],
  onChanged: (v) => setState(() => status = v!),
),

const SizedBox(height: 16),

_field(noteCtrl, 'Note', lines: 2),

                const Spacer(),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        child: const Text('Save Activity'),
                        onPressed: () {
                          Navigator.pop(
                            context,
                            ActivityEntry(
                              date: date,
                              factoryClient:
                                  widget.factoryClientName, // ✅ NAME
                              machine: machineCtrl.text,
                              serialNumber: serialCtrl.text,
                              activityType: activityType,
                              description: descCtrl.text,
                              status: status,
                              note: noteCtrl.text,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    int lines = 1,
  }) {
    return TextField(
      controller: c,
      maxLines: lines,
      decoration: InputDecoration(labelText: label),
    );
  }
}
