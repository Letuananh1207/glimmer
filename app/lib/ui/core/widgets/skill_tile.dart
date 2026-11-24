import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../skill_style.dart';
import '../themes/app_colors.dart';
import '../themes/app_text.dart';

/// Kiểu ô skill (screen_specs §6).
enum SkillTileKind { current, available, switching, soon }

/// Ô skill trong lưới màn Skill (components.md `SkillTile`).
class SkillTile extends StatelessWidget {
  const SkillTile({super.key, required this.id, required this.kind, this.onTap});

  final String id;
  final SkillTileKind kind;

  /// null = not tappable (sắp có, hoặc đang đổi skill khác).
  final VoidCallback? onTap;

  static const _pad = 14.0;
  static const _border = 2.0;
  static const _glyph = 28.0;
  static const _clawd = 40.0;
  static const _dot = 8.0;
  static const _dotGap = 6.0;
  static const _spinner = 16.0;
  static const _nameSize = 16.0;
  static const _descLine = 16 / 12;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final style = SkillStyle.of(id);
    final soon = kind == SkillTileKind.soon;
    final name = SkillStyle.name(l, id);
    final tile = Container(
      constraints: const BoxConstraints(minHeight: AppSize.skillTile),
      padding: const EdgeInsets.all(_pad),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(AppSize.radiusSkillTile),
        border: kind == SkillTileKind.current
            ? Border.all(color: style.accent, width: _border)
            : Border.all(color: Colors.transparent, width: _border),
      ),
      foregroundDecoration: kind == SkillTileKind.switching ? _DashedBorder(style.accent) : null,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: AppSize.skillBadge,
          height: AppSize.skillBadge,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: soon ? AppColors.panel2 : style.tint,
            borderRadius: BorderRadius.circular(AppSize.radiusSkillBadge),
          ),
          child: SkillStyle.glyph(id, size: style.icon == null ? _clawd : _glyph,
              color: soon ? AppColors.muted : style.accent),
        ),
        const SizedBox(height: AppSpace.s),
        Text(name,
            style: TextStyle(fontSize: _nameSize, fontWeight: FontWeight.w700,
                color: soon ? AppColors.inkDim : AppColors.ink)),
        const SizedBox(height: AppSpace.s),
        Text(SkillStyle.description(l, id),
            style: AppFonts.label.copyWith(letterSpacing: 0, height: _descLine)),
        const SizedBox(height: AppSpace.s),
        switch (kind) {
          SkillTileKind.current => Row(children: [
              Container(width: _dot, height: _dot, decoration: BoxDecoration(color: style.accent, shape: BoxShape.circle)),
              const SizedBox(width: _dotGap),
              Text(l.skillsCurrent, style: AppFonts.label.copyWith(color: AppColors.ink, letterSpacing: 0)),
            ]),
          SkillTileKind.available => Text(l.skillsUse,
              style: AppFonts.navLabel.copyWith(color: style.accent)),
          SkillTileKind.switching => Row(children: [
              const SizedBox.square(dimension: _spinner, child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: _dotGap),
              Text(l.skillsSwitching, style: AppFonts.label.copyWith(color: AppColors.ink, letterSpacing: 0)),
            ]),
          SkillTileKind.soon => Text(l.skillsSoon, style: AppFonts.label),
        },
      ]),
    );
    return Semantics(
      button: onTap != null,
      label: kind == SkillTileKind.current ? l.skillsCurrentA11y(name) : null,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSize.radiusSkillTile),
          onTap: onTap,
          child: tile,
        ),
      ),
    );
  }
}

/// Dashed 2-px border (the tile being switched to).
class _DashedBorder extends Decoration {
  const _DashedBorder(this.color);
  final Color color;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _DashedPainter(color);
}

class _DashedPainter extends BoxPainter {
  _DashedPainter(this.color);
  final Color color;

  static const _dash = 6.0, _gap = 4.0;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration cfg) {
    final rect = (offset & cfg.size!).deflate(1);
    final path = Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(AppSize.radiusSkillTile)));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += _dash + _gap) {
        canvas.drawPath(m.extractPath(d, d + _dash), paint);
      }
    }
  }
}
