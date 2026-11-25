import 'package:flutter/material.dart';

import '../themes/app_colors.dart';
import '../themes/app_text.dart';

/// Công tắc skill (components.md `SkillSwitch`): rãnh 52×32 tô màu nhấn của skill, vùng chạm 60×48.
/// Bật: nền + viền 2 [accent], núm 24 `bg` bên phải. Tắt: nền `panel2`, viền 2 `muted`, núm 16 `muted` bên trái.
/// Khoá ([onChanged] null): mờ 38 %.
class SkillSwitch extends StatelessWidget {
  const SkillSwitch({super.key, required this.value, required this.accent, required this.label, this.onChanged});

  final bool value;
  final Color accent;

  /// Screen-reader label (`skillsToggleA11y`).
  final String label;
  final ValueChanged<bool>? onChanged;

  static const tapW = 60.0;
  static const tapH = 48.0;
  static const _border = 2.0;
  static const _knobOn = 24.0;
  static const _knobOff = 16.0;
  static const _inset = 2.0; // knob gap inside the border when on
  static const _offInset = 6.0; // (32 − 2·2 − 16) / 2: off knob centred vertically, same gap from the left
  static const _disabled = 0.38;
  static const _duration = Duration(milliseconds: 150);

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    final knob = value ? _knobOn : _knobOff;
    final inner = AppSize.switchW - 2 * _border;
    final left = value ? inner - _inset - knob : _offInset;
    final top = (AppSize.switchH - 2 * _border - knob) / 2;
    return Semantics(
      toggled: value,
      enabled: enabled,
      label: label,
      button: true,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => onChanged!(!value) : null,
        child: SizedBox(
          width: tapW,
          height: tapH,
          child: Center(
            child: Opacity(
              opacity: enabled ? 1 : _disabled,
              child: AnimatedContainer(
                duration: _duration,
                width: AppSize.switchW,
                height: AppSize.switchH,
                decoration: BoxDecoration(
                  color: value ? accent : AppColors.panel2,
                  borderRadius: BorderRadius.circular(AppSize.switchH / 2),
                  border: Border.all(color: value ? accent : AppColors.muted, width: _border),
                ),
                child: Stack(children: [
                  AnimatedPositioned(
                    duration: _duration,
                    left: left,
                    top: top,
                    width: knob,
                    height: knob,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: value ? AppColors.bg : AppColors.muted, shape: BoxShape.circle),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
