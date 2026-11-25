import 'package:flutter/material.dart';

import '../themes/app_colors.dart';
import '../themes/app_text.dart';

/// Amber count badge, bo 4, số 700 màu `bg` (components.md: `DockTabBar` tab Agent 18 / 11, thanh dưới 16 / 10).
class CountBadge extends StatelessWidget {
  const CountBadge(this.text, {super.key, this.small = false});

  /// Already formatted ("2", "9+").
  final String text;

  /// Bottom-nav size (16, số 10) instead of the dock-tab size (18, số 11).
  final bool small;

  static const _side = 18.0, _sideSmall = 16.0;
  static const _font = 11.0, _fontSmall = 10.0;
  static const _padH = 4.0;

  @override
  Widget build(BuildContext context) {
    final side = small ? _sideSmall : _side;
    return ExcludeSemantics(
      child: Container(
        constraints: BoxConstraints(minWidth: side),
        height: side,
        padding: const EdgeInsets.symmetric(horizontal: _padH),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.amber,
          borderRadius: BorderRadius.circular(AppSize.radiusBadge),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: AppFonts.family,
            fontSize: small ? _fontSmall : _font,
            fontWeight: FontWeight.w700,
            height: 1,
            color: AppColors.bg,
          ),
        ),
      ),
    );
  }
}
