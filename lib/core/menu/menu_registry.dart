import 'package:flutter/material.dart';

import '../../pages/spare_part/spare_part_list_page.dart';
import '../../pages/common/placeholder_page.dart';
import 'menu_config.dart';

final List<MenuConfig> inventoryMenus = [
  // ===== DATABASE =====
  MenuConfig(
    label: 'Database',
    icon: Icons.inventory,
    color: Colors.blueGrey,
    category: MenuCategory.inventory,
    enableFloating: true,
    enableFullscreen: true,
    pageBuilder: ({
      required bool isCompact,
      String? searchKeyword,
    }) {
      return SparePartListPage(
  isCompact: isCompact,
  searchKeyword: searchKeyword,
);

    },
  ),

  // ===== ORDERS IN =====
  MenuConfig(
    label: 'Orders In',
    icon: Icons.input,
    color: Colors.green,
    category: MenuCategory.inventory,
    enableFloating: true,
    enableFullscreen: true,
    pageBuilder: ({
      required bool isCompact,
      String? searchKeyword,
    }) {
      return const PlaceholderPage(title: 'Orders In');
    },
  ),

  // ===== ORDERS OUT =====
  MenuConfig(
    label: 'Orders Out',
    icon: Icons.output,
    color: Colors.redAccent,
    category: MenuCategory.inventory,
    enableFloating: true,
    enableFullscreen: true,
    pageBuilder: ({
      required bool isCompact,
      String? searchKeyword,
    }) {
      return const PlaceholderPage(title: 'Orders Out');
    },
  ),

  // ===== PARTNERS =====
  MenuConfig(
    label: 'Partners',
    icon: Icons.groups,
    color: Colors.deepPurple,
    category: MenuCategory.inventory,
    enableFloating: true,
    enableFullscreen: true,
    pageBuilder: ({
      required bool isCompact,
      String? searchKeyword,
    }) {
      return const PlaceholderPage(title: 'Partners');
    },
  ),
];

final List<MenuConfig> machineryMenus = [
  // ===== MACHINE LIST =====
  MenuConfig(
    label: 'Machine List',
    icon: Icons.list,
    color: Colors.pinkAccent,
    category: MenuCategory.machinery,
    enableFloating: true,
    enableFullscreen: true,
    pageBuilder: ({
      required bool isCompact,
      String? searchKeyword,
    }) {
      return const PlaceholderPage(title: 'Machine List');
    },
  ),

  // ===== MACHINE MANUAL =====
  MenuConfig(
    label: 'Machine Manual',
    icon: Icons.menu_book,
    color: Colors.teal,
    category: MenuCategory.machinery,
    enableFloating: true,
    enableFullscreen: true,
    pageBuilder: ({
      required bool isCompact,
      String? searchKeyword,
    }) {
      return const PlaceholderPage(title: 'Machine Manual');
    },
  ),

  // ===== MACHINE CATALOGUE =====
  MenuConfig(
    label: 'Machine Catalogue',
    icon: Icons.auto_stories,
    color: Colors.indigo,
    category: MenuCategory.machinery,
    enableFloating: true,
    enableFullscreen: true,
    pageBuilder: ({
      required bool isCompact,
      String? searchKeyword,
    }) {
      return const PlaceholderPage(title: 'Machine Catalogue');
    },
  ),

  // ===== LICENSES =====
  MenuConfig(
    label: 'Licenses',
    icon: Icons.verified,
    color: Colors.orange,
    category: MenuCategory.machinery,
    enableFloating: true,
    enableFullscreen: true,
    pageBuilder: ({
      required bool isCompact,
      String? searchKeyword,
    }) {
      return const PlaceholderPage(title: 'Licenses');
    },
  ),
];

final List<MenuConfig> reportsMenus = [
  // ===== DAILY ATTENDANCE =====
  MenuConfig(
    label: 'Daily Attendance',
    icon: Icons.event_available,
    color: Colors.blue,
    category: MenuCategory.reports,
    enableFloating: true,
    enableFullscreen: true,
    pageBuilder: ({
      required bool isCompact,
      String? searchKeyword,
    }) {
      return const PlaceholderPage(title: 'Daily Attendance');
    },
  ),

  // ===== SERVICE REPORT =====
  MenuConfig(
    label: 'Service Report',
    icon: Icons.build_circle,
    color: Colors.green,
    category: MenuCategory.reports,
    enableFloating: true,
    enableFullscreen: true,
    pageBuilder: ({
      required bool isCompact,
      String? searchKeyword,
    }) {
      return const PlaceholderPage(title: 'Service Report');
    },
  ),

  // ===== BUSINESS TRIP REPORT =====
  MenuConfig(
    label: 'Business Trip Report',
    icon: Icons.flight_takeoff,
    color: Colors.purple,
    category: MenuCategory.reports,
    enableFloating: true,
    enableFullscreen: true,
    pageBuilder: ({
      required bool isCompact,
      String? searchKeyword,
    }) {
      return const PlaceholderPage(
          title: 'Business Trip Report');
    },
  ),
];
