import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text.dart';

/// Mờ của nút / chú thích không dùng được hoặc thiếu firmware.
const padDisabledOpacity = 0.38;

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
    this.margin = const EdgeInsets.fromLTRB(AppSpace.l, AppSpace.m, AppSpace.l, 0),
  });

  /// Outside the card (lề 12 16 0 alone; none in the bottom row of 2026-11-27.10).
  final EdgeInsets margin;

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
        margin: margin,
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

