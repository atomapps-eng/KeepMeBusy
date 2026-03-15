import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/trip_expense_model.dart';
import '../services/trip_expense_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'dart:convert';
import '../services/trip_service.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../../pages/common/app_background_wrapper.dart';
import 'package:file_picker/file_picker.dart';

class AddExpensePage extends StatefulWidget {
  final String tripId;
  final String? expenseId;

  const AddExpensePage({
    super.key,
    required this.tripId,
    this.expenseId,
  });

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final amountController = TextEditingController();
  final descController = TextEditingController();
  final tripService = TripService();
  TripExpense? existingExpense;
  DateTime date = DateTime.now();

  String currency = 'AUD';
  String category = 'Hotel';
  String fingerprint = '';

  File? receiptImage;

  File? receiptPdf;
  String? pdfName;

  final expenseService = TripExpenseService();

  @override
  void initState() {
    super.initState();

    if (widget.expenseId != null) {
      loadExpense();
    }
  }

  Future<void> loadExpense() async {
    final companyId = await tripService.getCompanyId();

    final doc = await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('trips')
        .doc(widget.tripId)
        .collection('expenses')
        .doc(widget.expenseId)
        .get();

    if (!doc.exists) return;

    final expense = TripExpense.fromMap(doc.id, doc.data()!);

    setState(() {
      existingExpense = expense;

      amountController.text = expense.amount.toString();
      currency = expense.currency;
      category = expense.category;
      descController.text = expense.description;
      fingerprint = expense.fingerprint;
      date = expense.date;
    });
  }

  /// CLOUDINARY CONFIG
  final String cloudName = 'djl2sukor';
  final String uploadPreset = 'Receipt';

  /// SAVE EXPENSE
  Future<void> saveExpense() async {
    final user = FirebaseAuth.instance.currentUser!;

    String receiptUrl = '';

    /// upload image jika ada
    if (receiptImage != null) {
      receiptUrl = await uploadImageToCloudinary();
    }

    if (receiptPdf != null) {
    receiptUrl = await uploadPdfToCloudinary();
    }

    final expense = TripExpense(
      id: '',
      date: date,
      employeeId: user.uid,
      amount: double.tryParse(amountController.text) ?? 0,
      currency: currency,
      category: category,
      description: descController.text,
      receiptUrl: receiptUrl,
      fingerprint: fingerprint,
    );

    if (widget.expenseId == null) {
      await expenseService.createExpense(
        widget.tripId,
        expense,
      );
    } else {
      await expenseService.updateExpense(
        widget.tripId,
        widget.expenseId!,
        expense,
      );
    }

    Navigator.pop(context);
  }

  /// PICK RECEIPT IMAGE
Future<void> scanReceipt() async {
  final picker = ImagePicker();

  final photo = await picker.pickImage(
    source: ImageSource.camera,
    imageQuality: 85,
  );

  if (photo == null) return;

  setState(() {
    receiptImage = File(photo.path);
  });
}

  /// UPLOAD IMAGE TO CLOUDINARY
  Future<String> uploadImageToCloudinary() async {
    if (receiptImage == null) return '';

    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', url);

    request.fields['upload_preset'] = uploadPreset;
    request.fields['folder'] = 'Receipt';

    final uniqueId = 'receipt_${DateTime.now().millisecondsSinceEpoch}';

    request.fields['public_id'] = uniqueId;

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        receiptImage!.path,
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

  Future<String> uploadPdfToCloudinary() async {
  if (receiptPdf == null) return '';

  final url = Uri.parse(
    'https://api.cloudinary.com/v1_1/$cloudName/raw/upload',
  );

  final request = http.MultipartRequest('POST', url);

  request.fields['upload_preset'] = uploadPreset;
  request.fields['folder'] = 'Receipt';

  final uniqueId = 'receipt_pdf_${DateTime.now().millisecondsSinceEpoch}';

  request.fields['public_id'] = uniqueId;

  request.files.add(
    await http.MultipartFile.fromPath(
      'file',
      receiptPdf!.path,
    ),
  );

  final response = await request.send();

  final resBody = await response.stream.bytesToString();
  final data = json.decode(resBody);

  if (response.statusCode == 200) {
    return data['secure_url'];
  } else {
    debugPrint('PDF upload failed');
    return '';
  }
}

  void removePhoto() {
    setState(() {
      receiptImage = null;
      amountController.clear();
      fingerprint = '';
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Hotel':
        return Colors.blue;
      case 'Meal':
        return Colors.green;
      case 'Transportation':
        return Colors.orange;
      case 'Other':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.expenseId != null;
    final categoryColor = _getCategoryColor(category);
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
                    Colors.red.withOpacity(0.2),
                    Colors.red.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.receipt,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Edit Expense' : 'Add Expense',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isEditing ? 'Update expense' : 'New expense',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.red.shade700,
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
                Colors.white.withOpacity(0.2),
                Colors.white.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
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
            ? _buildDesktopLayout(isEditing, categoryColor)
            : _buildMobileLayout(isEditing, categoryColor),
      ),
    );
  }

  Widget _buildDesktopLayout(bool isEditing, Color categoryColor) {
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
                              Colors.red.withOpacity(0.2),
                              Colors.red.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.info_outline,
                          color: Colors.red,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Expense Information',
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

                  // Amount
                  _buildDesktopTextField(
                    label: 'Amount',
                    icon: Icons.attach_money,
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    hint: '0.00',
                  ),

                  const SizedBox(height: 16),

                  // Currency and Category
                  Row(
                    children: [
                      // Currency
                      Expanded(
                        child: _buildDesktopDropdown(
                          label: 'Currency',
                          value: currency,
                          icon: Icons.currency_exchange,
                          items: const [
                            'AUD', 'JPY', 'MYR', 'SGD', 'IDR'
                          ],
                          itemBuilder: (value) => value,
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => currency = v);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Category
                      Expanded(
                        child: _buildDesktopDropdown(
                          label: 'Category',
                          value: category,
                          icon: Icons.category,
                          items: const [
                            'Hotel', 'Meal', 'Transportation', 'Other'
                          ],
                          itemBuilder: (value) => value,
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => category = v);
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Description
                  _buildDesktopTextField(
                    label: 'Description',
                    icon: Icons.description,
                    controller: descController,
                    hint: 'Enter description',
                    maxLines: 2,
                  ),

                  const SizedBox(height: 24),

                  // Scan Receipt Button
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      side: BorderSide(color: Colors.blue.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
  showModalBottomSheet(
    context: context,
    builder: (_) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                scanReceipt();
              },
            ),

            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                pickFromGallery();
              },
            ),

            ListTile(
  leading: const Icon(Icons.picture_as_pdf),
  title: const Text('Upload PDF'),
  onTap: () {
    Navigator.pop(context);
    pickPdf();
  },
),

          ],
        ),
      );
    },
  );
},
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Scan Receipt'),
                  ),

                  const SizedBox(height: 16),

                  // Receipt Preview
                  if (receiptImage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              receiptImage!,
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton.icon(
                                onPressed: removePhoto,
                                icon: const Icon(Icons.delete, color: Colors.red, size: 16),
                                label: const Text(
                                  "Remove",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                              const SizedBox(width: 20),
                              TextButton.icon(
                                onPressed: scanReceipt,
                                icon: const Icon(Icons.camera_alt, size: 16),
                                label: const Text("Retake"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (receiptPdf != null) ...[
  const SizedBox(height: 16),
  Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.red.withOpacity(0.05),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.red.withOpacity(0.3)),
    ),
    child: Row(
      children: [
        const Icon(Icons.picture_as_pdf, color: Colors.red),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            pdfName ?? 'PDF File',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () {
            setState(() {
              receiptPdf = null;
              pdfName = null;
            });
          },
        ),
      ],
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
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: saveExpense,
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
                            Colors.purple.withOpacity(0.2),
                            Colors.purple.withOpacity(0.1),
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
                      'Expense Preview',
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
                            Colors.red.withOpacity(0.1),
                            Colors.red.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.3),
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
                              color: Colors.red.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.receipt,
                              size: 48,
                              color: Colors.red.shade700,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Date
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
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
                                ? '0.00'
                                : amountController.text,
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
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

                          // Category
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: categoryColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: categoryColor,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Description
                          if (descController.text.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                descController.text,
                                style: const TextStyle(fontSize: 13),
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

  Widget _buildMobileLayout(bool isEditing, Color categoryColor) {
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
                            Colors.red.withOpacity(0.2),
                            Colors.red.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        color: Colors.red,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Expense Information',
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
                          Colors.blue.withOpacity(0.1),
                          Colors.blue.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.3),
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
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixIcon: const Icon(Icons.attach_money, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    hintText: '0.00',
                  ),
                ),

                const SizedBox(height: 12),

                // Currency
                DropdownButtonFormField<String>(
                  value: currency,
                  decoration: InputDecoration(
                    labelText: 'Currency',
                    prefixIcon: const Icon(Icons.currency_exchange, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    'AUD', 'JPY', 'MYR', 'SGD', 'IDR'
                  ].map((c) {
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

                // Category
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    prefixIcon: const Icon(Icons.category, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    'Hotel', 'Meal', 'Transportation', 'Other'
                  ].map((c) {
                    return DropdownMenuItem(
                      value: c,
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _getCategoryColor(c),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(c),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => category = v);
                    }
                  },
                ),

                const SizedBox(height: 12),

                // Description
                TextField(
                  controller: descController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    prefixIcon: const Icon(Icons.description, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    hintText: 'Enter description',
                  ),
                ),

                const SizedBox(height: 20),

                // Scan Receipt Button
               Row(
  children: [

    Expanded(
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.blue,
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: Colors.blue.withOpacity(0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: scanReceipt,
        icon: const Icon(Icons.camera_alt),
        label: const Text('Camera'),
      ),
    ),

    const SizedBox(width: 8),

    Expanded(
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.green,
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: Colors.green.withOpacity(0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: pickFromGallery,
        icon: const Icon(Icons.photo_library),
        label: const Text('Gallery'),
      ),
    ),

    const SizedBox(width: 8),

    Expanded(
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: Colors.red.withOpacity(0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: pickPdf,
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text('PDF'),
      ),
    ),
  ],
),
                // Receipt Preview
                if (receiptImage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            receiptImage!,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton.icon(
                              onPressed: removePhoto,
                              icon: const Icon(Icons.delete, color: Colors.red, size: 16),
                              label: const Text(
                                "Remove",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                            const SizedBox(width: 20),
                            TextButton.icon(
                              onPressed: scanReceipt,
                              icon: const Icon(Icons.camera_alt, size: 16),
                              label: const Text("Retake"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                if (receiptPdf != null) ...[
  const SizedBox(height: 16),
  Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.red.withOpacity(0.05),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.red.withOpacity(0.3)),
    ),
    child: Row(
      children: [
        const Icon(Icons.picture_as_pdf, color: Colors.red),
        const SizedBox(width: 10),

        Expanded(
          child: Text(
            pdfName ?? 'PDF File',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () {
            setState(() {
              receiptPdf = null;
              pdfName = null;
            });
          },
        ),
      ],
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
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
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
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: saveExpense,
                    child: Text(isEditing ? 'UPDATE' : 'SAVE'),
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
        color: Colors.grey.withOpacity(0.05),
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
            decoration: InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
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
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
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
        color: Colors.grey.withOpacity(0.05),
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

  Future<void> pickFromGallery() async {
  final picker = ImagePicker();

  final photo = await picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 85,
  );

  if (photo == null) return;

  setState(() {
    receiptImage = File(photo.path);
  });
}

Future<void> pickPdf() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf'],
  );

  if (result == null) return;

  setState(() {
    receiptPdf = File(result.files.single.path!);
    pdfName = result.files.single.name;
    receiptImage = null;
  });
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
              Colors.white.withOpacity(0.3),
              Colors.white.withOpacity(0.15),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.4)),
        ),
        child: child,
      ),
    ),
  );
}