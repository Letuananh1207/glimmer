import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Khung 3 tab (Tổng quan, Cài đặt, Thiết bị) với thanh điều hướng dưới.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.index, required this.onSelect, required this.child});

  final int index;
  final ValueChanged<int> onSelect;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: onSelect,
        destinations: [
          NavigationDestination(icon: const Icon(Icons.dashboard_outlined), label: l.navDashboard),
          NavigationDestination(icon: const Icon(Icons.tune), label: l.navSettings),
          NavigationDestination(icon: const Icon(Icons.memory), label: l.navDevice),
        ],
      ),
    );
  }
}
