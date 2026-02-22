import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/services/company_firestore.dart';

class MigrationEngine {
  static const String targetCompany = 'atomIndonesia';

  static Future<void> migrateCollection(String collectionName) async {
    final db = FirebaseFirestore.instance;

    final snapshot = await db.collection(collectionName).get();

    const int batchLimit = 400;
    int operationCount = 0;
    WriteBatch batch = db.batch();

    for (var doc in snapshot.docs) {
      final targetRef = db
          .collection('companies')
          .doc(targetCompany)
          .collection(collectionName)
          .doc(doc.id);

      batch.set(targetRef, doc.data(), SetOptions(merge: false));

      operationCount++;

      if (operationCount >= batchLimit) {
        await batch.commit();
        batch = db.batch();
        operationCount = 0;
      }
    }

    if (operationCount > 0) {
      await batch.commit();
    }
  }
 static Future<void> runFullMigration() async {
  final collections = [
    'partners',
    'locations',
    'attendance_periods',
    'spare_parts',
    'order_in',
    'order_out',
  ];

  for (final name in collections) {
    await migrateCollection(name);
  }

  // Attendance pakai handler khusus
  await migrateAttendance();

}
static Future<void> migrateAttendance() async {

  final users = await CompanyFirestore.collection('attendance').get();

  for (final userDoc in users.docs) {
    final userId = userDoc.id;

    final targetUserRef = CompanyFirestore
        .collection('companies')
        .doc(targetCompany)
        .collection('attendance')
        .doc(userId);

    // Create empty parent doc supaya subcollection bisa attach
    await targetUserRef.set({}, SetOptions(merge: true));

    // ---- MIGRATE DAYS ----
    final daysSnapshot = await userDoc.reference.collection('days').get();
    for (final dayDoc in daysSnapshot.docs) {
      await targetUserRef
          .collection('days')
          .doc(dayDoc.id)
          .set(dayDoc.data());
    }

    // ---- MIGRATE OVERNIGHT ----
    final overnightSnapshot =
        await userDoc.reference.collection('overnight').get();
    for (final overnightDoc in overnightSnapshot.docs) {
      await targetUserRef
          .collection('overnight')
          .doc(overnightDoc.id)
          .set(overnightDoc.data());
    }

  }
  
}
}