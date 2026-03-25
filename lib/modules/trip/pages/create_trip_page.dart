import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/trip_model.dart';
import '../services/trip_service.dart';
import '../../../pages/partners/partner_list_page.dart';
import '../../../models/partner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../pages/common/app_background_wrapper.dart';
import '../../../core/widgets/draggable_window.dart';

class CreateTripPage extends StatefulWidget {
  final Trip? trip;

  const CreateTripPage({
    super.key,
    this.trip,
  });

  @override
  State<CreateTripPage> createState() => _CreateTripPageState();
}

class _CreateTripPageState extends State<CreateTripPage> {
  final _titleController = TextEditingController();

  DateTime? startDate;
  DateTime? endDate;

  String country = 'Japan';
  String currency = 'JPY';
  String? partnerId;
  String? partnerName;

  final tripService = TripService();

  @override
  void initState() {
    super.initState();

    if (widget.trip != null) {
      _titleController.text = widget.trip!.title;
      startDate = widget.trip!.startDate;
      endDate = widget.trip!.endDate;
      country = widget.trip!.country;
      currency = widget.trip!.currency;
      partnerId = widget.trip!.partnerId;
      partnerName = widget.trip!.partnerName;
    }
  }

  Future<void> createTrip() async {
    final user = FirebaseAuth.instance.currentUser!;
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final userName = userDoc.data()?['username'] ?? '';

    final trip = Trip(
      id: '',
      title: _titleController.text,
      partnerId: partnerId ?? '',
      partnerName: partnerName ?? '',
      country: country,
      currency: currency,
      startDate: startDate ?? DateTime.now(),
      endDate: endDate ?? DateTime.now().add(const Duration(days: 3)),
      members: [user.uid],
      createdBy: user.uid,
      createdByName: userName,
      createdAt: DateTime.now(),
      status: 'open',
    );

    await tripService.createTrip(trip);

    Navigator.pop(context);

    if (partnerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a partner')),
      );
      return;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select Date';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final isEditing = widget.trip != null;

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
                    Colors.blue.withValues(alpha:0.2),
                    Colors.blue.withValues(alpha:0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.withValues(alpha:0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                isEditing ? Icons.edit : Icons.flight_takeoff,
                color: Colors.blue,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Edit Trip' : 'Create Trip',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isEditing ? 'Update details' : 'New business trip',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue.shade700,
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
            ? _buildDesktopLayout(isEditing)
            : _buildMobileLayout(isEditing),
      ),
    );
  }

  Widget _buildDesktopLayout(bool isEditing) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEFT SIDEBAR - FORM
        Container(
          width: 450,
          margin: const EdgeInsets.only(right: 16),
          child: SingleChildScrollView(
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
                              Colors.blue.withValues(alpha:0.2),
                              Colors.blue.withValues(alpha:0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.info_outline,
                          color: Colors.blue,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Trip Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Trip Title
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
                            Icon(Icons.title, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              'Trip Title',
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
                          controller: _titleController,
                          decoration: InputDecoration(
                            hintText: 'e.g., Business Meeting in Tokyo',
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

                  // Partner Selection
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.withValues(alpha:0.1),
                          Colors.green.withValues(alpha:0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.green.withValues(alpha:0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.business, size: 16, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(
                              'Client',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () async {
  final isDesktop = MediaQuery.of(context).size.width >= 900;

  if (isDesktop) {
    Partner? selectedPartner;

    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (context) {
        return DraggableResizableWindow(
          title: "Select Partner",
          headerColor: Colors.green,
          child: PartnerListPage(
            selectionMode: true,
            onSelected: (partner) {
              selectedPartner = partner;
              Navigator.pop(context);
            },
          ),
        );
      },
    );

    if (selectedPartner != null) {
      setState(() {
        partnerId = selectedPartner!.id;
        partnerName = selectedPartner!.name;
      });
    }
  } else {
    final Partner? partner = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PartnerListPage(
          selectionMode: true,
        ),
      ),
    );

    if (partner != null) {
      setState(() {
        partnerId = partner.id;
        partnerName = partner.name;
      });
    }
  }
},
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha:0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.green.withValues(alpha:0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (partnerName != null) ...[
                                        Text(
                                          partnerName!,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                      ] else
                                        Text(
                                          'Select Client',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.green.withValues(alpha:0.7),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 14,
                                  color: Colors.green,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Date Range
                  Row(
                    children: [
                      // Start Date
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: startDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: Colors.green,
                                      onPrimary: Colors.white,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setState(() => startDate = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green.withValues(alpha:0.1),
                                  Colors.green.withValues(alpha:0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.green.withValues(alpha:0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha:0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.calendar_today, color: Colors.green, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Start Date',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.green,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        _formatDate(startDate),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: startDate != null ? FontWeight.w600 : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // End Date
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: endDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: Colors.red,
                                      onPrimary: Colors.white,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setState(() => endDate = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.red.withValues(alpha:0.1),
                                  Colors.red.withValues(alpha:0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.red.withValues(alpha:0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha:0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.calendar_month, color: Colors.red, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'End Date',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.red,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        _formatDate(endDate),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: endDate != null ? FontWeight.w600 : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Country and Currency
                  Row(
                    children: [
                      // Country
                      Expanded(
                        child: Container(
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
                                  Icon(Icons.public, size: 14, color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Country',
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
                                value: country,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'Japan', child: Text('Japan 🇯🇵')),
                                  DropdownMenuItem(value: 'Australia', child: Text('Australia 🇦🇺')),
                                  DropdownMenuItem(value: 'Malaysia', child: Text('Malaysia 🇲🇾')),
                                  DropdownMenuItem(value: 'Singapore', child: Text('Singapore 🇸🇬')),
                                ],
                                onChanged: (v) {
                                  setState(() {
                                    country = v!;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Currency
                      Expanded(
                        child: Container(
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
                                  Icon(Icons.attach_money, size: 14, color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Currency',
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
                                value: currency,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'JPY', child: Text('JPY 💴')),
                                  DropdownMenuItem(value: 'AUD', child: Text('AUD 💵')),
                                  DropdownMenuItem(value: 'MYR', child: Text('MYR 💵')),
                                  DropdownMenuItem(value: 'SGD', child: Text('SGD 💵')),
                                ],
                                onChanged: (v) {
                                  setState(() {
                                    currency = v!;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: createTrip,
                          child: Text(isEditing ? 'UPDATE TRIP' : 'CREATE TRIP'),
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
                      'Trip Preview',
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
    child: SingleChildScrollView(
      child: Container(
                      width: 350,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.withValues(alpha:0.1),
                            Colors.blue.withValues(alpha:0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.blue.withValues(alpha:0.3),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Icon
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha:0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.flight_takeoff,
                              size: 48,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Title
                          Text(
                            _titleController.text.isEmpty
                                ? 'Trip Title'
                                : _titleController.text,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),

                          // Partner
                          if (partnerName != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha:0.1),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.business, size: 14, color: Colors.green),
                                  const SizedBox(width: 6),
                                  Text(
                                    partnerName!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Country
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.public, size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 8),
                              Text(
                                country,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Dates
                          if (startDate != null && endDate != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha:0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
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
                                      Text(
                                        '${startDate!.day}/${startDate!.month}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 20),
                                  const Icon(
                                    Icons.arrow_forward,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 20),
                                  Column(
                                    children: [
                                      const Text(
                                        'To',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                      ),
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
                            ),
                          ],

                          const SizedBox(height: 16),

                          // Currency
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.purple.withValues(alpha:0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Currency: $currency',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.purple.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(bool isEditing) {
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
                            Colors.blue.withValues(alpha:0.2),
                            Colors.blue.withValues(alpha:0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        color: Colors.blue,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Trip Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Trip Title
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Trip Title',
                    prefixIcon: const Icon(Icons.title, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    hintText: 'e.g., Business Meeting in Tokyo',
                  ),
                ),

                const SizedBox(height: 16),

                // Partner Selection
                InkWell(
                  onTap: () async {
                    final Partner? partner = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PartnerListPage(
                          selectionMode: true,
                        ),
                      ),
                    );

                    if (partner != null) {
                      setState(() {
                        partnerId = partner.id;
                        partnerName = partner.name;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.withValues(alpha:0.1),
                          Colors.green.withValues(alpha:0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.green.withValues(alpha:0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha:0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.business,
                            color: Colors.green,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Client',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green.withValues(alpha:0.8),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                partnerName ?? 'Select Client',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: partnerName != null
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: partnerName != null
                                      ? Colors.green.shade700
                                      : Colors.green.withValues(alpha:0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: Colors.green,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Start Date
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: startDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => startDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.withValues(alpha:0.1),
                          Colors.green.withValues(alpha:0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.green.withValues(alpha:0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.green, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Start Date',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green,
                                ),
                              ),
                              Text(
                                _formatDate(startDate),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: startDate != null ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.green,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // End Date
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: endDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => endDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.red.withValues(alpha:0.1),
                          Colors.red.withValues(alpha:0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.red.withValues(alpha:0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month, color: Colors.red, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'End Date',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.red,
                                ),
                              ),
                              Text(
                                _formatDate(endDate),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: endDate != null ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.red,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Country
                DropdownButtonFormField<String>(
                  value: country,
                  decoration: InputDecoration(
                    labelText: 'Country',
                    prefixIcon: const Icon(Icons.public, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Japan', child: Text('Japan 🇯🇵')),
                    DropdownMenuItem(value: 'Australia', child: Text('Australia 🇦🇺')),
                    DropdownMenuItem(value: 'Malaysia', child: Text('Malaysia 🇲🇾')),
                    DropdownMenuItem(value: 'Singapore', child: Text('Singapore 🇸🇬')),
                  ],
                  onChanged: (v) {
                    setState(() {
                      country = v!;
                    });
                  },
                ),

                const SizedBox(height: 12),

                // Currency
                DropdownButtonFormField<String>(
                  value: currency,
                  decoration: InputDecoration(
                    labelText: 'Currency',
                    prefixIcon: const Icon(Icons.attach_money, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'JPY', child: Text('JPY 💴')),
                    DropdownMenuItem(value: 'AUD', child: Text('AUD 💵')),
                    DropdownMenuItem(value: 'MYR', child: Text('MYR 💵')),
                    DropdownMenuItem(value: 'SGD', child: Text('SGD 💵')),
                  ],
                  onChanged: (v) {
                    setState(() {
                      currency = v!;
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Preview Card (Mobile)
          if (_titleController.text.isNotEmpty ||
              partnerName != null ||
              startDate != null ||
              endDate != null)
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
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.withValues(alpha:0.1),
                          Colors.blue.withValues(alpha:0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha:0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha:0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.flight_takeoff,
                                size: 24,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _titleController.text.isEmpty
                                        ? 'Trip Title'
                                        : _titleController.text,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (partnerName != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      partnerName!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                const Icon(Icons.public, size: 16, color: Colors.grey),
                                const SizedBox(height: 4),
                                Text(
                                  country,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            if (startDate != null && endDate != null)
                              Column(
                                children: [
                                  const Icon(Icons.date_range, size: 16, color: Colors.orange),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${endDate!.difference(startDate!).inDays} days',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            Column(
                              children: [
                                const Icon(Icons.attach_money, size: 16, color: Colors.purple),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withValues(alpha:0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    currency,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.purple.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
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
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: createTrip,
                    child: Text(isEditing ? 'UPDATE' : 'CREATE'),
                  ),
                ),
              ],
            ),
          ),
        ],
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