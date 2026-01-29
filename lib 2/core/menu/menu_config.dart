import 'package:flutter/material.dart';

enum MenuCategory {
  inventory,
  machinery,
  reports,
  systems,
}

class MenuConfig {
  final String label;
  final IconData icon;
  final Color color;

  final MenuCategory category;

  // Apakah menu boleh floating
  final bool enableFloating;

  // Apakah menu boleh fullscreen
  final bool enableFullscreen;

  // Builder page tujuan (DITAMBAH searchKeyword)
  final Widget Function({
    required bool isCompact,
    String? searchKeyword,
  }) pageBuilder;

  const MenuConfig({
    required this.label,
    required this.icon,
    required this.color,
    required this.category,
    required this.pageBuilder,
    this.enableFloating = false,
    this.enableFullscreen = false,
  });
}
