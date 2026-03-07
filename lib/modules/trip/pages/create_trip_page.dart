import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/trip_model.dart';
import '../services/trip_service.dart';
import '../../../pages/partners/partner_list_page.dart';
import '../../../models/partner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Trip'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Trip Title',
              ),
            ),

            const SizedBox(height: 20),

            ListTile(
  contentPadding: EdgeInsets.zero,
  title: Text(partnerName ?? 'Select Partner'),
  subtitle: const Text('Client'),
  trailing: const Icon(Icons.arrow_forward_ios),
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
),

const SizedBox(height: 20),

            DropdownButtonFormField(
              value: country,
              items: const [
                DropdownMenuItem(value: 'Japan', child: Text('Japan')),
                DropdownMenuItem(value: 'Australia', child: Text('Australia')),
                DropdownMenuItem(value: 'Malaysia', child: Text('Malaysia')),
                DropdownMenuItem(value: 'Singapore', child: Text('Singapore')),
              ],
              onChanged: (v){
                setState(() {
                  country = v!;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Country',
              ),
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField(
              value: currency,
              items: const [
                DropdownMenuItem(value: 'JPY', child: Text('JPY')),
                DropdownMenuItem(value: 'AUD', child: Text('AUD')),
                DropdownMenuItem(value: 'MYR', child: Text('MYR')),
                DropdownMenuItem(value: 'SGD', child: Text('SGD')),
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

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: createTrip,
              child: const Text('CREATE TRIP'),
            )
          ],
        ),
      ),
    );
  }
}