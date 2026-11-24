import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/skill_style.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text.dart';
import '../../core/widgets/skill_tile.dart';
import '../../core/widgets/status_banner.dart';
import '../view_models/skills_view_model.dart';

/// Màn Skill — tab 2 (screen_specs §6).
class SkillsScreen extends StatelessWidget {
  const SkillsScreen({super.key, required this.viewModel, required this.onOpenHome, required this.onOpenDevice});

  final SkillsViewModel viewModel;

  /// Chạm ô đang dùng → màn chính của skill đó (tab 1).
  final ValueChanged<String> onOpenHome;

  /// Firmware cũ → tab Thiết bị.
  final VoidCallback onOpenDevice;

  static const _gridGap = AppSpace.m;
  static const _gridPad = EdgeInsets.symmetric(horizontal: AppSpace.l, vertical: AppSpace.s);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final tiles = viewModel.tiles;
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
          Padding(
            padding: _gridPad,
            child: _Grid(gap: _gridGap, children: [
              for (final t in tiles)
                SkillTile(
                  id: t.id,
                  kind: switch (t.state) {
                    SkillTileState.current => SkillTileKind.current,
                    SkillTileState.available => SkillTileKind.available,
                    SkillTileState.switching => SkillTileKind.switching,
                    SkillTileState.soon => SkillTileKind.soon,
                  },
                  onTap: !t.enabled
                      ? null
                      : t.state == SkillTileState.current
                          ? () => onOpenHome(t.id)
                          : () => viewModel.select(t.id),
                ),
            ]),
          ),
          _ChannelsCard(skill: viewModel.active),
        ]);
      },
    );
  }

  Widget? _banner(AppLocalizations l) => switch (viewModel.banner) {
        null => null,
        SkillsBanner.switching => StatusBanner(
            busy: true,
            title: l.skillsSwitchingBanner(SkillStyle.name(l, viewModel.target ?? '')),
            body: l.skillsSwitchingHint,
          ),
        SkillsBanner.error => StatusBanner(
            title: l.skillsErrorTitle,
            titleColor: AppColors.coral,
            body: l.skillsErrorBody(SkillStyle.name(l, viewModel.active)),
            trailing: TextButton(onPressed: viewModel.retry, child: Text(l.commonRetry)),
          ),
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

/// Two equal columns; rows as tall as their tallest tile.
class _Grid extends StatelessWidget {
  const _Grid({required this.gap, required this.children});

  final double gap;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(children: [
        for (var i = 0; i < children.length; i += 2) ...[
          if (i > 0) SizedBox(height: gap),
          IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(child: children[i]),
              SizedBox(width: gap),
              Expanded(child: i + 1 < children.length ? children[i + 1] : const SizedBox()),
            ]),
          ),
        ],
      ]);
}

/// MÀN THIẾT BỊ ĐANG XOAY: kênh của skill + kênh hệ thống + nhắc thẻ duyệt (R-SK-3).
class _ChannelsCard extends StatelessWidget {
  const _ChannelsCard({required this.skill});

  final String skill;

  static const _square = 8.0;
  static const _textSize = 13.0;
  static const _textLine = 18 / 13;
  static const _margin = EdgeInsets.symmetric(horizontal: AppSpace.l, vertical: 6);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final small = AppFonts.label.copyWith(letterSpacing: 0, height: 16 / 12);
    return Container(
      margin: _margin,
      padding: const EdgeInsets.all(AppSpace.l),
      decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(AppSize.radiusCard)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.skillsChannelsTitle, style: AppFonts.label),
        const SizedBox(height: AppSpace.s),
        Text(SkillStyle.channels(l, skill),
            style: const TextStyle(fontSize: _textSize, height: _textLine, color: AppColors.ink)),
        const SizedBox(height: AppSpace.xs),
        Text(l.skillsChannelsSystem, style: small),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpace.m),
          child: Divider(height: AppSize.hairline, thickness: AppSize.hairline, color: AppColors.line),
        ),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(
            padding: EdgeInsets.only(top: AppSpace.xs),
            child: SizedBox.square(dimension: _square, child: ColoredBox(color: AppColors.amber)),
          ),
          const SizedBox(width: AppSpace.s),
          Expanded(child: Text(l.skillsAttentionNote, style: small.copyWith(color: AppColors.inkDim))),
        ]),
      ]),
    );
  }
}
