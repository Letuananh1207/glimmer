import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/skill_style.dart';
import '../../core/themes/app_colors.dart';
import '../../core/widgets/clawd.dart';

/// Khung 4 tab (components.md "Thanh điều hướng dưới", 2026-11-25.2): màn chính của skill đang dùng · Skill ·
/// Cài đặt · Thiết bị.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.skill, required this.index, required this.onSelect, required this.child});

  /// Skill đang dùng — nhãn + icon của tab 1.
  final String skill;
  final int index;
  final ValueChanged<int> onSelect;
  final Widget child;

  static const _icon = 24.0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: onSelect,
        destinations: [
          NavigationDestination(
            // Agent: Clawd without eyes; filled with the skill accent when selected.
            icon: SkillStyle.glyph(skill, size: _icon, color: AppColors.ink, mood: ClawdMood.sleep),
            selectedIcon:
                SkillStyle.glyph(skill, size: _icon, color: SkillStyle.of(skill).accent, mood: ClawdMood.sleep),
            label: SkillStyle.name(l, skill),
          ),
          NavigationDestination(icon: const Icon(Icons.apps), label: l.navSkills),
          NavigationDestination(icon: const Icon(Icons.tune), label: l.navSettings),
          NavigationDestination(icon: const Icon(Icons.memory), label: l.navDevice),
        ],
      ),
    );
  }
}
