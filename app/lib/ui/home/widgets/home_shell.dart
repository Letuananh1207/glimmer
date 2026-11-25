import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/widgets/count_badge.dart';
import '../../core/widgets/nav_home_icon.dart';

/// Khung 4 tab (components.md "Thanh điều hướng dưới", 2026-11-25.3): Màn hình (huy hiệu agent chờ) · Skill ·
/// Cài đặt · Thiết bị.
class HomeShell extends StatelessWidget {
  const HomeShell({
    super.key,
    required this.waiting,
    required this.badge,
    required this.index,
    required this.onSelect,
    required this.child,
  });

  /// Agents waiting (approval + input), for the screen reader.
  final int waiting;

  /// Badge text ("2", "9+"); null hides it.
  final String? badge;
  final int index;
  final ValueChanged<int> onSelect;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final home = _HomeIcon(badge: badge);
    return Scaffold(
      body: SafeArea(child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: onSelect,
        destinations: [
          NavigationDestination(
            icon: badge == null
                ? home
                : Semantics(label: l.navHomeBadgeA11y('$waiting'), child: home),
            label: l.navHome,
          ),
          NavigationDestination(icon: const Icon(Icons.apps), label: l.navSkills),
          NavigationDestination(icon: const Icon(Icons.tune), label: l.navSettings),
          NavigationDestination(icon: const Icon(Icons.memory), label: l.navDevice),
        ],
      ),
    );
  }
}

/// nav-home icon 24 with the amber badge at the icon's top right: top −2, left 38 in the 64 × 32 pill → (−6, 18)
/// from the icon's corner (icon centred: left 20, top 4).
class _HomeIcon extends StatelessWidget {
  const _HomeIcon({required this.badge});

  final String? badge;

  static const _icon = 24.0;
  static const _badgeTop = -6.0;
  static const _badgeLeft = 18.0;

  @override
  Widget build(BuildContext context) => Stack(clipBehavior: Clip.none, children: [
        const NavHomeIcon(size: _icon),
        if (badge != null) Positioned(top: _badgeTop, left: _badgeLeft, child: CountBadge(badge!, small: true)),
      ]);
}
