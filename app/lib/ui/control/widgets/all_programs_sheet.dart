import 'package:flutter/material.dart';

import '../../../domain/models/touch.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/skill_style.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text.dart';
import 'program_style.dart';
import 'start_menu_sheet.dart';
import 'start_parts.dart';

/// `AllProgramsSheet` (§8, design 2026-11-26.6): cùng khung với Start; đầu nút quay lại 44 (`allProgramsBackA11y`) +
/// `allProgramsTitle` 16/700. Nhóm (`allProgramsGroup*` 12 muted) lưới 4 cột cách 8: ô ≥ 76 bo 14 `panel2`, icon 24 +
/// tên 12, chấm mint 6 góc trên phải = đang mở (`allProgramsOpenLegend`). Cuối: hàng viền đứt
/// `allProgramsAddRemove` → Skill (R-DK-9: chương trình theo skill bật).
class AllProgramsSheet extends StatelessWidget {
  const AllProgramsSheet({
    super.key,
    required this.actions,
    required this.onBack,
    required this.onProgram,
    required this.onAddRemove,
  });

  final StartActions actions;
  final VoidCallback onBack, onAddRemove;
  final ValueChanged<String> onProgram;

  static const _pad = EdgeInsets.fromLTRB(AppSpace.m, 10, AppSpace.m, AppSpace.xl);
  static const _back = 44.0, _titleSize = 16.0, _tileH = 76.0;
  static const _cols = 4;
  static const _addH = 52.0, _dash = 1.5, _small = 11.0;

  /// Skills that come later (named on the Thêm / gỡ row).
  static const _soon = ['chat', 'music'];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final groups = [
      (ProgramGroup.agent, l.allProgramsGroupAgent),
      (ProgramGroup.other, l.allProgramsGroupOther),
      (ProgramGroup.system, l.allProgramsGroupSystem),
    ];
    final shown = [
      for (final (g, label) in groups)
        if ((actions.programs[g] ?? const []).isNotEmpty) (g, label),
    ];
    return Padding(
      padding: _pad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHandle(),
          Row(
            children: [
              SizedBox.square(
                dimension: _back,
                child: IconButton(
                  tooltip: l.allProgramsBackA11y,
                  onPressed: onBack,
                  icon: const Icon(Icons.chevron_left, color: AppColors.ink),
                ),
              ),
              const SizedBox(width: AppSpace.xs),
              Text(
                l.allProgramsTitle,
                style: const TextStyle(
                  fontFamily: AppFonts.family,
                  fontSize: _titleSize,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          for (final (i, (g, label)) in shown.indexed) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.s, 14, AppSpace.s, AppSpace.s),
              child: Row(
                children: [
                  Expanded(
                    child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppFonts.label),
                  ),
                  if (i == shown.length - 1)
                    Text(l.allProgramsOpenLegend, style: AppFonts.label.copyWith(fontSize: _small, letterSpacing: 0)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
              child: GridView.count(
                crossAxisCount: _cols,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpace.s,
                crossAxisSpacing: AppSpace.s,
                mainAxisExtent: _tileH,
                children: [
                  for (final p in actions.programs[g]!)
                    _Tile(
                      program: p,
                      open: actions.open.contains(p),
                      onTap: actions.programsEnabled ? () => onProgram(p) : null,
                    ),
                ],
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.xs, 14, AppSpace.xs, 0),
            child: InkWell(
              onTap: onAddRemove,
              borderRadius: BorderRadius.circular(AppSize.radiusCard),
              child: Container(
                constraints: const BoxConstraints(minHeight: _addH),
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.l),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSize.radiusCard),
                  border: Border.all(color: AppColors.line, width: _dash),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add, size: 22, color: AppColors.clawd),
                    const SizedBox(width: AppSpace.m),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.allProgramsAddRemove, style: AppFonts.body.copyWith(color: AppColors.ink)),
                          Text(
                            l.allProgramsAddRemoveSub(_soon.map((id) => SkillStyle.name(l, id)).join(', ')),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppFonts.label.copyWith(fontSize: _small, letterSpacing: 0),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 20, color: AppColors.muted),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ô chương trình: ≥ 76 bo 14 `panel2`, icon 24 + tên 12 ink cách 6, chấm mint 6 góc trên phải khi [open].
class _Tile extends StatelessWidget {
  const _Tile({required this.program, required this.open, required this.onTap});

  final String program;
  final bool open;
  final VoidCallback? onTap;

  static const _icon = 24.0, _dot = 6.0, _inset = 6.0, _size = 12.0, _disabled = 0.38;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Opacity(
      opacity: onTap == null ? _disabled : 1,
      child: Material(
        color: AppColors.panel2,
        borderRadius: BorderRadius.circular(AppSize.radiusCard),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSize.radiusCard),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ProgramStyle.icon(program, size: _icon),
                    const SizedBox(height: _inset),
                    Text(
                      ProgramStyle.name(l, program),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: AppFonts.family, fontSize: _size, color: AppColors.ink),
                    ),
                  ],
                ),
              ),
              if (open)
                Positioned(
                  top: _inset,
                  right: _inset,
                  child: Semantics(
                    label: l.allProgramsOpenLegend,
                    child: Container(
                      width: _dot,
                      height: _dot,
                      decoration: const BoxDecoration(color: AppColors.mint, shape: BoxShape.circle),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
