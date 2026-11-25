import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text.dart';
import '../view_models/dashboard_view_model.dart';

/// Tab Đồng hồ (screen_specs §2 `clock`): giờ 72/700 (giờ ink, ":" coral, phút amber như kênh Clock), ngày, rồi múi
/// giờ / kiểu giờ / ban đêm.
class ClockCard extends StatelessWidget {
  const ClockCard({super.key, required this.view});

  final ClockView view;

  static const _heroTop = 18.0;
  static const _hero = 72.0;
  static const _suffix = 20.0;
  static const _dateMargin = EdgeInsets.fromLTRB(0, 10, 0, 14);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final night = view.night;
    final mode = switch (night?.mode) {
      1 => l.devClockNightDim,
      2 => l.devClockNightClock,
      _ => l.devClockNightOff,
    };
    const hero = TextStyle(fontSize: _hero, fontWeight: FontWeight.w700, height: 1);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.l),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(l.clockTitle, style: AppFonts.label),
          const SizedBox(height: _heroTop),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: view.hour, style: hero.copyWith(color: AppColors.ink)),
                TextSpan(text: ':', style: hero.copyWith(color: AppColors.coral)),
                TextSpan(text: view.minute, style: hero.copyWith(color: AppColors.amber)),
                if (view.pm != null)
                  TextSpan(
                    text: ' ${view.pm! ? l.devClockPm : l.devClockAm}',
                    style: const TextStyle(fontSize: _suffix, fontWeight: FontWeight.w700, color: AppColors.inkDim),
                  ),
              ]),
              semanticsLabel: '${view.hour}:${view.minute}',
            ),
          ),
          Padding(
            padding: _dateMargin,
            child: Text(
              l.clockDate(l.devWeekdayLong('${view.weekday}'), view.date, '${view.week}'),
              textAlign: TextAlign.center,
              style: AppFonts.body.copyWith(letterSpacing: AppFonts.label.letterSpacing),
            ),
          ),
          _InfoRow(label: l.clockTz, value: view.tz, first: true),
          _InfoRow(label: l.clockFormat, value: view.h24 ? l.clockFormat24 : l.clockFormat12),
          _InfoRow(
            label: l.clockNight,
            value: night == null ? l.settingsNightNone : l.clockNightValue(night.start, night.end, mode),
          ),
        ]),
      ),
    );
  }
}

/// Dòng ≥ 44: nhãn 14 inkDim, giá trị 14 ink căn phải; kẻ `line` giữa các dòng.
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.first = false});

  final String label, value;
  final bool first;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: AppSize.tapMin),
        decoration: first
            ? null
            : const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line, width: AppSize.hairline))),
        child: Row(children: [
          Text(label, style: AppFonts.body),
          const SizedBox(width: AppSpace.s),
          Expanded(
            child: Text(value, textAlign: TextAlign.right, style: AppFonts.body.copyWith(color: AppColors.ink)),
          ),
        ]),
      );
}
