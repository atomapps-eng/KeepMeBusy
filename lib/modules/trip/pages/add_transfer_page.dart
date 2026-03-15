import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/trip_transfer_model.dart';
import '../services/trip_transfer_service.dart';

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
  
  TripTransfer? existingTransfer;
  DateTime date = DateTime.now();
  final amountController = TextEditingController();
  final noteController = TextEditingController();

  String currency = 'AUD';

  final transferService = TripTransferService();

  @override
void initState() {
  super.initState();

  if (widget.transferId != null) {
    loadTransfer();
  }
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

    amountController.text = transfer['amount'].toString();
    currency = transfer['currency'];
    noteController.text = doc.note;
    date = doc.date;

  });

}

  Future<void> saveTransfer() async {

    final user = FirebaseAuth.instance.currentUser!;

    final transfer = TripTransfer(
      id: '',
      date: date,
      createdBy: user.uid,
      transfers: [
        {
          'employeeId': user.uid,
          'amount': double.tryParse(amountController.text) ?? 0,
          'currency': currency,
        }
      ],
      note: noteController.text,
    );

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

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(
  widget.transferId == null
      ? 'Add Transfer'
      : 'Edit Transfer',
),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// DATE PICKER
ListTile(
  contentPadding: EdgeInsets.zero,
  title: Text(
    "${date.year}-${date.month}-${date.day}",
  ),
  subtitle: const Text("Date"),
  trailing: const Icon(Icons.calendar_today),
  onTap: () async {

    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        date = picked;
      });
    }

  },
),

const SizedBox(height: 20),

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
              onChanged: (v){
                setState(() {
                  currency = v!;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Currency',
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Note',
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: saveTransfer,
              child: const Text('SAVE TRANSFER'),
            )

          ],
        ),
      ),
    );
  }
}