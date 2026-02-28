// lib/core/cache/company_cache.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyCache {
  static final CompanyCache _instance = CompanyCache._internal();
  factory CompanyCache() => _instance;
  CompanyCache._internal();

  // Cache untuk partners
  List<Map<String, dynamic>>? _cachedPartners;
  DateTime? _partnersLastFetch;
  
  // Cache untuk spare parts
  List<Map<String, dynamic>>? _cachedSpareParts;
  DateTime? _sparePartsLastFetch;
  
  // Cache untuk technicians
  List<String>? _cachedTechnicians;
  DateTime? _techniciansLastFetch;

  static const Duration _cacheDuration = Duration(minutes: 10);

  // ========== PARTNERS CACHE ==========
  Future<List<Map<String, dynamic>>> getPartners(String companyId) async {
    // Cek cache
    if (_isPartnersCacheValid()) {
      print("📦 Menggunakan cached partners");
      return _cachedPartners!;
    }

    // Fetch dari Firestore
    print("📦 Fetching partners from Firestore");
    final snapshot = await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('partners')
        .orderBy('name')
        .get();

    _cachedPartners = snapshot.docs.map((doc) => doc.data()).toList();
    _partnersLastFetch = DateTime.now();
    
    return _cachedPartners!;
  }

  bool _isPartnersCacheValid() {
    if (_cachedPartners == null || _partnersLastFetch == null) return false;
    return DateTime.now().difference(_partnersLastFetch!) < _cacheDuration;
  }

  // ========== SPARE PARTS CACHE ==========
  Future<List<Map<String, dynamic>>> getSpareParts(String companyId) async {
    if (_isSparePartsCacheValid()) {
      print("📦 Menggunakan cached spare parts");
      return _cachedSpareParts!;
    }

    print("📦 Fetching spare parts from Firestore");
    final snapshot = await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('spare_parts')
        .orderBy('name')
        .get();

    _cachedSpareParts = snapshot.docs.map((doc) => doc.data()).toList();
    _sparePartsLastFetch = DateTime.now();
    
    return _cachedSpareParts!;
  }

  bool _isSparePartsCacheValid() {
    if (_cachedSpareParts == null || _sparePartsLastFetch == null) return false;
    return DateTime.now().difference(_sparePartsLastFetch!) < _cacheDuration;
  }

  // ========== TECHNICIANS CACHE ==========
  Future<List<String>> getTechnicians(String companyId) async {
    if (_isTechniciansCacheValid()) {
      print("📦 Menggunakan cached technicians");
      return _cachedTechnicians!;
    }

    print("📦 Fetching technicians from Firestore");
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('companyIds', arrayContains: companyId)
        .where('position', isEqualTo: 'technician')
        .where('active', isEqualTo: true)
        .get();

    _cachedTechnicians = snapshot.docs
        .map((doc) => doc.data()['username']?.toString() ?? '')
        .where((name) => name.isNotEmpty)
        .toList();
    
    _techniciansLastFetch = DateTime.now();
    
    return _cachedTechnicians!;
  }

  bool _isTechniciansCacheValid() {
    if (_cachedTechnicians == null || _techniciansLastFetch == null) return false;
    return DateTime.now().difference(_techniciansLastFetch!) < _cacheDuration;
  }

  // ========== CLEAR CACHE ==========
  void clearAll() {
    _cachedPartners = null;
    _partnersLastFetch = null;
    _cachedSpareParts = null;
    _sparePartsLastFetch = null;
    _cachedTechnicians = null;
    _techniciansLastFetch = null;
    print("📦 All company caches cleared");
  }

  void clearPartners() {
    _cachedPartners = null;
    _partnersLastFetch = null;
  }

  void clearSpareParts() {
    _cachedSpareParts = null;
    _sparePartsLastFetch = null;
  }

  void clearTechnicians() {
    _cachedTechnicians = null;
    _techniciansLastFetch = null;
  }

   // Method untuk set spare parts langsung
  void setSpareParts(List<Map<String, dynamic>> parts) {
    _cachedSpareParts = parts;
    _sparePartsLastFetch = DateTime.now();
    print("📦 Spare parts cache updated with ${parts.length} items");
  }

  // Method untuk append spare parts
  void appendSpareParts(List<Map<String, dynamic>> newParts) {
    if (_cachedSpareParts == null) {
      _cachedSpareParts = [];
    }
    _cachedSpareParts!.addAll(newParts);
    _sparePartsLastFetch = DateTime.now();
    print("📦 Appended ${newParts.length} items to spare parts cache");
  }

  // Method untuk update single spare part
  void updateSparePart(String partCode, Map<String, dynamic> updatedData) {
    if (_cachedSpareParts == null) return;
    
    final index = _cachedSpareParts!.indexWhere(
      (part) => part['partCode'] == partCode || part['id'] == partCode
    );
    
    if (index != -1) {
      _cachedSpareParts![index] = {..._cachedSpareParts![index], ...updatedData};
      print("📦 Updated spare part in cache: $partCode");
    }
  }

  // Method untuk remove spare part dari cache
  void removeSparePart(String partCode) {
    if (_cachedSpareParts == null) return;
    
    _cachedSpareParts!.removeWhere(
      (part) => part['partCode'] == partCode || part['id'] == partCode
    );
    print("📦 Removed spare part from cache: $partCode");
  }
}
