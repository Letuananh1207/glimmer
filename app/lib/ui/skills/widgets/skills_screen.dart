import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/skill_style.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text.dart';
import '../../core/widgets/skill_row.dart';
import '../../core/widgets/skill_switch.dart';
import '../../core/widgets/status_banner.dart';
import '../view_models/skills_view_model.dart';

/// Màn Skill — tab 2 (screen_specs §6, 2026-11-25.3): danh sách công tắc skill theo dock + chip "Sắp có".
class SkillsScreen extends StatelessWidget {
  const SkillsScreen({super.key, required this.viewModel, required this.onOpenDevice});

  final SkillsViewModel viewModel;

  /// Firmware cũ → tab Thiết bị.
  final VoidCallback onOpenDevice;

  static const _cardMargin = EdgeInsets.symmetric(horizontal: AppSpace.l, vertical: 6);
  static const _cardPad = EdgeInsets.symmetric(horizontal: AppSpace.l, vertical: AppSpace.xs);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final rows = viewModel.rows;
        return ListView(padding: const EdgeInsets.only(bottom: AppSpace.l), children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.xl, AppSpace.l, AppSpace.xl, AppSpace.s),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.skillsTitle, style: AppFonts.screenTitle.copyWith(color: AppColors.ink)),
              const SizedBox(height: AppSpace.xs),
              Text(l.skillsSubtitle, style: AppFonts.label),
            ]),
          ),
          ?_banner(l),
          Container(
            margin: _cardMargin,
            padding: _cardPad,
            decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(AppSize.radiusCard)),
            child: Column(children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const Divider(height: AppSize.hairline, thickness: AppSize.hairline, color: AppColors.line),
                _Row(
                  row: rows[i],
                  onChanged: (v) => viewModel.toggle(rows[i].id, enable: v),
                  onOpenDevice: onOpenDevice,
                ),
              ],
            ]),
          ),
          if (viewModel.showOrderNote) const _OrderNote(),
          _Soon(ids: viewModel.soon),
        ]);
      },
    );
  }

  Widget? _banner(AppLocalizations l) {
    final f = viewModel.failed;
    return switch (viewModel.banner) {
      null => null,
      SkillsBanner.error when f != null => StatusBanner(
          title: f.enable
              ? l.skillsErrorOnTitle(SkillStyle.name(l, f.id))
              : l.skillsErrorOffTitle(SkillStyle.name(l, f.id)),
          titleColor: AppColors.coral,
          body: f.enable
              ? l.skillsErrorOnBody(SkillStyle.name(l, f.id))
              : l.skillsErrorOffBody(SkillStyle.name(l, f.id)),
          trailing: TextButton(onPressed: viewModel.retry, child: Text(l.commonRetry)),
        ),
      SkillsBanner.error => null,
      SkillsBanner.legacy => StatusBanner(
          title: l.skillsLegacyTitle,
          titleColor: AppColors.amber,
          body: l.skillsLegacyBody(viewModel.firmware),
          action: OutlinedButton.icon(
            onPressed: onOpenDevice,
            icon: const Icon(Icons.system_update),
            label: Text(l.deviceUpdateFw),
          ),
        ),
    };
  }
}

/// One `SkillRow` with what its mode puts on the right and in the description.
class _Row extends StatelessWidget {
  const _Row({required this.row, required this.onChanged, required this.onOpenDevice});

  final SkillRowData row;
  final ValueChanged<bool> onChanged;
  final VoidCallback onOpenDevice;

  static const _spinner = 24.0;
  static const _spinnerStroke = 3.0;
  static const _lock = 20.0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final style = SkillStyle.of(row.id);
    final name = SkillStyle.name(l, row.id);
    final (desc, descColor) = switch (row.mode) {
      SkillRowMode.sending => (l.skillsSending, AppColors.inkDim),
      SkillRowMode.lastOne => (l.skillsLastOne, AppColors.amber),
      SkillRowMode.alwaysOn => (l.skillsAlwaysOn, AppColors.muted),
      SkillRowMode.needsFirmware => (l.skillsNeedFirmware, AppColors.amber),
      _ when row.photoHint > 0 => (l.skillsPhotoHint(row.photoHint), AppColors.skillPhoto),
      _ => (SkillStyle.description(l, row.id), AppColors.muted),
    };
    final Widget trailing = switch (row.mode) {
      SkillRowMode.sending => SizedBox(
          width: SkillSwitch.tapW,
          height: SkillSwitch.tapH,
          child: Center(
            child: Semantics(
              label: l.skillsSending,
              child: const SizedBox.square(
                dimension: _spinner,
                child: CircularProgressIndicator(strokeWidth: _spinnerStroke, color: AppColors.clawd),
              ),
            ),
          ),
        ),
      SkillRowMode.legacyLocked => const SizedBox.square(
          dimension: SkillSwitch.tapH,
          child: Icon(Icons.lock_outline, size: _lock, color: AppColors.muted),
        ),
      SkillRowMode.alwaysOn => const SizedBox.shrink(),
      SkillRowMode.needsFirmware => _UpdateFirmwareButton(onPressed: onOpenDevice),
      _ => SkillSwitch(
          value: row.on,
          accent: style.accent,
          label: l.skillsToggleA11y(name),
          onChanged: row.enabled ? onChanged : null,
        ),
    };
    return SkillRow(
      icon: SkillStyle.dockIcon(row.id, color: row.on ? style.accent : AppColors.muted),
      on: row.on,
      tint: style.tint,
      name: name,
      description: desc,
      descriptionColor: descColor,
      descriptionLines: row.photoHint > 0 ? 2 : 1,
      trailing: trailing,
    );
  }
}

/// `photoFw`: nút viền ≥ 44 bo 22 (viền `line`, icon tải firmware 16 + `skillsUpdateFirmware` 13/500 `clawd`)
/// → tab Thiết bị, thay công tắc.
class _UpdateFirmwareButton extends StatelessWidget {
  const _UpdateFirmwareButton({required this.onPressed});

  final VoidCallback onPressed;

  static const _pad = EdgeInsets.symmetric(horizontal: 14);
  static const _radius = 22.0;
  static const _icon = 16.0;
  static const _gap = 6.0;
  static const _text = 13.0;

  @override
  Widget build(BuildContext context) => OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(AppSize.tapMin, AppSize.tapMin),
          padding: _pad,
          foregroundColor: AppColors.clawd,
          side: const BorderSide(color: AppColors.line, width: AppSize.hairline),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius)),
          textStyle: const TextStyle(fontFamily: AppFonts.family, fontSize: _text, fontWeight: FontWeight.w500),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.system_update, size: _icon, color: AppColors.clawd),
          const SizedBox(width: _gap),
          Text(AppLocalizations.of(context).skillsUpdateFirmware),
        ]),
      );
}

/// Dưới thẻ: ô vuông 8 amber + `skillsOrderNote` (R-SK-3).
class _OrderNote extends StatelessWidget {
  const _OrderNote();

  static const _square = 8.0;
  static const _pad = EdgeInsets.fromLTRB(AppSpace.xl, 6, AppSpace.xl, 0);
  static const _squareTop = 4.0; // centre the square on the first 16-px line
  static const _line = 16 / 12;

  @override
  Widget build(BuildContext context) => Padding(
        padding: _pad,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(
            padding: EdgeInsets.only(top: _squareTop),
            child: SizedBox.square(dimension: _square, child: ColoredBox(color: AppColors.amber)),
          ),
          const SizedBox(width: AppSpace.s),
          Expanded(
            child: Text(AppLocalizations.of(context).skillsOrderNote,
                style: AppFonts.label.copyWith(letterSpacing: 0, height: _line)),
          ),
        ]),
      );
}

/// `skillsSoonTitle` + chip "Sắp có" (không bấm được).
class _Soon extends StatelessWidget {
  const _Soon({required this.ids});

  final List<String> ids;

  static const _titlePad = EdgeInsets.fromLTRB(AppSpace.xl, 14, AppSpace.xl, AppSpace.xs);
  static const _chipsPad = EdgeInsets.fromLTRB(AppSpace.l, AppSpace.xs, AppSpace.l, 0);
  static const _chipPad = EdgeInsets.only(left: 10, right: AppSpace.m);
  static const _icon = 16.0;
  static const _text = 13.0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: _titlePad, child: Text(l.skillsSoonTitle, style: AppFonts.label)),
      Padding(
        padding: _chipsPad,
        child: Wrap(spacing: AppSpace.s, runSpacing: AppSpace.s, children: [
          for (final id in ids)
            Container(
              height: AppSize.chip,
              padding: _chipPad,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.line, width: AppSize.hairline),
                borderRadius: BorderRadius.circular(AppSize.radiusChip),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                SkillStyle.glyph(id, size: _icon, color: AppColors.muted),
                const SizedBox(width: AppSpace.s),
                Text(SkillStyle.name(l, id), style: const TextStyle(fontSize: _text, color: AppColors.muted)),
              ]),
            ),
        ]),
      ),
    ]);
  }
}
