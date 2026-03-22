// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/cache/user_cache.dart';
import '../core/cache/company_cache.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔥 PERTAHANKAN: Stream untuk auth state
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 🔥 PERTAHANKAN: Current user getter
  User? get currentUser => _auth.currentUser;

  // ========== LOGIN ==========
  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      // Login dulu
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Clear cache sebelum login baru
      UserCache().clear();
      CompanyCache().clearAll();

      // Ambil data user dan simpan di cache
      await _loadUserToCache();

    } catch (e) {
      rethrow;
    }
  }

  // ========== REGISTER ==========
  Future<void> register({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      // Register ke Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await credential.user!.updateDisplayName(username);

      // Buat document user di Firestore
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'username': username,
        'email': email,
        'role': 'user', // Default role
        'companyIds': [], // Empty array initially
        'position': '',
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

    } catch (e) {
      rethrow;
    }
  }

  // ========== SEND PASSWORD RESET ==========
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  // ========== LOGOUT ==========
  Future<void> logout() async {
    try {
      // Clear semua cache sebelum logout
      UserCache().clear();
      CompanyCache().clearAll();
      
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // ========== LOAD USER DATA TO CACHE ==========
  Future<UserModel> _loadUserToCache() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("No user logged in");

    // Ambil data dari Firestore
    final userDoc = await _firestore.collection('users').doc(user.uid).get();

    if (!userDoc.exists) {
      throw Exception("User document not found in Firestore");
    }

    // Konversi ke UserModel
    final userModel = UserModel.fromFirestore(userDoc);
    
    // 🔥 GUNAKAN METHOD setUser
    await UserCache().setUser(userModel);
    
    return userModel;
  }

  // ========== GET CURRENT USER WITH CACHE ==========
  Future<UserModel?> getCurrentUserModel() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      // Coba ambil dari cache dulu
      return await UserCache().getUser();
    } catch (e) {
      // Jika gagal, load dari Firestore
      return await _loadUserToCache();
    }
  }

  // ========== REFRESH USER DATA ==========
  Future<UserModel> refreshUserData() async {
    // Force refresh dari Firestore
    final userModel = await _loadUserToCache();
    return userModel;
  }
}