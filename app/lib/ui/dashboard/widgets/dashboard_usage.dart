import 'package:flutter/material.dart';

import '../../../domain/models/usage_meta.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/durations.dart';
import '../../core/labels.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text.dart';
import '../../core/themes/status_colors.dart';
import '../view_models/dashboard_view_model.dart';

/// MỨC DÙNG CLAUDE: week (big) and 5-hour session rows.
class UsageCard extends StatelessWidget {
  const UsageCard({super.key, required this.meta, required this.week, required this.session});

  final UsageMeta meta;
  final UsageRowData week, session;

  /// Gap between the title and each row (design: 14).
  static const _rowGap = 14.0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // R-DUNG-2.
    final (text, color) = switch (meta.kind) {
      UsageMetaKind.noKey => (l.dashboardUsageNoKey, AppColors.amber),
      UsageMetaKind.keyBad => (l.dashboardUsageKeyBad, AppColors.coral),
      UsageMetaKind.blocked => (l.dashboardUsageBlocked, AppColors.amber),
      UsageMetaKind.stale => (l.dashboardUsageStale(agoShort(meta.ageS)), AppColors.amber),
      UsageMetaKind.fresh => (l.ago(meta.ageS), AppColors.muted),
      UsageMetaKind.none => ('', AppColors.muted),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.l),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(l.dashboardUsageTitle, style: AppFonts.label),
            const Spacer(),
            Flexible(
              child: Text(text, style: AppFonts.label.copyWith(color: color), overflow: TextOverflow.ellipsis),
            ),
          ]),
          const SizedBox(height: _rowGap),
          UsageRow(label: l.dashboardWeek, data: week, big: true),
          const SizedBox(height: _rowGap),
          UsageRow(label: l.dashboardSession, data: session),
        ]),
      ),
    );
  }
}

/// One usage row: big % + label, "đặt lại sau …", segmented bar.
class UsageRow extends StatelessWidget {
  const UsageRow({super.key, required this.label, required this.data, this.big = false});

  final String label;
  final UsageRowData data;
  final bool big;

  /// "%" sign next to the number (design: 20 / 14).
  static const _pctBig = 20.0;
  static const _pctSmall = 14.0;

  /// Lifts the label and reset text to the number's baseline area (design: 6).
  static const _lift = 6.0;

  /// Between the number and the label (design: 10).
  static const _labelGap = 10.0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final color = StatusColors.usage(data.level);
    final used = data.used;
    final left = l.countdown(data.resetInS);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(used < 0 ? '--' : '$used',
            style: (big ? AppFonts.usageHero : AppFonts.usageSmall).copyWith(color: color)),
        Text('%', style: TextStyle(fontSize: big ? _pctBig : _pctSmall, color: color)),
        const SizedBox(width: _labelGap),
        Padding(padding: const EdgeInsets.only(bottom: _lift), child: Text(label, style: AppFonts.body)),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.only(bottom: _lift),
          child: Text(left == null ? '' : l.dashboardResetIn(left),
              style: AppFonts.label.copyWith(color: AppColors.inkDim)),
        ),
      ]),
      const SizedBox(height: _lift),
      ClipRRect(
        borderRadius: BorderRadius.circular(AppSize.radiusUsageBar),
        child: LinearProgressIndicator(
          value: used < 0 ? 0 : used / 100,
          minHeight: big ? AppSize.usageBarBig : AppSize.usageBarSmall,
          backgroundColor: AppColors.panel2,
          color: color,
        ),
      ),
    ]);
  }
}
