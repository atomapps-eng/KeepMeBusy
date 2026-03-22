// lib/core/cache/user_cache.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';

class UserCache {
  // Singleton pattern
  static final UserCache _instance = UserCache._internal();
  factory UserCache() => _instance;
  UserCache._internal();

  // Data cache
  UserModel? _currentUser;
  DateTime? _lastFetch;
  
  // Durasi cache (5 menit)
  static const Duration _cacheDuration = Duration(minutes: 5);

  // 🔥 METHOD BARU: Set user langsung ke cache
  Future<void> setUser(UserModel user) async {
    _currentUser = user;
    _lastFetch = DateTime.now();
  }

  // Get user dari cache atau Firestore
  Future<UserModel> getUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not authenticated");

    // Cek apakah cache masih valid
    if (_isCacheValid()) {
      return _currentUser!;
    }

    // Ambil dari Firestore
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!userDoc.exists) {
      throw Exception("User document not found");
    }

    _currentUser = UserModel.fromFirestore(userDoc);
    _lastFetch = DateTime.now();
    
    return _currentUser!;
  }

  // Cek apakah cache masih valid
  bool _isCacheValid() {
    if (_currentUser == null || _lastFetch == null) return false;
    
    final age = DateTime.now().difference(_lastFetch!);
    return age < _cacheDuration;
  }

  // Clear cache (panggil saat logout)
  void clear() {
    _currentUser = null;
    _lastFetch = null;
  }

  // Force refresh (panggil setelah update profile)
  Future<UserModel> refreshUser() async {
    clear();
    return await getUser();
  }

  // Get current user tanpa fetch (synchronous)
  UserModel? get currentUser => _currentUser;
}