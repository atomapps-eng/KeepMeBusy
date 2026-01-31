import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/attendance_day.dart';
import '../services/attendance_period_helper.dart';
import 'activity_form_page.dart';
import '../../pages/common/app_background_wrapper.dart';

// ⬇️ TAMBAHAN (WAJIB)
import '../../services/partner_service.dart';
import '../../models/partner.dart';

class AttendanceInputPage extends StatefulWidget {
  final String employeeId;
  final DateTime date;
  final AttendanceDay? existingDay;
  final ActivityEntry? pendingActivity;

  const AttendanceInputPage({
    super.key,
    required this.employeeId,
    required this.date,
    this.existingDay,
    this.pendingActivity,
  });

  @override
  State<AttendanceInputPage> createState() => _AttendanceInputPageState();
}

class _AttendanceInputPageState extends State<AttendanceInputPage> {
  bool _isSaving = false;

  late DateTime _selectedDate;

  late AttendanceStatus status;
  AttendanceLocation? location;

  String? selectedCustomerId;
  String? selectedCustomerName;
  final noteController = TextEditingController();

  final List<ActivityEntry> activities = [];

  TimeOfDay checkIn = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay checkOut = const TimeOfDay(hour: 17, minute: 0);

  Future<bool> _showConfirmDialog({
  required String title,
  required String message,
  String confirmText = 'Yes',
  String cancelText = 'Cancel',
  Color confirmColor = Colors.red,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelText),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmText),
        ),
      ],
    ),
  );

  return result ?? false;
}

  @override
  void initState() {
    super.initState();

    _selectedDate = widget.date;

    status = widget.existingDay?.status ?? AttendanceStatus.off;

    if (status == AttendanceStatus.present) {
      location = widget.existingDay?.location;
    } else {
      location = null;
    }

    selectedCustomerId = widget.existingDay?.customerId;
    noteController.text = widget.existingDay?.note ?? '';

    if (widget.existingDay?.checkInHour != null) {
      checkIn = TimeOfDay(
        hour: widget.existingDay!.checkInHour!,
        minute: widget.existingDay!.checkInMinute ?? 0,
      );
    }

    if (widget.existingDay?.checkOutHour != null) {
      checkOut = TimeOfDay(
        hour: widget.existingDay!.checkOutHour!,
        minute: widget.existingDay!.checkOutMinute ?? 0,
      );
    }
     if (widget.existingDay != null) {
    _loadExistingActivities();
  }
  }

  bool get _isPresent => status == AttendanceStatus.present;
  bool get _isOutstation =>
      _isPresent && location == AttendanceLocation.outstation;

Future<void> _loadExistingActivities() async {
  final date = _selectedDate;
  final dateKey =
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  final snap = await FirebaseFirestore.instance
      .collection('attendance')
      .doc(widget.employeeId)
      .collection('days')
      .doc(dateKey)
      .collection('activities')
      .orderBy('createdAt')
      .get();

  final loaded = snap.docs.map((d) {
    final data = d.data();
    return ActivityEntry(
      date: (data['date'] as Timestamp).toDate(),
      factoryClient: data['factoryClient'],
      machine: data['machine'],
      serialNumber: data['serialNumber'],
      activityType: data['activityType'],
      description: data['description'],
      status: data['status'],
      note: data['note'],
    );
  }).toList();

  setState(() {
    activities.addAll(loaded);
  });
}

 Future<void> _deleteAttendance() async {
  final date = _selectedDate;
  final dateKey =
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  final dayRef = FirebaseFirestore.instance
      .collection('attendance')
      .doc(widget.employeeId)
      .collection('days')
      .doc(dateKey);

  // 1️⃣ Ambil semua activities
  final activitiesSnap =
      await dayRef.collection('activities').get();

  // 2️⃣ Hapus satu per satu activity
  for (final doc in activitiesSnap.docs) {
    await doc.reference.delete();
  }

  // 3️⃣ Hapus attendance day
  await dayRef.delete();

  if (!mounted) return;
  Navigator.pop(context);
}


  Future<void> _saveAttendance() async {
  if (_isSaving) return;

  setState(() => _isSaving = true);

  try {
    final date = _selectedDate;
    final period = AttendancePeriodHelper.resolvePeriod(date);

    final dateKey =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final Map<String, dynamic> attendanceData = {
      'employeeId': widget.employeeId,
      'date': date,
      'period': period,
      'status': status.name,
      'note': noteController.text,
      'approved': false,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (_isPresent) {
      attendanceData.addAll({
        'location': location?.name,
        'customerId': selectedCustomerId,
        'customerName': selectedCustomerName,
        'checkInHour': checkIn.hour,
        'checkInMinute': checkIn.minute,
        'checkOutHour': checkOut.hour,
        'checkOutMinute': checkOut.minute,
      });
    }

    await FirebaseFirestore.instance
        .collection('attendance')
        .doc(widget.employeeId)
        .collection('days')
        .doc(dateKey)
        .set(attendanceData, SetOptions(merge: true));

    for (final a in activities) {
      await FirebaseFirestore.instance
          .collection('attendance')
          .doc(widget.employeeId)
          .collection('days')
          .doc(dateKey)
          .collection('activities')
          .add({
        'date': a.date,
        'factoryClient': a.factoryClient,
        'machine': a.machine,
        'serialNumber': a.serialNumber,
        'activityType': a.activityType,
        'description': a.description,
        'status': a.status,
        'note': a.note,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    if (!mounted) return;
    Navigator.pop(context);
  } finally {
    if (mounted) {
      setState(() => _isSaving = false);
    }
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Attendance'),
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Attendance • ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<AttendanceStatus>(
                value: status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: AttendanceStatus.values
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s.name),
                        ))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    status = v!;
                    if (!_isPresent) {
                      location = null;
                      selectedCustomerId = null;
                      activities.clear();
                    }
                  });
                },
              ),

              if (_isPresent) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Office'),
                      selected: location == AttendanceLocation.office,
                      onSelected: (_) {
                        setState(() {
                          location = AttendanceLocation.office;
                          selectedCustomerId = null;
                          activities.clear();
                        });
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Outstation'),
                      selected: location == AttendanceLocation.outstation,
                      onSelected: (_) {
                        setState(() {
                          location = AttendanceLocation.outstation;
                        });
                      },
                    ),
                  ],
                ),
              ],

              if (_isOutstation) ...[
                const SizedBox(height: 12),
                StreamBuilder<List<Partner>>(
                  stream: PartnerService().getPartners(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const LinearProgressIndicator();
                    }

                    final partners = snapshot.data!;
                    return DropdownButtonFormField<String>(
                      value: selectedCustomerId,
                      decoration:
                          const InputDecoration(labelText: 'Customer / Client'),
                      items: partners
                          .map(
                            (p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(p.name),
                            ),
                          )
                          .toList(),
                      onChanged: (partnerId) {
  final partner = partners.firstWhere(
    (p) => p.id == partnerId,
  );

  setState(() {
    selectedCustomerId = partner.id;
    selectedCustomerName = partner.name;
  });
},

                    );
                  },
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.build),
                    label: const Text('Add Activity'),
                    onPressed: () async {
                      final result =
                          await Navigator.push<ActivityEntry>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ActivityFormPage(
  attendanceDate: _selectedDate,
  factoryClientName: selectedCustomerName!,
),

                        ),
                      );
                      if (result != null) {
  setState(() {
    activities.add(result);
  });
}

                    },
                  ),
                ),
              ],

// ================= CHECK IN / CHECK OUT =================
if (_isPresent) ...[
  const Divider(height: 24),
  Row(
    children: [
      Expanded(
        child: ListTile(
          title: const Text('Check In'),
          subtitle: Text(checkIn.format(context)),
          onTap: () async {
            final t = await showTimePicker(
              context: context,
              initialTime: checkIn,
            );
            if (t != null) {
              setState(() => checkIn = t);
            }
          },
        ),
      ),
      Expanded(
        child: ListTile(
          title: const Text('Check Out'),
          subtitle: Text(checkOut.format(context)),
          onTap: () async {
            final t = await showTimePicker(
              context: context,
              initialTime: checkOut,
            );
            if (t != null) {
              setState(() => checkOut = t);
            }
          },
        ),
      ),
    ],
  ),
],
Row(
  children: [
    if (widget.existingDay != null)
      Expanded(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          onPressed: () async {
  final confirm = await _showConfirmDialog(
    title: 'Delete Attendance',
    message:
        'Attendance dan seluruh activity pada tanggal ini akan DIHAPUS PERMANEN.\n\nLanjutkan?',
    confirmText: 'Delete',
    confirmColor: Colors.red,
  );

  if (confirm) {
    await _deleteAttendance();
  }
},

          child: const Text('Delete'),
        ),
      ),

    if (widget.existingDay != null)
      const SizedBox(width: 12),

   Expanded(
  child: ElevatedButton(
    onPressed: () async {
      final confirm = await _showConfirmDialog(
        title: 'Save Attendance',
        message: widget.existingDay != null
            ? 'Perubahan attendance akan disimpan.\n\nLanjutkan?'
            : 'Attendance baru akan dibuat.\n\nLanjutkan?',
        confirmText: 'Save',
        confirmColor: Colors.green,
      );

      if (confirm) {
        await _saveAttendance();
      }
    },
    child: const Text('Save Attendance'),
  ),
),

  ],
),
// ===== ACTIVITIES PREVIEW =====
if (_isOutstation && activities.isNotEmpty) ...[
  const Divider(height: 24),
  const Text(
    'Activities',
    style: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
    ),
  ),
  const SizedBox(height: 8),

  ...activities.map((a) {
    return ListTile(
      dense: true,
      title: Text(a.activityType),
      subtitle: Text('${a.factoryClient} • ${a.machine}'),
      trailing: const Icon(Icons.check, size: 16),
    );
  }),
],

              const Spacer(),              
            ],
          ),
        ),
      ),
    );
  }
}
