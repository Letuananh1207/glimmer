import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text.dart';

/// Thanh trên của Số liệu (screen_specs §2, 2026-11-26.5 — màn phụ đẩy từ Điều khiển): cao 56, nút quay lại 48
/// (`detailsBackA11y`) → Điều khiển, `detailsTitle` 18/700, nút refresh 44 bên phải (`dashboardRefreshNow`).
class DetailsTopBar extends StatelessWidget {
  const DetailsTopBar({super.key, required this.onBack, required this.onRefresh});

  final VoidCallback onBack;
  final VoidCallback onRefresh;

  static const _height = 56.0;
  static const _back = 48.0;
  static const _title = 18.0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SizedBox(
      height: _height,
      child: Row(children: [
        const SizedBox(width: AppSpace.xs),
        IconButton(
          onPressed: onBack,
          tooltip: l.detailsBackA11y,
          constraints: const BoxConstraints.tightFor(width: _back, height: _back),
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
        ),
        const SizedBox(width: AppSpace.xs),
        Expanded(
          child: Text(l.detailsTitle,
              style: AppFonts.screenTitle.copyWith(fontSize: _title, color: AppColors.ink)),
        ),
        IconButton(
          onPressed: onRefresh,
          tooltip: l.dashboardRefreshNow,
          constraints: const BoxConstraints.tightFor(width: AppSize.tapMin, height: AppSize.tapMin),
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.refresh, color: AppColors.inkDim),
        ),
        const SizedBox(width: AppSpace.s),
      ]),
    );
  }
}

/// Amber note on `panel2` (device in glimmer-setup).
class SetupNote extends StatelessWidget {
  const SetupNote({super.key, required this.text});

  final String text;

  /// Inner padding (design: 14).
  static const _pad = 14.0;

  @override
  Widget build(BuildContext context) => Card(
        color: AppColors.panel2,
        child: Padding(
          padding: const EdgeInsets.all(_pad),
          child: Text(text, style: const TextStyle(color: AppColors.amber)),
        ),
      );
}
