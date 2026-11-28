import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../utils/durations.dart';
import '../../core/labels.dart';
import '../../core/skill_style.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text.dart';
import '../view_models/dashboard_view_model.dart';

/// Tab Thời tiết (screen_specs §2 `weather` / `weatherNoLoc`): hôm nay + 3 ngày, hoặc lời mời đặt vị trí.
class WeatherCard extends StatelessWidget {
  const WeatherCard({super.key, required this.view, required this.onSetLocation});

  final WeatherView view;

  /// `weatherSetLocation` → màn Vị trí thời tiết (2026-11-26.9).
  final VoidCallback onSetLocation;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final (meta, metaColor) = switch (view.status) {
      WeatherStatus.noLocation => (l.weatherNoLocationMeta, AppColors.amber),
      WeatherStatus.waiting => (l.devWeatherNoData, AppColors.muted),
      WeatherStatus.ok when view.stale && view.ageS != null =>
        (l.dashboardUsageStale(agoShort(view.ageS!)), AppColors.amber),
      WeatherStatus.ok => (view.ageS == null ? '' : l.ago(view.ageS!), AppColors.muted),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.l),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Text(l.weatherTitle, style: AppFonts.label),
            const SizedBox(width: AppSpace.s),
            Expanded(
              child: Text(meta,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.label.copyWith(color: metaColor)),
            ),
          ]),
          if (view.status == WeatherStatus.noLocation)
            _NoLocation(onSetLocation: onSetLocation)
          else ...[
            _Now(view: view),
            const _Rule(),
            for (var i = 0; i < view.forecast.length; i++) _DayRow(row: view.forecast[i], first: i == 0),
          ],
        ]),
      ),
    );
  }
}

/// "29°" or "--°".
String _deg(int? t) => '${t ?? '--'}°';

const _sunScale = 3.5;

class _Now extends StatelessWidget {
  const _Now({required this.view});

  final WeatherView view;

  static const _top = 14.0;
  static const _hero = 56.0;
  static const _desc = 16.0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: _top),
      child: Row(children: [
        SkillStyle.dockIcon('weather', color: AppColors.skillWeather, scale: _sunScale),
        const SizedBox(width: AppSpace.l),
        Text(_deg(view.temp),
            style: const TextStyle(fontSize: _hero, fontWeight: FontWeight.w700, height: 1, color: AppColors.ink)),
        const SizedBox(width: AppSpace.l),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(view.desc, style: const TextStyle(fontSize: _desc, color: AppColors.ink)),
            const SizedBox(height: AppSpace.xs),
            Text(l.weatherHiLo('${view.hi ?? '--'}', '${view.lo ?? '--'}'),
                style: AppFonts.label.copyWith(color: AppColors.inkDim, letterSpacing: 0)),
            if (view.feels != null) ...[
              const SizedBox(height: AppSpace.xs),
              Text(l.weatherFeels('${view.feels}'), style: AppFonts.label.copyWith(letterSpacing: 0)),
            ],
          ]),
        ),
      ]),
    );
  }
}

/// Hairline under the hero (lề 16 0 4).
class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) => Container(
        height: AppSize.hairline,
        margin: const EdgeInsets.only(top: AppSpace.l, bottom: AppSpace.xs),
        color: AppColors.line,
      );
}

class _DayRow extends StatelessWidget {
  const _DayRow({required this.row, required this.first});

  final ForecastRow row;
  final bool first;

  static const _dayW = 36.0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final day = switch (row.offset) {
      1 => l.weatherDayTomorrow,
      2 => l.weatherDayAfter,
      _ => l.devWeekdayShort('${row.weekday}'),
    };
    return Container(
      constraints: const BoxConstraints(minHeight: AppSize.tapMin),
      decoration: first
          ? null
          : const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line, width: AppSize.hairline))),
      child: Row(children: [
        SizedBox(width: _dayW, child: Text(day, style: AppFonts.label)),
        const SizedBox(width: AppSpace.m),
        Expanded(child: Text(row.desc, overflow: TextOverflow.ellipsis, style: AppFonts.body)),
        const SizedBox(width: AppSpace.m),
        Text.rich(
          TextSpan(text: _deg(row.hi), children: [
            TextSpan(text: ' / ${_deg(row.lo)}', style: const TextStyle(color: AppColors.muted)),
          ]),
          style: AppFonts.body.copyWith(color: AppColors.ink),
        ),
      ]),
    );
  }
}

class _NoLocation extends StatelessWidget {
  const _NoLocation({required this.onSetLocation});

  final VoidCallback onSetLocation;

  static const _pad = EdgeInsets.fromLTRB(AppSpace.s, AppSpace.xxl, AppSpace.s, AppSpace.s);
  static const _bodySize = 13.0;
  static const _bodyLine = 18 / 13;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(children: [
      Padding(
        padding: _pad,
        child: Column(children: [
          SkillStyle.dockIcon('weather', color: AppColors.muted, scale: _sunScale),
          const SizedBox(height: AppSpace.l),
          Text(l.weatherNoLocationTitle, textAlign: TextAlign.center, style: AppFonts.heading.copyWith(color: AppColors.ink)),
          const SizedBox(height: AppSpace.s),
          Text(l.weatherNoLocationBody,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: _bodySize, height: _bodyLine, color: AppColors.inkDim)),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.only(top: AppSpace.m, bottom: AppSpace.s),
        child: OutlinedButton.icon(
          onPressed: onSetLocation,
          icon: const Icon(Icons.place),
          label: Text(l.weatherSetLocation),
        ),
      ),
    ]);
  }
}
