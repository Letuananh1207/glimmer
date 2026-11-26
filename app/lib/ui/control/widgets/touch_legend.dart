import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text.dart';
import 'control_toggles.dart';

/// `TouchLegend` (§8, design 2026-11-26.6): lề 10 16 0, đệm 10 14, bo 14 `panel` — `controlLegendTitle` 12 muted, lưới
/// 2 cột cách 6 12: ô ký hiệu (≥ 22 × 20 bo 4 `panel2`, chữ 11/700 ink) + nhãn 12 inkDim. Mờ 38 % khi không dùng được.
class TouchLegend extends StatelessWidget {
  const TouchLegend({super.key, this.enabled = true});

  final bool enabled;

  static const _keyW = 22.0, _keyH = 20.0, _keyRadius = 4.0, _keySize = 11.0;
  static const _rowGap = 6.0, _colGap = 12.0, _gap = 6.0;
  static const _margin = EdgeInsets.fromLTRB(AppSpace.l, 10, AppSpace.l, 0);
  static const _pad = EdgeInsets.symmetric(horizontal: 14, vertical: 10);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final items = [
      ('_', l.controlLegendMin),
      ('□', l.controlLegendMax),
      ('×', l.controlLegendClose),
      ('▭', l.controlLegendTaskbar),
      (l.controlLegendStartKey, l.controlLegendStart),
      (l.controlLegendHoldKey, l.controlLegendHold),
    ];
    Widget cell((String, String) it) => Row(
      children: [
        Container(
          constraints: const BoxConstraints(minWidth: _keyW, minHeight: _keyH),
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
          alignment: Alignment.center,
          decoration: BoxDecoration(color: AppColors.panel2, borderRadius: BorderRadius.circular(_keyRadius)),
          child: Text(
            it.$1,
            style: const TextStyle(
              fontFamily: AppFonts.family,
              fontSize: _keySize,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ),
        const SizedBox(width: _gap),
        Expanded(
          child: Text(
            it.$2,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.label.copyWith(color: AppColors.inkDim, letterSpacing: 0),
          ),
        ),
      ],
    );
    return Opacity(
      opacity: enabled ? 1 : padDisabledOpacity,
      child: Container(
        margin: _margin,
        padding: _pad,
        decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(AppSize.radiusCard)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.controlLegendTitle, style: AppFonts.label),
            const SizedBox(height: AppSpace.s),
            for (var i = 0; i < items.length; i += 2) ...[
              if (i > 0) const SizedBox(height: _rowGap),
              Row(
                children: [
                  Expanded(child: cell(items[i])),
                  const SizedBox(width: _colGap),
                  Expanded(child: cell(items[i + 1])),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
