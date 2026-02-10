import 'package:flutter/material.dart';

class DesktopShell extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onMenuSelected;
  final Widget content;
  final Widget sidebarHeader;

  const DesktopShell({
    super.key,
    required this.selectedIndex,
    required this.onMenuSelected,
    required this.content,
    required this.sidebarHeader,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: true,
            minExtendedWidth: 220,
            selectedIndex: selectedIndex,
            onDestinationSelected: onMenuSelected,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: sidebarHeader,
            ),
            destinations: const [
  NavigationRailDestination(
    icon: Icon(Icons.dashboard_rounded),
    label: Text('Dashboard'),
  ),
  NavigationRailDestination(
    icon: Icon(Icons.inventory_2_rounded),
    label: Text('Inventory'),
  ),
  NavigationRailDestination(
    icon: Icon(Icons.build_circle_rounded),
    label: Text('Machinery'),
  ),
  NavigationRailDestination(
    icon: Icon(Icons.bar_chart_rounded),
    label: Text('Reports'),
  ),
  NavigationRailDestination(
    icon: Icon(Icons.settings_rounded),
    label: Text('Settings'),
  ),
],

          ),
          const VerticalDivider(width: 1),
          Expanded(child: content),
        ],
      ),
    );
  }
}
