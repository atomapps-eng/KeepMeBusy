import 'package:cloud_firestore/cloud_firestore.dart';

class SparePartMigration {
  static Future<void> addLowercaseFields() async {


    final collection = FirebaseFirestore.instance
        .collection('companies')
        .doc('atomIndonesia')
        .collection('spare_parts');

    const int batchSize = 400;
    DocumentSnapshot? lastDoc;

    while (true) {
      Query query = collection
          .orderBy(FieldPath.documentId)
          .limit(batchSize);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) break;

      final batch = FirebaseFirestore.instance.batch();

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        final partCode = data['partCode']?.toString() ?? '';
        final nameEn = data['nameEn']?.toString() ?? '';

        batch.update(doc.reference, {
          'partCode_lower': partCode.toLowerCase(),
          'name_lower': nameEn.toLowerCase(),
        });
      }

      await batch.commit();

      lastDoc = snapshot.docs.last;

      if (snapshot.docs.length < batchSize) break;
    }

  }
}