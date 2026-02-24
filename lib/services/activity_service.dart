import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class ActivityService {
  static const String _key = 'recent_activities';

  // 🔹 Mapping icon yang diizinkan (CONST)
  static const Map<String, IconData> _iconMap = {
    'home': Icons.home,
    'settings': Icons.settings,
    'inventory': Icons.inventory,
    'build': Icons.build,
    'person': Icons.person,
    'add': Icons.add,
    'delete': Icons.delete,
    'edit': Icons.edit,
  };

  /// Convert IconData ke string name
  static String _iconToString(IconData icon) {
    return _iconMap.entries
        .firstWhere(
          (entry) => entry.value == icon,
          orElse: () => const MapEntry('help', Icons.help_outline),
        )
        .key;
  }

  /// Convert string ke IconData (CONST SAFE)
  static IconData _stringToIcon(String name) {
    return _iconMap[name] ?? Icons.help_outline;
  }

  // ===============================
  // Tambah aktivitas
  // ===============================
  static Future<void> addActivity({
    required IconData icon,
    required String title,
    required Color color,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    List<String> activities = prefs.getStringList(_key) ?? [];

    final newActivity = jsonEncode({
      'icon': _iconToString(icon), // 🔥 Simpan string, bukan codePoint
      'title': title,
      'time': DateTime.now().toIso8601String(),
      'color': color.value,
    });

    activities.insert(0, newActivity);

    if (activities.length > 10) {
      activities = activities.sublist(0, 10);
    }

    await prefs.setStringList(_key, activities);
  }

  // ===============================
  // Ambil aktivitas
  // ===============================
  static Future<List<Map<String, dynamic>>> getActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final activities = prefs.getStringList(_key) ?? [];

    return activities.map((jsonString) {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;

      map['icon'] = _stringToIcon(map['icon']); // 🔥 SAFE
      map['color'] = Color(map['color']);

      final time = DateTime.parse(map['time']);
      map['time'] = _formatTimeAgo(time);

      return map;
    }).toList();
  }

  // ===============================
  // Format waktu
  // ===============================
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