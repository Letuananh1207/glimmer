import 'package:flutter/material.dart';

import '../themes/app_colors.dart';
import '../themes/app_text.dart';

/// Dòng skill trong thẻ danh sách màn Skill (components.md `SkillRow`, screen_specs §6): ô icon 44 bo 12 + 14 +
/// tên 16/700 / mô tả 12 một dòng + phần bên phải ([trailing]: `SkillSwitch`, vòng xoay hoặc ổ khoá). Cao ≥ 72.
class SkillRow extends StatelessWidget {
  const SkillRow({
    super.key,
    required this.icon,
    required this.on,
    required this.tint,
    required this.name,
    required this.description,
    this.descriptionColor = AppColors.muted,
    this.descriptionLines = 1,
    required this.trailing,
  });

  /// Pixel icon, already coloured (accent when on, muted when off).
  final Widget icon;

  /// On: icon box `skill…Tint`, name ink. Off: icon box `panel2`, name inkDim.
  final bool on;
  final Color tint;
  final String name;
  final String description;
  final Color descriptionColor;

  /// Lines the description may take (one; the Ảnh hint wraps to two).
  final int descriptionLines;
  final Widget trailing;

  static const _pad = EdgeInsets.symmetric(vertical: 10);
  static const _gap = 14.0;
  static const _nameSize = 16.0;
  static const _descSize = 12.0;
  static const _descLine = 16 / 12;
  static const _trailingNudge = -4.0; // the 60-wide tap area hangs 4 into the card padding

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSize.skillRow),
        child: Padding(
          padding: _pad,
          child: Row(children: [
            Container(
              width: AppSize.skillIcon,
              height: AppSize.skillIcon,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on ? tint : AppColors.panel2,
                borderRadius: BorderRadius.circular(AppSize.radiusSkillBadge),
              ),
              child: icon,
            ),
            const SizedBox(width: _gap),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(name,
                    style: TextStyle(
                        fontSize: _nameSize, fontWeight: FontWeight.w700, color: on ? AppColors.ink : AppColors.inkDim)),
                const SizedBox(height: 2),
                Text(description,
                    maxLines: descriptionLines,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: _descSize, height: _descLine, color: descriptionColor)),
              ]),
            ),
            Transform.translate(offset: const Offset(-_trailingNudge, 0), child: trailing),
          ]),
        ),
      );
}
