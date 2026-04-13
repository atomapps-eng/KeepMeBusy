import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/trip_service.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/trip_transfer_model.dart';
import '../services/trip_transfer_service.dart';
import '../../../pages/common/app_background_wrapper.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class AddTransferPage extends StatefulWidget {
  final String tripId;
  final String? transferId;

  const AddTransferPage({
    super.key,
    required this.tripId,
    this.transferId,
  });

  @override
  State<AddTransferPage> createState() => _AddTransferPageState();
}

class _AddTransferPageState extends State<AddTransferPage> {
  bool isUploading = false;
double uploadProgress = 0;
  TripTransfer? existingTransfer;
  DateTime date = DateTime.now();
  final amountController = TextEditingController();
  final noteController = TextEditingController();
  File? transferImage;
  String? existingImageUrl;

final String cloudName = 'djl2sukor';
final String uploadPreset = 'Receipt';

  String currency = 'AUD';
  IconData _getCurrencyIcon(String currency) {
  switch (currency) {
    case 'IDR':
      return Icons.payments;
    case 'JPY':
      return Icons.currency_yen;
    case 'CNY':
      return Icons.currency_yuan;
    case 'AUD':
    case 'SGD':
    case 'MYR':
    default:
      return Icons.attach_money;
  }
}

  final transferService = TripTransferService();
  final tripService = TripService();
List<String> allowedCurrencies = [];

  @override
void initState() {
  super.initState();

  loadAllowedCurrencies();

  if (widget.transferId != null) {
    loadTransfer();
  }
}

Future<void> loadAllowedCurrencies() async {
  final companyId = await tripService.getCompanyId();

  final tripDoc = await FirebaseFirestore.instance
      .collection('companies')
      .doc(companyId)
      .collection('trips')
      .doc(widget.tripId)
      .get();

  final tripCurrency = tripDoc.data()?['currency'] ?? 'IDR';

  List<String> baseCurrencies = [];

  if (companyId == 'atomIndonesia') {
    baseCurrencies = ['IDR'];
  } else if (companyId == 'atomIndia') {
    baseCurrencies = ['INR'];
  } else if (companyId == 'atomVietnam') {
    baseCurrencies = ['VND'];
  }

  final result = <String>{...baseCurrencies, tripCurrency}.toList();

  setState(() {
    allowedCurrencies = result;

    if (!allowedCurrencies.contains(currency)) {
      currency = allowedCurrencies.first;
    }
  });
}

  Future<void> loadTransfer() async {
    final doc = await transferService.getTransfer(
      widget.tripId,
      widget.transferId!,
    );

    if (doc == null) return;

    setState(() {
      existingTransfer = doc;

      final transfer = doc.transfers.first;

      amountController.text =
    formatNumber(transfer['amount'].toInt().toString());
      currency = transfer['currency'];
      noteController.text = doc.note;
      date = doc.date;
      existingImageUrl = doc.receiptUrl;
    });
  }

    Future<void> saveTransfer() async {

  if (isUploading) return;

  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("User not authenticated"),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  if (amountController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Amount cannot be empty"),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  setState(() {
    isUploading = true;
    uploadProgress = 0;
  });

  String photoUrl = existingImageUrl ?? '';

  try {

    /// ======================
    /// UPLOAD IMAGE
    /// ======================
    if (transferImage != null) {
      photoUrl = await uploadImageToCloudinary();
    }

    /// ======================
    /// CREATE MODEL
    /// ======================
    final transfer = TripTransfer(
      id: '',
      date: date,
      createdBy: user.uid,
      transfers: [
        {
          'employeeId': user.uid,
          'amount': double.tryParse(
  amountController.text.replaceAll('.', '')
) ?? 0,
          'currency': currency,
        }
      ],
      note: noteController.text,
      receiptUrl: photoUrl,
    );

    /// ======================
    /// SAVE FIRESTORE
    /// ======================
    if (widget.transferId == null) {
      await transferService.createTransfer(
        widget.tripId,
        transfer,
      );
    } else {
      await transferService.updateTransfer(
        widget.tripId,
        widget.transferId!,
        transfer,
      );
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Transfer saved successfully"),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context);

  } on SocketException {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("No internet connection"),
        backgroundColor: Colors.red,
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Failed to save transfer: $e"),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        isUploading = false;
      });
    }
  }
}

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.transferId != null;
    final isDesktop = MediaQuery.of(context).size.width >= 900;

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
                    Colors.green.withValues(alpha:0.2),
                    Colors.green.withValues(alpha:0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.withValues(alpha:0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.arrow_downward,
                color: Colors.green,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Edit Transfer' : 'Add Transfer',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isEditing ? 'Update transfer' : 'New transfer',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.green.shade700,
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
            onPressed: isUploading ? null : () => Navigator.pop(context),
          ),
        ),
      ),
      body: Stack(
  children: [

    AppBackgroundWrapper(
      padding: const EdgeInsets.all(16),
      child: isDesktop
          ? _buildDesktopLayout(isEditing)
          : _buildMobileLayout(isEditing),
    ),

    if (isUploading)
      Container(
        color: Colors.black.withValues(alpha: 0.4),
        child: Center(
          child: Container(
            width: 280,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  "Saving Transfer...",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

  ],
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
                              Colors.green.withValues(alpha:0.2),
                              Colors.green.withValues(alpha:0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.info_outline,
                          color: Colors.green,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Transfer Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Date Picker
                  _buildDesktopDateField(
                    label: 'Date',
                    value: date,
                    icon: Icons.calendar_today,
                    color: Colors.blue,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Colors.blue,
                                onPrimary: Colors.white,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() => date = picked);
                      }
                    },
                  ),

                  const SizedBox(height: 16),

                  // Currency
_buildDesktopDropdown(
  label: 'Currency',
  value: allowedCurrencies.isNotEmpty
    ? (allowedCurrencies.contains(currency)
        ? currency
        : allowedCurrencies.first)
    : '',
  icon: Icons.currency_exchange,
  items: allowedCurrencies,
  itemBuilder: (value) => value,
  onChanged: (v) {
    if (v != null) {
      setState(() => currency = v);
    }
  },
),

const SizedBox(height: 16),

// Amount (WAJIB pakai helper, bukan TextField langsung)
_buildDesktopTextField(
  label: 'Amount',
  icon: _getCurrencyIcon(currency),
  controller: amountController,
  keyboardType: TextInputType.number,
  hint: '0.00',
),

                  const SizedBox(height: 16),

                  // Note
                  _buildDesktopTextField(
                    label: 'Note',
                    icon: Icons.note,
                    controller: noteController,
                    hint: 'Enter note (optional)',
                    maxLines: 3,
                  ),
const SizedBox(height: 20),

// PHOTO BUTTONS
Row(
  children: [

    Expanded(
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.blue,
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: Colors.blue.withValues(alpha:0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: takePhoto,
        icon: const Icon(Icons.camera_alt),
        label: const Text('Take Photo'),
      ),
    ),

    const SizedBox(width: 12),

   Expanded(
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.green,
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: Colors.green.withValues(alpha:0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: pickFromGallery,
        icon: const Icon(Icons.photo_library),
        label: const Text('Gallery'),
      ),
    ),

  ],
),

// PHOTO PREVIEW
if (transferImage != null || (existingImageUrl?.isNotEmpty ?? false)) ...[
  const SizedBox(height: 16),

  Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.grey.withValues(alpha:0.05),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: transferImage != null
          ? Image.file(
              transferImage!,
              height: 120,
              fit: BoxFit.cover,
            )
          : Image.network(
              existingImageUrl!,
              height: 120,
              fit: BoxFit.cover,
            ),
    ),
  ),
],

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
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: isUploading
    ? null
    : () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("Confirm"),
              content: const Text(
                  "Are you sure you want to save this transfer?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Yes, Save"),
                ),
              ],
            );
          },
        );

        if (confirm == true) {
          await saveTransfer();
        }
      },
                          child: Text(isEditing ? 'UPDATE' : 'SAVE'),
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
                      'Transfer Preview',
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
                      width: 350,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.withValues(alpha:0.1),
                            Colors.green.withValues(alpha:0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.green.withValues(alpha:0.3),
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
                              color: Colors.green.withValues(alpha:0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_downward,
                              size: 48,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Date
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha:0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _formatDate(date),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Amount
                          Text(
                            amountController.text.isEmpty
    ? '0'
    : amountController.text,
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Currency
                          Text(
                            currency,
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Note
                          if (noteController.text.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha:0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                noteController.text,
                                style: const TextStyle(fontSize: 14),
                                textAlign: TextAlign.center,
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
                            Colors.green.withValues(alpha:0.2),
                            Colors.green.withValues(alpha:0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        color: Colors.green,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Transfer Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Date Picker
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => date = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.withValues(alpha:0.1),
                          Colors.blue.withValues(alpha:0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha:0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.blue, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Date',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue,
                                ),
                              ),
                              Text(
                                _formatDate(date),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.blue,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Amount
                // Currency (dipindah ke atas)
DropdownButtonFormField<String>(
  value: allowedCurrencies.isNotEmpty
    ? (allowedCurrencies.contains(currency)
        ? currency
        : allowedCurrencies.first)
    : '',
  decoration: InputDecoration(
    labelText: 'Currency',
    prefixIcon: const Icon(Icons.currency_exchange, size: 20),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  items: allowedCurrencies.map((c) {
    return DropdownMenuItem(
      value: c,
      child: Text(c),
    );
  }).toList(),
  onChanged: (v) {
    if (v != null) {
      setState(() => currency = v);
    }
  },
),

const SizedBox(height: 12),

// Amount (icon dynamic)
TextField(
  controller: amountController,
  keyboardType: TextInputType.number,
  onChanged: (value) {
    final formatted = formatNumber(value);

    if (value != formatted) {
      amountController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  },
  decoration: InputDecoration(
    labelText: 'Amount',
    prefixIcon: Icon(_getCurrencyIcon(currency), size: 20),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    hintText: '0.00',
  ),
),

                const SizedBox(height: 12),

                // Note
               // Note
TextField(
  controller: noteController,
  maxLines: 3,
  decoration: InputDecoration(
    labelText: 'Note',
    prefixIcon: const Icon(Icons.note, size: 20),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    hintText: 'Enter note (optional)',
  ),
),

const SizedBox(height: 20),

// PHOTO BUTTONS
Row(
  children: [

    Expanded(
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.blue,
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: Colors.blue.withValues(alpha:0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: takePhoto,
        icon: const Icon(Icons.camera_alt),
        label: const Text('Take Photo'),
      ),
    ),
    const SizedBox(width: 12),

    Expanded(
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.green,
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: Colors.green.withValues(alpha:0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: pickFromGallery,
        icon: const Icon(Icons.photo_library),
        label: const Text('Gallery'),
      ),
    ),

  ],
),

// PHOTO PREVIEW
if (transferImage != null) ...[
  const SizedBox(height: 16),

  Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.grey.withValues(alpha:0.05),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        transferImage!,
        height: 120,
        fit: BoxFit.cover,
      ),
    ),
  ),
],
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
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: isUploading
    ? null
    : () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("Confirm"),
              content: const Text(
                  "Are you sure you want to save this transfer?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Yes, Save"),
                ),
              ],
            );
          },
        );

        if (confirm == true) {
          await saveTransfer();
        }
      },
                    child: Text(isEditing ? 'UPDATE' : 'SAVE'),
                  ),
                ),
              ],
            ),
          ),

          // Preview Card (Mobile)
          if (amountController.text.isNotEmpty || noteController.text.isNotEmpty)
            const SizedBox(height: 16),

          if (amountController.text.isNotEmpty || noteController.text.isNotEmpty)
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
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha:0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_downward,
                            size: 24,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                amountController.text.isEmpty
                                    ? '0.00'
                                    : '${amountController.text} $currency',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDate(date),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              if (noteController.text.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  noteController.text,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
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
    );
  }

  Widget _buildDesktopTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? hint,
    int maxLines = 1,
  }) {
    return Container(
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
              Icon(icon, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                label,
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
  controller: controller,
  keyboardType: keyboardType,
  maxLines: maxLines,
  onChanged: (value) {
    final formatted = formatNumber(value);

    if (value != formatted) {
      controller.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  },
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopDateField({
    required String label,
    required DateTime value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
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
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(value),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.grey,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopDropdown({
    required String label,
    required String value,
    required IconData icon,
    required List<String> items,
    required String Function(String) itemBuilder,
    required void Function(String?) onChanged,
  }) {
    return Container(
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
              Icon(icon, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                label,
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
            value: value,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: items.map((item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(itemBuilder(item)),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

 Future<void> takePhoto() async {
  final picker = ImagePicker();

  final photo = await picker.pickImage(
    source: ImageSource.camera,
    imageQuality: 85,
  );

  if (photo == null) return;

  setState(() {
    transferImage = File(photo.path);
  });
}

Future<void> pickFromGallery() async {
  final picker = ImagePicker();

  final photo = await picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 85,
  );

  if (photo == null) return;

  setState(() {
    transferImage = File(photo.path);
  });
}

Future<String> uploadImageToCloudinary() async {
  if (transferImage == null) return '';

  final url = Uri.parse(
    'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
  );

  final request = http.MultipartRequest('POST', url);

  request.fields['upload_preset'] = uploadPreset;
  request.fields['folder'] = 'Transfer';

  final uniqueId = 'transfer_${DateTime.now().millisecondsSinceEpoch}';

  request.fields['public_id'] = uniqueId;

  request.files.add(
    await http.MultipartFile.fromPath(
      'file',
      transferImage!.path,
    ),
  );

  final response = await request.send();

  final resBody = await response.stream.bytesToString();
  final data = json.decode(resBody);

  if (response.statusCode == 200) {
    return data['secure_url'];
  } else {
    debugPrint('Upload failed');
    return '';
  }
}

String formatNumber(String value) {
  if (value.isEmpty) return '';

  final clean = value.replaceAll(RegExp(r'[^0-9]'), '');

  if (clean.isEmpty) return '';

  final parsed = int.parse(clean);

  return parsed.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => '.',
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