import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/trip_expense_model.dart';
import '../services/trip_expense_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'dart:convert';
import '../services/trip_service.dart';
import 'package:http/http.dart' as http;
import '../../../services/receipt_scanner_service.dart';
import '../../../utils/receipt_amount_extractor.dart';
import '../../../utils/receipt_category_detector.dart';
import '../../../utils/receipt_confidence_calculator.dart';
import '../../../utils/receipt_currency_detector.dart';
import '../../../utils/receipt_duplicete_detector.dart';
import '../../../utils/receipt_image_processor.dart';
import 'package:image_picker/image_picker.dart';
import '../../../utils/receipt_layout_analyzer.dart';
import '../../../utils/receipt_fingerprint.dart';


class AddExpensePage extends StatefulWidget {

  final String tripId;
  

  const AddExpensePage({
    super.key,
    required this.tripId,
  });

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {

  final amountController = TextEditingController();
  final descController = TextEditingController();
  final scannerService = ReceiptScannerService();
  final tripService = TripService();
  

  String currency = 'AUD';
  String category = 'Hotel';
  String fingerprint = '';

  File? receiptImage;

  final expenseService = TripExpenseService();

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

    final expense = TripExpense(
      id: '',
      date: DateTime.now(),
      employeeId: user.uid,
      amount: double.tryParse(amountController.text) ?? 0,
      currency: currency,
      category: category,
      description: descController.text,
      receiptUrl: receiptUrl,
      fingerprint: fingerprint,
    );

    await expenseService.createExpense(
      widget.tripId,
      expense,
    );

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

  /// raw image
  final rawFile = File(photo.path);

  /// enhance image sebelum OCR
  final processedFile =
      await ReceiptImageProcessor.enhance(rawFile);
  
  final recognized =
    await scannerService.recognizeLayout(processedFile);

final layout =
    ReceiptLayoutAnalyzer.analyze(recognized);

final merchant =
    layout.header.isNotEmpty ? layout.header.first : '';

  setState(() {
    receiptImage = processedFile;
  });

  /// OCR
  final text =
      await scannerService.recognizeText(processedFile);

  /// DETECT DATA FROM RECEIPT
  final amount =
      ReceiptAmountExtractor.extractAmount(text);
  final detectedCurrency =
      ReceiptCurrencyDetector.detectCurrency(text);

  final detectedCategory =
      ReceiptCategoryDetector.detectCategory(text);
  
  if (amount != null) {

  fingerprint = ReceiptFingerprint.generate(
    merchant: merchant,
    amount: amount,
    currency: detectedCurrency,
    date: DateTime.now(),
  );

}

if (amount != null) {

  fingerprint = ReceiptFingerprint.generate(
    merchant: merchant,
    amount: amount,
    currency: detectedCurrency,
    date: DateTime.now(),
  );

}

  

  final confidence =
      ReceiptConfidenceCalculator.calculate(
        amount: amount,
        currency: detectedCurrency,
        text: text,
      );

  if (amount != null) {

    final user = FirebaseAuth.instance.currentUser!;

    final companyId = await tripService.getCompanyId();

    final expenseCollection = FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('trips')
        .doc(widget.tripId)
        .collection('expenses');
    
    final isDuplicateFingerprint =
    await expenseCollection
        .where('fingerprint', isEqualTo: fingerprint)
        .limit(1)
        .get();

if (isDuplicateFingerprint.docs.isNotEmpty) {

  if (!mounted) return;

  showDialog(
    context: context,
    builder: (_) => const AlertDialog(
      title: Text('Duplicate Receipt'),
      content: Text(
        'This receipt was already scanned before.',
      ),
    ),
  );

  return;
}

    final isDuplicate =
        await ReceiptDuplicateDetector.isDuplicate(
      expenseCollection: expenseCollection,
      amount: amount,
      currency: detectedCurrency,
      employeeId: user.uid,
    );

    if (isDuplicate) {

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Duplicate Expense'),
          content: const Text(
              'Possible duplicate expense detected. Please verify before saving.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            )
          ],
        ),
      );
    }
  }

  setState(() {

    if (amount != null) {
      amountController.text = amount.toString();
    }

    if (detectedCurrency.isNotEmpty) {
      currency = detectedCurrency;
    }

    if (detectedCategory.isNotEmpty) {
      category = detectedCategory;
    }

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

    final uniqueId =
        'receipt_${DateTime.now().millisecondsSinceEpoch}';

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

  void removePhoto() {
  setState(() {
    receiptImage = null;
    amountController.clear();
    fingerprint = '';
  });
}
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
      ),
      body: SingleChildScrollView(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
          children: [

            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
              ),
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField(
              value: currency,
              items: const [
                DropdownMenuItem(value: 'AUD', child: Text('AUD')),
                DropdownMenuItem(value: 'JPY', child: Text('JPY')),
                DropdownMenuItem(value: 'MYR', child: Text('MYR')),
                DropdownMenuItem(value: 'SGD', child: Text('SGD')),
                DropdownMenuItem(value: 'IDR', child: Text('IDR')),
              ],
              onChanged: (v) {
                setState(() {
                  currency = v!;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Currency',
              ),
            ),

            const SizedBox(height: 20),

DropdownButtonFormField(
  value: category,
  items: const [

    DropdownMenuItem(
      value: 'Hotel',
      child: Text('Hotel'),
    ),

    DropdownMenuItem(
      value: 'Meal',
      child: Text('Meal'),
    ),

    DropdownMenuItem(
      value: 'Transportation',
      child: Text('Transportation'),
    ),

    DropdownMenuItem(
      value: 'Other',
      child: Text('Other'),
    ),

  ],
  onChanged: (v) {
    setState(() {
      category = v!;
    });
  },
  decoration: const InputDecoration(
    labelText: 'Category',
  ),
),

            const SizedBox(height: 20),

            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description',
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton.icon(
              onPressed: scanReceipt,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Scan Receipt'),
            ),

            if (receiptImage != null)
  Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Column(
      children: [

        Image.file(
          receiptImage!,
          height: 120,
        ),

        const SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            TextButton.icon(
              onPressed: removePhoto,
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text("Remove"),
            ),

            const SizedBox(width: 10),

            TextButton.icon(
              onPressed: scanReceipt,
              icon: const Icon(Icons.camera_alt),
              label: const Text("Retake"),
            ),

          ],
        )
      ],
    ),
  ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: saveExpense,
              child: const Text('SAVE EXPENSE'),
            ),

          ],
        ),
      ),
      )
    );
  }
}