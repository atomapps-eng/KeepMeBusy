import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/spare_part.dart';
import '../core/services/company_firestore.dart';
import '../../core/services/firestore_tracker.dart';
import '../core/session/company_session.dart';

class SparePartService {
  // Gunakan method yang sudah ada
  Future<QuerySnapshot> fetchSpareParts({
    DocumentSnapshot? lastDoc,
    int limit = 50,
  }) async {
    Query query = CompanyFirestore
        .collection('spare_parts')
        .orderBy('partCode_lower')
        .limit(limit);

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    return await FirestoreTracker.get(
  query: query,
  page: 'SparePartListPage',
  collection: 'spare_parts',
);
  }

  Future<QuerySnapshot> fetchLowStockParts({
  DocumentSnapshot? lastDoc,
}) async {
  final companyId = CompanySession.currentCompanyId;

  Query query = FirebaseFirestore.instance
      .collection('companies')
      .doc(companyId)
      .collection('spare_parts')
      .where('currentStock', isLessThanOrEqualTo: 0) // 🔥 LOW STOCK
      .orderBy('currentStock')
      .limit(50);

  if (lastDoc != null) {
    query = query.startAfterDocument(lastDoc);
  }

  return await query.get();
}

  // Stream untuk real-time updates (pertahankan)
  Stream<List<SparePart>> getSpareParts() {
    final ref = CompanyFirestore.collection('spare_parts');
    return ref.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return SparePart.fromMap(data, doc.id);
      }).toList();
    });
  }

  // ==================== SEARCH METHODS ====================
  
  // TAMBAHKAN: Search method utama
 Future<QuerySnapshot> searchSpareParts({
  required String keyword,
  DocumentSnapshot? lastDoc,
  int limit = 50,
}) async {

  if (keyword.isEmpty) {
    throw Exception("Keyword cannot be empty");
  }

  final lower = keyword.toLowerCase();
  final end = '$lower\uf8ff';

  final collection = CompanyFirestore.collection('spare_parts');

  // jalankan 3 query paralel
  final results = await Future.wait([
  FirestoreTracker.get(
    query: collection
        .orderBy('partCode_lower')
        .startAt([lower])
        .endAt([end])
        .limit(limit),
    page: 'SparePartSearch',
    collection: 'spare_parts',
  ),

  FirestoreTracker.get(
    query: collection
        .orderBy('name_lower')
        .startAt([lower])
        .endAt([end])
        .limit(limit),
    page: 'SparePartSearch',
    collection: 'spare_parts',
  ),

  FirestoreTracker.get(
    query: collection
        .orderBy('nameEn')
        .startAt([keyword])
        .endAt(['$keyword\uf8ff'])
        .limit(limit),
    page: 'SparePartSearch',
    collection: 'spare_parts',
  ),
]);

  // deduplicate hasil
  final Map<String, QueryDocumentSnapshot> uniqueDocs = {};

  for (var snap in results) {
    for (var doc in snap.docs) {
      uniqueDocs[doc.id] = doc;
    }
  }

  final docs = uniqueDocs.values.toList();

  // kita buat QuerySnapshot fake sederhana
  return _CombinedQuerySnapshot(docs);
}


  // TAMBAHKAN: Search by location//
  Future<List<SparePart>> searchByLocation(String location) async {
    try {
      final normalizedLoc = normalizeLocation(location);
      
      final snapshot = await CompanyFirestore
          .collection('spare_parts')
          .where('location', isEqualTo: location)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return SparePart.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // ==================== EXISTING METHODS ====================
  
  String normalizeLocation(String location) {
    return location
        .trim()
        .toUpperCase()
        .replaceAll(' ', '')
        .replaceAll('.', '-');
  }

  Future<void> addSparePart(String id, Map<String, dynamic> data) async {
  try {
    final docRef = CompanyFirestore.doc('spare_parts', id);
    final existing = await docRef.get();

    if (existing.exists) {
      throw Exception('PartCode sudah ada');
    }

    final partCodeLower = id.toLowerCase();
    final nameLower =
        (data['nameEn'] ?? '').toString().toLowerCase();

    final completeData = {
      ...data,
      'partCode': id,
      'partCode_lower': partCodeLower,
      'name_lower': nameLower,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await docRef.set(completeData);
  } catch (e) {
    rethrow;
  }
}

  Future<void> updateSparePart(String id, Map<String, dynamic> data) async {
  try {
    final docRef = CompanyFirestore.doc('spare_parts', id);
    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      throw Exception('Spare part tidak ditemukan');
    }

    if (data.containsKey('partCode')) {
      throw Exception('PartCode tidak boleh diubah');
    }

    final completeData = {
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (data.containsKey('nameEn')) {
      completeData['name_lower'] =
          data['nameEn'].toString().toLowerCase();
    }

    await docRef.update(completeData);
  } catch (e) {
    rethrow;
  }
}

  Future<void> deleteSparePart(String partCode, String location) async {
    try {
      final locationKey = normalizeLocation(location);
      final batch = FirebaseFirestore.instance.batch();

      final partRef = CompanyFirestore.doc('spare_parts', partCode);
      final locationRef = CompanyFirestore.doc('locations', locationKey);

      batch.delete(partRef);

      // Hapus location jika ada
      final locationSnap = await locationRef.get();
      if (locationSnap.exists) {
        batch.delete(locationRef);
      }

      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  // ==================== HELPER METHODS ====================
  
  List<String> _generateSearchKeywords(Map<String, dynamic> data) {
    Set<String> keywords = {};
    
    // Add partCode
    if (data['partCode'] != null) {
      keywords.add(data['partCode'].toString().toLowerCase());
    }
    
    // Add name
    if (data['name'] != null) {
      final words = data['name'].toString().toLowerCase().split(' ');
      keywords.addAll(words);
    }
    
    // Add nameEn
    if (data['nameEn'] != null) {
      final enWords = data['nameEn'].toString().toLowerCase().split(' ');
      keywords.addAll(enWords);
    }
    
    // Add category
    if (data['category'] != null) {
      keywords.add(data['category'].toString().toLowerCase());
    }
    
    // Add location
    if (data['location'] != null) {
      keywords.add(data['location'].toString().toLowerCase());
    }
    
    return keywords.toList();
  }

  // ==================== UTILITY METHODS ====================
  
  Future<bool> isPartCodeExists(String partCode) async {
    try {
      final doc = await CompanyFirestore.doc('spare_parts', partCode).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  Future<SparePart?> getSparePartByCode(String partCode) async {
    try {
      final doc = await CompanyFirestore.doc('spare_parts', partCode).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return SparePart.fromMap(data, doc.id);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<SparePart?> getByPartCode(String partCode) async {
  try {
    final doc = await CompanyFirestore
        .collection('spare_parts')
        .doc(partCode)
        .get();

    if (!doc.exists) return null;

    return SparePart.fromFirestore(doc);
  } catch (e) {
    print('Error getByPartCode: $e');
    return null;
  }
}

}

class _CombinedQuerySnapshot implements QuerySnapshot {
  final List<QueryDocumentSnapshot> _docs;

  _CombinedQuerySnapshot(this._docs);

  @override
  List<QueryDocumentSnapshot> get docs => _docs;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}