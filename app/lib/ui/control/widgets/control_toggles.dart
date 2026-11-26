import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/skill_style.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text.dart';
import '../../core/widgets/dock_tab_bar.dart';
import 'control_pad.dart';

/// `JumpTabBar` (§8): `DockTabBar` 4 tab xếp dọc (ô 56, icon dock ×1.25 + nhãn 12), lề 12 16 0; tab sáng = kênh
/// đang hiện trên thiết bị ([lit]); huy hiệu amber trên Agent. Bấm → [onJump] (skill id).
class JumpTabBar extends StatelessWidget {
  const JumpTabBar({
    super.key,
    required this.skills,
    required this.lit,
    required this.badge,
    required this.onJump,
    this.enabled = true,
  });

  final List<String> skills;
  final String? lit;
  final String? badge;
  final ValueChanged<String> onJump;
  final bool enabled;

  static const _iconScale = 1.25;
  static const _margin = EdgeInsets.fromLTRB(AppSpace.l, AppSpace.m, AppSpace.l, 0);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Opacity(
      opacity: enabled ? 1 : padDisabledOpacity,
      child: IgnorePointer(
        ignoring: !enabled,
        child: DockTabBar(
          semanticLabel: l.controlJumpGroupA11y,
          margin: _margin,
          alwaysStacked: true,
          selected: lit ?? '',
          onSelect: onJump,
          tabs: [
            for (final id in skills)
              DockTabItem(
                id: id,
                label: SkillStyle.name(l, id),
                icon: SkillStyle.dockIcon(
                  id,
                  color: id == 'agent' ? AppColors.clawd : AppColors.inkDim,
                  scale: _iconScale,
                ),
                accent: SkillStyle.of(id).accent,
                badge: id == 'agent' ? badge : null,
              ),
          ],
        ),
      ),
    );
  }
}

/// `BrightnessSlider` (§8): lề 12 16 0, thẻ ≥ 52 `panel` bo 14 đệm 0 16, cách 14 — mặt trời 20 inkDim, thanh trượt
/// (rãnh 4 `panel2`, phần sáng amber, núm 20 ink có bóng; vùng chạm 44), số "80%" 13 ink rộng 40. Đang kéo: núm 28
/// + bong bóng ink chữ bg 12/700. [onChanged] khi kéo, [onRelease] khi thả (R-DK-5).
class BrightnessSlider extends StatelessWidget {
  const BrightnessSlider({
    super.key,
    required this.value,
    required this.dragging,
    required this.onChanged,
    required this.onRelease,
    this.enabled = true,
  });

  final int value;
  final bool dragging;
  final ValueChanged<double> onChanged;
  final VoidCallback onRelease;
  final bool enabled;

  static const _min = 5.0, _max = 100.0;
  static const _minH = 52.0;
  static const _sun = 20.0;
  static const _gap = 14.0;
  static const _numW = 40.0;
  static const _num = 13.0;
  static const _track = 4.0;
  static const _thumb = 10.0, _thumbDrag = 14.0;
  static const _bubble = 12.0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final slider = SliderTheme(
      data: SliderThemeData(
        trackHeight: _track,
        activeTrackColor: AppColors.amber,
        inactiveTrackColor: AppColors.panel2,
        thumbColor: AppColors.ink,
        overlayShape: SliderComponentShape.noOverlay,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: dragging ? _thumbDrag : _thumb, elevation: 2),
        showValueIndicator: ShowValueIndicator.onDrag,
        valueIndicatorColor: AppColors.ink,
        valueIndicatorTextStyle: TextStyle(
          fontFamily: AppFonts.family,
          fontSize: _bubble,
          fontWeight: FontWeight.w700,
          color: AppColors.bg,
        ),
      ),
      child: Slider(
        value: value.toDouble().clamp(_min, _max),
        min: _min,
        max: _max,
        label: '$value%',
        semanticFormatterCallback: (v) => '${l.controlBrightness} ${v.round()}%',
        onChanged: enabled ? onChanged : null,
        onChangeEnd: enabled ? (_) => onRelease() : null,
      ),
    );
    return Opacity(
      opacity: enabled ? 1 : padDisabledOpacity,
      child: Container(
        margin: const EdgeInsets.fromLTRB(AppSpace.l, AppSpace.m, AppSpace.l, 0),
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.l),
        constraints: const BoxConstraints(minHeight: _minH),
        decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(AppSize.radiusCard)),
        child: Row(
          children: [
            const Icon(Icons.wb_sunny_outlined, size: _sun, color: AppColors.inkDim),
            const SizedBox(width: _gap),
            Expanded(
              child: SizedBox(height: AppSize.tapMin, child: slider),
            ),
            const SizedBox(width: _gap),
            SizedBox(
              width: _numW,
              child: Text(
                '$value%',
                textAlign: TextAlign.right,
                style: const TextStyle(fontFamily: AppFonts.family, fontSize: _num, color: AppColors.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One `RoundToggle`.
class RoundItem {
  const RoundItem({required this.icon, required this.label, required this.onTap, this.on, this.look = PadLook.normal});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Accent when on (screen off amber, night lilac); null = off.
  final Color? on;
  final PadLook look;
}

/// Hàng `RoundToggle` (§8): đệm 16 16 0, 3 cột — vòng 56 (`roundButton`) nền `panel` viền 1 `line`, icon 24 ink +
/// nhãn 12 inkDim cách 6. Bật: nền tint + viền + icon + nhãn màu nhấn.
class RoundToggleRow extends StatelessWidget {
  const RoundToggleRow({super.key, required this.items});

  final List<RoundItem> items;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(AppSpace.l, AppSpace.l, AppSpace.l, 0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [for (final i in items) Expanded(child: RoundToggle(item: i))],
    ),
  );
}

class RoundToggle extends StatelessWidget {
  const RoundToggle({super.key, required this.item});

  final RoundItem item;

  static const _icon = 24.0;
  static const _gap = 6.0;
  static const _label = 12.0;
  static const _tint = 0.16;
  static const _lock = 14.0;

  @override
  Widget build(BuildContext context) {
    final on = item.on;
    final usable = item.look == PadLook.normal;
    return Semantics(
      button: true,
      toggled: on != null,
      enabled: usable,
      label: item.label,
      excludeSemantics: true,
      child: Opacity(
        opacity: usable ? 1 : padDisabledOpacity,
        child: InkWell(
          onTap: usable ? item.onTap : null,
          customBorder: const CircleBorder(),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: AppSize.roundButton,
                    height: AppSize.roundButton,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: on == null
                          ? AppColors.panel
                          : Color.alphaBlend(on.withValues(alpha: _tint), AppColors.panel),
                      border: Border.all(color: on ?? AppColors.line),
                    ),
                    child: Icon(item.icon, size: _icon, color: on ?? AppColors.ink),
                  ),
                  if (item.look == PadLook.locked)
                    const Positioned(
                      top: 0,
                      right: -AppSpace.xs,
                      child: Icon(Icons.lock_outline, size: _lock, color: AppColors.inkDim),
                    ),
                ],
              ),
              const SizedBox(height: _gap),
              Text(
                item.label,
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: AppFonts.family, fontSize: _label, color: on ?? AppColors.inkDim),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
