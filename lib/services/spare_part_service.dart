import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/spare_part.dart';
import '../core/services/company_firestore.dart';

class SparePartService {
  // Gunakan method yang sudah ada
  Future<QuerySnapshot> fetchSpareParts({
    DocumentSnapshot? lastDoc,
    int limit = 50,
  }) async {
    Query query = CompanyFirestore
        .collection('spare_parts')
        .orderBy('partCode')
        .limit(limit);

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    return await query.get();
  }

  // Stream untuk real-time updates (pertahankan)
  Stream<List<SparePart>> getSpareParts() {
    print("🔥 getSpareParts STREAM ATTACHED");
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
  Future<List<SparePart>> searchSpareParts(String keyword) async {
    try {
      if (keyword.isEmpty) return [];

      final keywordLower = keyword.toLowerCase();
      
      // Method 1: Search by partCode (prefix match)
      QuerySnapshot partCodeSnapshot = await CompanyFirestore
          .collection('spare_parts')
          .where('partCode', isGreaterThanOrEqualTo: keyword)
          .where('partCode', isLessThanOrEqualTo: keyword + '\uf8ff')
          .limit(50)
          .get();

      // Method 2: Search by searchKeywords jika ada
      QuerySnapshot keywordSnapshot = await CompanyFirestore
          .collection('spare_parts')
          .where('searchKeywords', arrayContains: keywordLower)
          .limit(50)
          .get();

      // Gabungkan hasil (hindari duplikat)
      Map<String, SparePart> uniqueParts = {};
      
      for (var doc in partCodeSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        uniqueParts[doc.id] = SparePart.fromMap(data, doc.id);
      }
      
      for (var doc in keywordSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        uniqueParts[doc.id] = SparePart.fromMap(data, doc.id);
      }

      return uniqueParts.values.toList();
    } catch (e) {
      print('Error searching spare parts: $e');
      return [];
    }
  }

  // PERBAIKI: searchSparePartsMore yang sudah ada
  Future<List<SparePart>> searchSparePartsMore({
    required String keyword,
    DocumentSnapshot? lastDoc,
  }) async {
    try {
      if (keyword.isEmpty) return [];

      final keywordLower = keyword.toLowerCase();
      
      Query query = CompanyFirestore
          .collection('spare_parts')
          .where('searchKeywords', arrayContains: keywordLower)
          .orderBy('partCode')
          .limit(50);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return SparePart.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      print('Error searching spare parts with pagination: $e');
      return [];
    }
  }

  // TAMBAHKAN: Search by location
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
      print('Error searching by location: $e');
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
      // Tambahkan searchKeywords otomatis
      final completeData = {...data};
      if (!completeData.containsKey('searchKeywords')) {
        completeData['searchKeywords'] = _generateSearchKeywords(data);
      }
      
      await CompanyFirestore.doc('spare_parts', id).set(completeData);
    } catch (e) {
      print('Error adding spare part: $e');
      rethrow;
    }
  }

  Future<void> updateSparePart(String id, Map<String, dynamic> data) async {
    try {
      // Update searchKeywords jika nama berubah
      final completeData = {...data};
      if (data.containsKey('name') || data.containsKey('nameEn')) {
        // Ambil data existing untuk generate keywords
        final doc = await CompanyFirestore.doc('spare_parts', id).get();
        if (doc.exists) {
          final existingData = doc.data() as Map<String, dynamic>;
          final mergedData = {...existingData, ...data};
          completeData['searchKeywords'] = _generateSearchKeywords(mergedData);
        }
      }
      
      await CompanyFirestore.doc('spare_parts', id).update(completeData);
    } catch (e) {
      print('Error updating spare part: $e');
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
      print('Error deleting spare part: $e');
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
      print('Error checking part code: $e');
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
      print('Error getting spare part: $e');
      return null;
    }
  }
}