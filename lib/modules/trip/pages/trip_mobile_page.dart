import 'package:flutter/material.dart';
import '../services/trip_service.dart';
import '../../../models/trip_model.dart';
import 'create_trip_page.dart';
import 'trip_detail_page.dart';
import 'package:firebase_auth/firebase_auth.dart';


class TripMobilePage extends StatelessWidget {
  const TripMobilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final tripService = TripService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Trip Report'),
      ),
      body: FutureBuilder<String>(
  future: tripService.getCompanyId(),
  builder: (context, companySnapshot) {

    /// LOADING COMPANY
    if (companySnapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    /// ERROR COMPANY
    if (companySnapshot.hasError) {
      return Center(
        child: Text(companySnapshot.error.toString()),
      );
    }

    /// DATA NULL
    if (!companySnapshot.hasData) {
      return const Center(child: Text("Company not found"));
    }

    final companyId = companySnapshot.data!;

    return StreamBuilder<List<Trip>>(
      stream: tripService.streamTrips(companyId),
      builder: (context, snapshot) {

        /// LOADING TRIPS
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        /// ERROR TRIPS
        if (snapshot.hasError) {
          return Center(
            child: Text(snapshot.error.toString()),
          );
        }

        /// DATA NULL
        if (!snapshot.hasData) {
          return const Center(child: Text("No data"));
        }

        final trips = snapshot.data!;

        if (trips.isEmpty) {
          return const Center(child: Text('No trips yet'));
        }

        return ListView.builder(
          itemCount: trips.length,
          itemBuilder: (context, index) {

            final trip = trips[index];

            return Card(
              margin: const EdgeInsets.all(12),
              child: ListTile(
                title: Text(trip.title),

                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text('${trip.partnerName} • ${trip.country}'),

                    Text(
  'Created by: ${trip.createdByName}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),

                  ],
                ),

                trailing: Text(trip.currency),

                onTap: () async {

                  final userData =
                      await tripService.getCurrentUserData();

                  final uid =
                      FirebaseAuth.instance.currentUser!.uid;

                  final accessLevel = userData['accessLevel'];
                  final List countryIds =
                      userData['countryIds'] ?? [];

                  bool allow = false;

                  if (trip.createdBy == uid) {
                    allow = true;
                  }

                  if (accessLevel == 'admin_countries' &&
                      countryIds.contains(trip.country)) {
                    allow = true;
                  }

                  if (!allow) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'You can only open trips that you created',
                        ),
                      ),
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TripDetailPage(trip: trip),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  },
),

      floatingActionButton: FloatingActionButton(
  onPressed: (){
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateTripPage(),
      ),
    );
  },
  child: const Icon(Icons.add),
     ),
    );
  }
}