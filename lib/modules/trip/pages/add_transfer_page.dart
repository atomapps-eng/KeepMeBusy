import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/trip_transfer_model.dart';
import '../services/trip_transfer_service.dart';

class AddTransferPage extends StatefulWidget {

  final String tripId;

  const AddTransferPage({
    super.key,
    required this.tripId,
  });

  @override
  State<AddTransferPage> createState() => _AddTransferPageState();
}

class _AddTransferPageState extends State<AddTransferPage> {

  final amountController = TextEditingController();
  final noteController = TextEditingController();

  String currency = 'AUD';

  final transferService = TripTransferService();

  Future<void> saveTransfer() async {

    final user = FirebaseAuth.instance.currentUser!;

    final transfer = TripTransfer(
      id: '',
      date: DateTime.now(),
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

    await transferService.createTransfer(
      widget.tripId,
      transfer,
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transfer'),
      ),
      body: Padding(
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