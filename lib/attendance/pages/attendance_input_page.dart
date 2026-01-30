import 'package:flutter/material.dart';
import '../models/attendance_day.dart';
import '../services/attendance_period_helper.dart';
import '../services/attendance_service.dart';


class AttendanceInputPage extends StatefulWidget {
  final String employeeId;
  final DateTime date;
  final AttendanceDay? existingDay;


  const AttendanceInputPage({
  super.key,
  required this.employeeId,
  required this.date,
  this.existingDay,
});


  @override
  State<AttendanceInputPage> createState() => _AttendanceInputPageState();
}

class _AttendanceInputPageState extends State<AttendanceInputPage> {
  AttendanceStatus _status = AttendanceStatus.present;
  AttendanceLocation _location = AttendanceLocation.office;
  final TextEditingController _noteController = TextEditingController();
  bool _overnightEnabled = false;
final TextEditingController _customerController =
    TextEditingController();
final TextEditingController _overnightCustomerController =
    TextEditingController();


  @override
void initState() {
  super.initState();

  final existing = widget.existingDay;
  if (existing != null) {
    _status = existing.status;
    _location = existing.location;
    _noteController.text = existing.note ?? '';
    _overnightEnabled = existing.overnightEnabled;
_customerController.text = existing.customerId ?? '';
_overnightCustomerController.text =
    existing.overnightCustomerId ?? '';

  }
}


  @override
  void dispose() {
    _noteController.dispose();
    _customerController.dispose();
    _overnightCustomerController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final period =
        AttendancePeriodHelper.resolvePeriod(widget.date);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Attendance'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // =====================
            // DATE
            // =====================
            ListTile(
              title: const Text('Date'),
              subtitle: Text(
                '${widget.date.day}-${widget.date.month}-${widget.date.year}',
              ),
            ),

            const Divider(),

            // =====================
            // STATUS
            // =====================
            DropdownButtonFormField<AttendanceStatus>(
              value: _status,
              decoration: const InputDecoration(
                labelText: 'Status',
              ),
              items: AttendanceStatus.values.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(status.name),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _status = value);
                }
              },
            ),

            const SizedBox(height: 16),

            // =====================
            // LOCATION
            // =====================
            DropdownButtonFormField<AttendanceLocation>(
              value: _location,
              decoration: const InputDecoration(
                labelText: 'Location',
              ),
              items: AttendanceLocation.values.map((loc) {
                return DropdownMenuItem(
                  value: loc,
                  child: Text(loc.name),
                );
              }).toList(),
              onChanged: (value) {
  if (value == null) return;

  setState(() {
    _location = value;

    if (_location == AttendanceLocation.office) {
      _overnightEnabled = false;
      _customerController.clear();
      _overnightCustomerController.clear();
    }
  });
},

            ),

            if (_location == AttendanceLocation.outstation) ...[
  const SizedBox(height: 16),

  TextFormField(
    controller: _customerController,
    decoration: const InputDecoration(
      labelText: 'Customer (Outstation)',
    ),
  ),

  const SizedBox(height: 16),

  SwitchListTile(
    title: const Text('Overnight'),
    value: _overnightEnabled,
    onChanged: (value) {
      setState(() => _overnightEnabled = value);
    },
  ),

  if (_overnightEnabled) ...[
    const SizedBox(height: 16),

    TextFormField(
      controller: _overnightCustomerController,
      decoration: const InputDecoration(
        labelText: 'Overnight Customer',
      ),
    ),
  ],
],


            const SizedBox(height: 16),

            // =====================
            // NOTE
            // =====================
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note',
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 32),

            // =====================
            // SAVE (DISABLED)
            // =====================
            ElevatedButton(
  onPressed: () async {
    final service = AttendanceService();

    final dayId =
        '${widget.date.year}-${widget.date.month.toString().padLeft(2, '0')}-${widget.date.day.toString().padLeft(2, '0')}';

    final attendanceDay = AttendanceDay(
      id: dayId,
      employeeId: widget.employeeId,
      date: widget.date,
      period: period,
      status: _status,
      location: _location,
      note: _noteController.text.trim(),
      customerId: _location == AttendanceLocation.outstation
    ? _customerController.text.trim()
    : null,

overnightEnabled:
    _location == AttendanceLocation.outstation &&
        _overnightEnabled,

overnightCustomerId:
    _overnightEnabled
        ? _overnightCustomerController.text.trim()
        : null,

    );

    await service.saveAttendanceDay(attendanceDay);

    if (!mounted) return;
    Navigator.pop(context);
  },
  child: Text(
    'Save (Period $period)',
  ),
),

          ],
        ),
      ),
    );
  }
}
