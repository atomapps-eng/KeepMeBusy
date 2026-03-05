import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/company_firestore.dart';
import '../models/attendance_day.dart';
import '../services/attendance_period_helper.dart';
import 'activity_form_page.dart';
import '../../pages/common/app_background_wrapper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/session/company_session.dart';
import '../../services/partner_service.dart';
import '../../models/partner.dart';
import '../models/activity_entry.dart';
import '../models/factory_visit.dart';
import '../../pages/partners/partner_list_page.dart';
import '../../theme/app_theme.dart';

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

  final List<FactoryVisit> factories = [];

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

    final dayRef = CompanyFirestore
        .collection('attendance')
        .doc(widget.employeeId)
        .collection('days')
        .doc(dateKey);

    final factorySnap = await dayRef.collection('factories').get();

    for (final factoryDoc in factorySnap.docs) {
      final factoryId = factoryDoc.id;
      final factoryName = factoryDoc['factoryName'] ?? '';

      final actSnap = await factoryDoc.reference
          .collection('activities')
          .orderBy('createdAt')
          .get();

      for (final actDoc in actSnap.docs) {
        final data = actDoc.data();
        final activity = ActivityEntry(
          date: (data['date'] as Timestamp).toDate(),
          factoryId: factoryId,
          factoryClient: data['factoryClient'] ?? factoryName,
          customerId: data['customerId'] ?? '',
          machine: data['machine'] ?? '',
          serialNumber: data['serialNumber'] ?? '',
          activityType: data['activityType'] ?? '',
          description: data['description'] ?? '',
          status: data['status'] ?? '',
          note: data['note'] ?? '',
        );

        _addActivity(activity);
      }
    }

    setState(() {});
  }

  Future<void> _deleteAttendance() async {
    final date = _selectedDate;
    final dateKey =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final dayRef = CompanyFirestore
        .collection('attendance')
        .doc(widget.employeeId)
        .collection('days')
        .doc(dateKey);

    // 1️⃣ Ambil semua activities
    final factorySnap = await dayRef.collection('factories').get();

    for (final f in factorySnap.docs) {
      final actSnap = await f.reference.collection('activities').get();

      for (final a in actSnap.docs) {
        await a.reference.delete();
      }

      await f.reference.delete();
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

      final companyId = CompanySession.selectedCompanyId;

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

      final dayRef = CompanyFirestore
          .collection('attendance')
          .doc(widget.employeeId)
          .collection('days')
          .doc(dateKey);

      // 🔹 Save attendance
      await dayRef.set(attendanceData, SetOptions(merge: true));

      // 🔹 Hapus activities lama supaya tidak duplicate saat edit
      final factorySnap = await dayRef.collection('factories').get();

      for (final f in factorySnap.docs) {
        final actSnap = await f.reference.collection('activities').get();

        for (final a in actSnap.docs) {
          await a.reference.delete();
        }

        await f.reference.delete();
      }

      // 🔹 Save activities baru
      for (final factory in factories) {
        final factoryRef = dayRef
            .collection('factories')
            .doc(factory.factoryId);

        await factoryRef.set({
          'factoryId': factory.factoryId,
          'factoryName': factory.factoryName,
        });

        for (final a in factory.activities) {
          await factoryRef
              .collection('activities')
              .add({
            'companyId': companyId,
            'employeeId': widget.employeeId,
            'period': period,
            'createdBy': FirebaseAuth.instance.currentUser!.uid,
            'createdAt': FieldValue.serverTimestamp(),
            'customerId': a.customerId,
            'date': a.date,
            'factoryClient': a.factoryClient,
            'machine': a.machine,
            'serialNumber': a.serialNumber,
            'activityType': a.activityType,
            'description': a.description,
            'status': a.status,
            'note': a.note,
          });
        }
      }

      if (!mounted) return;
      Navigator.pop(context);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Colors.green;
      case AttendanceStatus.off:
        return Colors.grey;
      case AttendanceStatus.sickLeave:
        return Colors.orange;
      case AttendanceStatus.annualLeave:
        return Colors.blue;
      case AttendanceStatus.traveling:
        return Colors.purple;
      case AttendanceStatus.joinHoliday:
        return Colors.pink;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final statusColor = _getStatusColor(status);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _isPresent ? Icons.check_circle : Icons.calendar_today,
                color: statusColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.existingDay == null ? 'Add Attendance' : 'Edit Attendance',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
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
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
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
            ? _buildDesktopLayout(context, statusColor)
            : _buildMobileLayout(context, statusColor),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, Color statusColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEFT SIDEBAR - MAIN FORM
        Container(
          width: 400,
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
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.info_outline,
                        color: statusColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Attendance Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Status Dropdown
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Status',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<AttendanceStatus>(
                        value: status,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: AttendanceStatus.values
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(s),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(s.label),
                                    ],
                                  ),
                                ))
                            .toList(),
                        onChanged: (v) {
                          setState(() {
                            status = v!;
                            if (!_isPresent) {
                              location = null;
                              selectedCustomerId = null;
                              factories.clear();
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Location Chips (if present)
                if (_isPresent) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Location',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildLocationChip(
                                'Office',
                                AttendanceLocation.office,
                                location == AttendanceLocation.office,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildLocationChip(
                                'Outstation',
                                AttendanceLocation.outstation,
                                location == AttendanceLocation.outstation,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                // Customer Selection (if outstation)
                if (_isOutstation) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Customer',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
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
                                selectedCustomerId = partner.id;
                                selectedCustomerName = partner.name;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.business,
                                  size: 16,
                                  color: Colors.blue.shade700,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    selectedCustomerName ?? 'Select Customer',
                                    style: TextStyle(
                                      fontWeight: selectedCustomerName != null 
                                          ? FontWeight.w600 
                                          : FontWeight.normal,
                                      color: selectedCustomerName != null 
                                          ? Colors.blue.shade700 
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 12,
                                  color: Colors.grey.shade400,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Check In/Out (if present)
                if (_isPresent) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Time',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTimePicker(
                                'Check In',
                                checkIn,
                                Icons.login,
                                Colors.green,
                                () async {
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
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildTimePicker(
                                'Check Out',
                                checkOut,
                                Icons.logout,
                                Colors.red,
                                () async {
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
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Notes
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Notes',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: noteController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Add notes...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    if (widget.existingDay != null)
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.delete),
                          label: const Text('Delete'),
                          onPressed: () async {
                            final confirm = await _showConfirmDialog(
                              title: 'Delete Attendance',
                              message: 'Attendance dan seluruh activity pada tanggal ini akan DIHAPUS PERMANEN.\n\nLanjutkan?',
                              confirmText: 'Delete',
                              confirmColor: Colors.red,
                            );

                            if (confirm) {
                              await _deleteAttendance();
                            }
                          },
                        ),
                      ),

                    if (widget.existingDay != null)
                      const SizedBox(width: 12),

                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: _isSaving 
                            ? Container(
                                width: 16,
                                height: 16,
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(_isSaving ? 'Saving...' : 'Save Attendance'),
                        onPressed: _isSaving ? null : () async {
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
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // RIGHT CONTENT - ACTIVITIES
        Expanded(
          child: Column(
            children: [
              // Add Activity Button (if outstation)
              if (_isOutstation) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Activity'),
                          onPressed: () async {
                            if (selectedCustomerId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please select customer first'),
                                ),
                              );
                              return;
                            }

                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ActivityFormPage(
                                  attendanceDate: _selectedDate,
                                  customerId: selectedCustomerId!,
                                ),
                              ),
                            );

                            if (result is ActivityEntry) {
                              _addActivity(result);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Activities List
              Expanded(
                child: _glass(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.bolt,
                              color: Colors.purple,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Activities',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (_allActivities.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_allActivities.length} items',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.purple.shade700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (_allActivities.isEmpty)
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.bolt,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No activities added',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Add activities for outstation visits',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.builder(
                            itemCount: factories.length,
                            itemBuilder: (context, factoryIndex) {
                              final factory = factories[factoryIndex];
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Factory Header
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.factory,
                                          size: 14,
                                          color: Colors.blue.shade700,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            factory.factoryName,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                              color: Colors.blue.shade700,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '${factory.activities.length}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Activities
                                  ...factory.activities.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final a = entry.value;
                                    return _buildActivityCard(a, factory, index);
                                  }),

                                  const SizedBox(height: 12),
                                ],
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, Color statusColor) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Status Card
          _glass(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _isPresent ? Icons.check_circle : Icons.calendar_today,
                        color: statusColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Attendance Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Status
                DropdownButtonFormField<AttendanceStatus>(
                  value: status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: AttendanceStatus.values
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(s),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(s.label),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      status = v!;
                      if (!_isPresent) {
                        location = null;
                        selectedCustomerId = null;
                        factories.clear();
                      }
                    });
                  },
                ),

                if (_isPresent) ...[
                  const SizedBox(height: 12),
                  const Text('Location', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildLocationChip(
                          'Office',
                          AttendanceLocation.office,
                          location == AttendanceLocation.office,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildLocationChip(
                          'Outstation',
                          AttendanceLocation.outstation,
                          location == AttendanceLocation.outstation,
                        ),
                      ),
                    ],
                  ),
                ],

                if (_isOutstation) ...[
                  const SizedBox(height: 12),
                  const Text('Customer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
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
                          selectedCustomerId = partner.id;
                          selectedCustomerName = partner.name;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.business, size: 16, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              selectedCustomerName ?? 'Select Customer',
                              style: TextStyle(
                                fontWeight: selectedCustomerName != null ? FontWeight.w600 : FontWeight.normal,
                                color: selectedCustomerName != null ? Colors.blue.shade700 : Colors.grey.shade600,
                              ),
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey.shade400),
                        ],
                      ),
                    ),
                  ),
                ],

                if (_isPresent) ...[
                  const SizedBox(height: 16),
                  const Text('Time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimePicker(
                          'Check In',
                          checkIn,
                          Icons.login,
                          Colors.green,
                          () async {
                            final t = await showTimePicker(
                              context: context,
                              initialTime: checkIn,
                            );
                            if (t != null) setState(() => checkIn = t);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTimePicker(
                          'Check Out',
                          checkOut,
                          Icons.logout,
                          Colors.red,
                          () async {
                            final t = await showTimePicker(
                              context: context,
                              initialTime: checkOut,
                            );
                            if (t != null) setState(() => checkOut = t);
                          },
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),
                const Text('Notes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Add notes...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
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
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                if (widget.existingDay != null)
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                      onPressed: () async {
                        final confirm = await _showConfirmDialog(
                          title: 'Delete Attendance',
                          message: 'Attendance dan seluruh activity pada tanggal ini akan DIHAPUS PERMANEN.\n\nLanjutkan?',
                          confirmText: 'Delete',
                          confirmColor: Colors.red,
                        );

                        if (confirm) {
                          await _deleteAttendance();
                        }
                      },
                    ),
                  ),

                if (widget.existingDay != null)
                  const SizedBox(width: 12),

                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: _isSaving 
                        ? Container(
                            width: 16,
                            height: 16,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isSaving ? 'Saving...' : 'Save'),
                    onPressed: _isSaving ? null : () async {
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
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Activities Section
          if (_isOutstation) ...[
            _glass(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.bolt, color: Colors.purple, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Activities',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (_allActivities.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_allActivities.length}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.purple.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Add Activity Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Activity'),
                      onPressed: () async {
                        if (selectedCustomerId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select customer first'),
                            ),
                          );
                          return;
                        }

                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ActivityFormPage(
                              attendanceDate: _selectedDate,
                              customerId: selectedCustomerId!,
                            ),
                          ),
                        );

                        if (result is ActivityEntry) {
                          _addActivity(result);
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Activities List
                  if (_allActivities.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(Icons.bolt, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'No activities added',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...factories.map((factory) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Factory Header
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.factory, size: 14, color: Colors.blue.shade700),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    factory.factoryName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue.shade700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${factory.activities.length}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Activities
                          ...factory.activities.asMap().entries.map((entry) {
                            final index = entry.key;
                            final a = entry.value;
                            return _buildMobileActivityCard(a, factory, index);
                          }),

                          const SizedBox(height: 12),
                        ],
                      );
                    }).toList(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationChip(String label, AttendanceLocation loc, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          location = loc;
          if (loc == AttendanceLocation.office) {
            selectedCustomerId = null;
            factories.clear();
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? (loc == AttendanceLocation.office ? Colors.green : Colors.orange).withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected 
                ? (loc == AttendanceLocation.office ? Colors.green : Colors.orange)
                : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected 
                  ? (loc == AttendanceLocation.office ? Colors.green : Colors.orange)
                  : Colors.grey.shade600,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimePicker(String label, TimeOfDay time, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              time.format(context),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(ActivityEntry a, FactoryVisit factory, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.purple,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.activityType,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.precision_manufacturing, size: 12, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        a.machine,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (a.serialNumber.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.qr_code, size: 12, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          a.serialNumber,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ActivityFormPage(
                        attendanceDate: _selectedDate,
                        customerId: a.customerId,
                        existingActivity: a,
                      ),
                    ),
                  );

                  if (result is ActivityEntry) {
                    setState(() {
                      factory.activities.removeAt(index);
                      _cleanupFactories();
                      _addActivity(result);
                    });
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                onPressed: () {
                  setState(() {
                    factory.activities.removeAt(index);
                    _cleanupFactories();
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileActivityCard(ActivityEntry a, FactoryVisit factory, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.purple,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.activityType,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  a.machine,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (a.serialNumber.isNotEmpty)
                  Text(
                    a.serialNumber,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 16, color: Colors.blue),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ActivityFormPage(
                        attendanceDate: _selectedDate,
                        customerId: a.customerId,
                        existingActivity: a,
                      ),
                    ),
                  );

                  if (result is ActivityEntry) {
                    setState(() {
                      factory.activities.removeAt(index);
                      _cleanupFactories();
                      _addActivity(result);
                    });
                  }
                },
              ),
              const SizedBox(height: 4),
              IconButton(
                icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  setState(() {
                    factory.activities.removeAt(index);
                    _cleanupFactories();
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  FactoryVisit _getOrCreateFactory(String factoryId, String factoryName) {
    final existing = factories.where((f) => f.factoryId == factoryId);

    if (existing.isNotEmpty) {
      return existing.first;
    }

    final newFactory = FactoryVisit(
      factoryId: factoryId,
      factoryName: factoryName,
      activities: [],
    );

    factories.add(newFactory);

    return newFactory;
  }

  void _addActivity(ActivityEntry activity) {
    final factory = _getOrCreateFactory(
      activity.factoryId,
      activity.factoryClient,
    );

    setState(() {
      factory.activities.add(activity);
    });
  }

  void _cleanupFactories() {
    factories.removeWhere((f) => f.activities.isEmpty);
  }

  List<ActivityEntry> get _allActivities {
    return factories.expand((f) => f.activities).toList();
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
          color: Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.4)),
        ),
        child: child,
      ),
    ),
  );
}