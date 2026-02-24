// Buat file baru: services/activity_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';


class ActivityService {
  static const String _key = 'recent_activities';
  
  // Simpan aktivitas baru
  static Future<void> addActivity({
    required IconData icon,
    required String title,
    required Color color,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Ambil aktivitas yang ada
    List<String> activities = prefs.getStringList(_key) ?? [];
    
    // Buat aktivitas baru
    final newActivity = jsonEncode({
      'icon': icon.codePoint, // Simpan kode icon
      'iconFamily': icon.fontFamily,
      'title': title,
      'time': DateTime.now().toIso8601String(),
      'color': color.value, // Simpan nilai warna
    });
    
    // Tambah di awal
    activities.insert(0, newActivity);
    
    // Batasi hanya 10 aktivitas terakhir
    if (activities.length > 10) {
      activities = activities.sublist(0, 10);
    }
    
    await prefs.setStringList(_key, activities);
  }
  
  // Ambil semua aktivitas
  static Future<List<Map<String, dynamic>>> getActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final activities = prefs.getStringList(_key) ?? [];
    
    return activities.map((jsonString) {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Reconstruct IconData
      map['icon'] = IconData(
        map['icon'],
        fontFamily: map['iconFamily'],
      );
      
      // Reconstruct Color
      map['color'] = Color(map['color']);
      
      // Format time
      final time = DateTime.parse(map['time']);
      map['time'] = _formatTimeAgo(time);
      
      return map;
    }).toList();
  }
  
  // Format waktu (misal: "2 minutes ago")
  static String _formatTimeAgo(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}