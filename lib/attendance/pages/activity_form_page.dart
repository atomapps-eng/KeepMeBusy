import 'package:flutter/material.dart';
import 'dart:ui';
import '../../pages/common/app_background_wrapper.dart';
import '../models/activity_entry.dart';
import '../../models/partner.dart';
import '../../pages/partners/partner_list_page.dart';
import '../../theme/app_theme.dart';
import '../../core/widgets/draggable_window.dart';
import 'dart:async';

class ActivityFormPage extends StatefulWidget {
  final DateTime attendanceDate;
  final String customerId;
  final ActivityEntry? existingActivity;
  final VoidCallback? onClose;
  final Function(ActivityEntry)? onSaved;

  const ActivityFormPage({
    super.key,
    required this.attendanceDate,
    required this.customerId, 
    this.existingActivity,
    this.onClose,
    this.onSaved,
  });

  @override
  State<ActivityFormPage> createState() => _ActivityFormPageState();
}

class _ActivityFormPageState extends State<ActivityFormPage> {
  late DateTime date;

  String? factoryId;
  String? factoryName;

  String activityType = 'service';
  String status = 'paid';

  final machineCtrl = TextEditingController();
  final serialCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();

    date = widget.attendanceDate;

    if (widget.existingActivity != null) {
      final a = widget.existingActivity!;

      date = a.date;
      factoryId = a.factoryId;
      factoryName = a.factoryClient;

      machineCtrl.text = a.machine;
      serialCtrl.text = a.serialNumber;
      descCtrl.text = a.description;
      noteCtrl.text = a.note;

      activityType = a.activityType;
      status = a.status;
    }
  }

  @override
  void dispose() {
    machineCtrl.dispose();
    serialCtrl.dispose();
    descCtrl.dispose();
    noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectFactory() async {
  final isDesktop = MediaQuery.of(context).size.width >= 900;

  if (isDesktop) {
    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) {
        return Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: DraggableResizableWindow(
              title: "Select Factory",
              headerColor: Colors.green,
              onClose: () {
                entry.remove();
              },
              child: PartnerListPage(
                selectionMode: true,
                onSelected: (partner) {
                  setState(() {
                    factoryId = partner.id;
                    factoryName = partner.name;
                  });
                  entry.remove();
                },
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(entry);
  } else {
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
        factoryId = partner.id;
        factoryName = partner.name;
      });
    }
  }
}

Future<void> _save() async {
  if (factoryId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please select factory'),
      ),
    );
    return;
  }

  final overlay = Overlay.of(context, rootOverlay: true);
late OverlayEntry entry;

final completer = Completer<bool>();

entry = OverlayEntry(
  builder: (context) {
    return Positioned.fill(
      child: Material(
        color: Colors.black.withOpacity(0.4),
        child: Center(
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Save Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Are you sure you want to save this activity?',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          entry.remove();
                          completer.complete(false);
                        },
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          entry.remove();
                          completer.complete(true);
                        },
                        child: const Text('Yes, Save'),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  },
);

overlay.insert(entry);

final confirm = await completer.future;

if (confirm != true) return;

  final activity = ActivityEntry(
    date: date,
    factoryId: factoryId!,
    factoryClient: factoryName ?? '',
    customerId: widget.customerId,
    machine: machineCtrl.text,
    serialNumber: serialCtrl.text,
    activityType: activityType,
    description: descCtrl.text,
    status: status,
    note: noteCtrl.text,
  );

  final isDesktop = MediaQuery.of(context).size.width >= 900;

 if (isDesktop) {
  widget.onSaved?.call(activity);
} else {
  Navigator.pop(context, activity);
}
}


  Color _getActivityTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'service':
        return Colors.green;
      case 'maintenance':
        return Colors.orange;
      case 'installation':
        return Colors.blue;
      case 'training':
        return Colors.purple;
      case 'meeting':
        return Colors.teal;
      case 'remote':
        return Colors.cyan;
      default:
        return AppTheme.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final activityColor = _getActivityTypeColor(activityType);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: activityColor.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.bolt,
                  color: activityColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.existingActivity == null
                        ? 'Add Activity'
                        : 'Edit Activity',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    date.toString().split(' ').first,
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
          leading: isDesktop
    ? null
    : IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
        ),
        body: AppBackgroundWrapper(
          padding: const EdgeInsets.all(16),
          child: isDesktop 
              ? _buildDesktopLayout(context, activityColor)
              : _buildMobileLayout(context, activityColor),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, Color activityColor) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEFT SIDEBAR - FORM
        Container(
  width: 450,
  margin: const EdgeInsets.only(right: 16),
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
                  color: activityColor.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: activityColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Activity Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildDesktopField(
            'Date',
            date.toString().split(' ').first,
            Icons.calendar_today,
            Colors.blue,
            () async {
              final picked = await showDatePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                initialDate: date,
              );
              if (picked != null) {
                setState(() => date = picked);
              }
            },
          ),

          const SizedBox(height: 12),

          _buildDesktopField(
            'Factory',
            factoryName ?? 'Select Factory',
            Icons.factory,
            Colors.green,
            _selectFactory,
            isSelected: factoryName != null,
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha:0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.precision_manufacturing, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Machine',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: machineCtrl,
                  decoration: InputDecoration(
                    hintText: 'Enter machine name/number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha:0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.qr_code, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Serial Number',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: serialCtrl,
                  decoration: InputDecoration(
                    hintText: 'Enter serial number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha:0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.category, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Activity Type',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: activityType,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    'service',
                    'maintenance',
                    'remote',
                    'installation',
                    'training',
                    'general visit',
                    'meeting',
                  ].map((e) {
                    final color = _getActivityTypeColor(e);
                    return DropdownMenuItem(
                      value: e,
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(e),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (v) {
                    setState(() => activityType = v!);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha:0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'paid',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, size: 14, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Paid'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'warranty',
                      child: Row(
                        children: [
                          Icon(Icons.verified, size: 14, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Warranty'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (v) {
                    setState(() => status = v!);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha:0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.description, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter activity description...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha:0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.note, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Note',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Additional notes...',
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

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel'),
                  onPressed: () {
  if (isDesktop) {
    widget.onClose?.call();
  } else {
    Navigator.pop(context);
  }
},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: activityColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.save),
                  label: const Text('Save Activity'),
                  onPressed: _save,
                ),
              ),
            ],
          ),
        ],
      ),
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
                        color: Colors.purple.withValues(alpha:0.1),
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
                      'Activity Preview',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Center(
                    child: Container(
                      width: 300,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: activityColor.withValues(alpha:0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: activityColor.withValues(alpha:0.3),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: activityColor.withValues(alpha:0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.bolt,
                              size: 48,
                              color: activityColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            activityType,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: activityColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            factoryName ?? 'No Factory Selected',
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            machineCtrl.text.isEmpty ? 'No Machine' : machineCtrl.text,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (serialCtrl.text.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'SN: ${serialCtrl.text}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: status == 'paid' ? Colors.green.withValues(alpha:0.1) : Colors.orange.withValues(alpha:0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  status == 'paid' ? Icons.check_circle : Icons.verified,
                                  size: 14,
                                  color: status == 'paid' ? Colors.green : Colors.orange,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  status == 'paid' ? 'Paid' : 'Warranty',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: status == 'paid' ? Colors.green : Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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

  Widget _buildMobileLayout(BuildContext context, Color activityColor) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Main Form Card
          _glass(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: activityColor.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.info_outline,
                        color: activityColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Activity Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Date Selector
                _buildMobileField(
                  'Date',
                  date.toString().split(' ').first,
                  Icons.calendar_today,
                  Colors.blue,
                  () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      initialDate: date,
                    );
                    if (picked != null) {
                      setState(() => date = picked);
                    }
                  },
                ),

                const SizedBox(height: 8),

                // Factory Selector
                _buildMobileField(
                  'Factory',
                  factoryName ?? 'Select Factory',
                  Icons.factory,
                  Colors.green,
                  _selectFactory,
                  isSelected: factoryName != null,
                ),

                const SizedBox(height: 16),

                // Machine
                TextField(
                  controller: machineCtrl,
                  decoration: InputDecoration(
                    labelText: 'Machine',
                    prefixIcon: const Icon(Icons.precision_manufacturing),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Serial Number
                TextField(
                  controller: serialCtrl,
                  decoration: InputDecoration(
                    labelText: 'Serial Number',
                    prefixIcon: const Icon(Icons.qr_code),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Activity Type
                DropdownButtonFormField<String>(
                  value: activityType,
                  decoration: InputDecoration(
                    labelText: 'Activity Type',
                    prefixIcon: const Icon(Icons.category),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    'service',
                    'maintenance',
                    'remote',
                    'installation',
                    'training',
                    'general visit',
                    'meeting',
                  ].map((e) {
                    final color = _getActivityTypeColor(e);
                    return DropdownMenuItem(
                      value: e,
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(e),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (v) {
                    setState(() => activityType = v!);
                  },
                ),

                const SizedBox(height: 16),

                // Status
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    prefixIcon: const Icon(Icons.info),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'paid',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, size: 16, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Paid'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'warranty',
                      child: Row(
                        children: [
                          Icon(Icons.verified, size: 16, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Warranty'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (v) {
                    setState(() => status = v!);
                  },
                ),

                const SizedBox(height: 16),

                // Description
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    prefixIcon: const Icon(Icons.description),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Note
                TextField(
                  controller: noteCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Note',
                    prefixIcon: const Icon(Icons.note),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
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
              color: Colors.white.withValues(alpha:0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha:0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade300,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: activityColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                    onPressed: _save,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopField(
    String label,
    String value,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool isSelected = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha:0.05) : Colors.grey.withValues(alpha:0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? color : Colors.black87,
                    ),
                  ),
                ],
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
    );
  }

  Widget _buildMobileField(
    String label,
    String value,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool isSelected = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha:0.05) : Colors.grey.withValues(alpha:0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? color : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.grey.shade400,
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
          color: Colors.white.withValues(alpha:0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha:0.4)),
        ),
        child: child,
      ),
    ),
  );
}