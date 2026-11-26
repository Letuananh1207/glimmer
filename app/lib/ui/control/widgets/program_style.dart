import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/skill_style.dart';
import '../../core/themes/app_colors.dart';
import '../../core/widgets/clawd.dart';

/// Name and icon of a device program (a channel) in Start, Tất cả chương trình and the line under the mirror
/// (design 2026-11-26.6: `app*` strings; Claude = Clawd coral, Thời tiết / Ảnh / Đồng hồ = dock pixel icons, the rest
/// Material icons as the design draws them).
abstract final class ProgramStyle {
  static String name(AppLocalizations l, String program) => switch (program) {
    'Claude' => l.appClaude,
    'Codex' => l.appCodex,
    'AI' => l.appAi,
    'Trend' => l.appTrend,
    'Agents' => l.appAgents,
    'Photo' => l.appPhoto,
    'Weather' => l.appWeather,
    'Forecast' => l.appForecast,
    'Clock' => l.appClock,
    'Info' => l.appInfo,
    'Home' => l.controlDesktop,
    final p => p,
  };

  static const _dock = {'Weather': 'weather', 'Clock': 'clock', 'Photo': 'photo'};

  /// Pixel icons are 16 px wide.
  static const _dockPx = 16;

  /// Clawd is drawn a little wider than the other icons.
  static const _clawdScale = 1.4;

  static Widget icon(String program, {required double size, Color color = AppColors.inkDim}) {
    if (program == 'Claude') return Clawd(size: size * _clawdScale, color: AppColors.clawd);
    final dock = _dock[program];
    if (dock != null) return SkillStyle.dockIcon(dock, color: color, scale: size / _dockPx);
    return Icon(
      switch (program) {
        'Codex' => Icons.code,
        'AI' => Icons.auto_awesome,
        'Trend' => Icons.trending_up,
        'Agents' => Icons.list,
        'Forecast' => Icons.date_range,
        'Info' => Icons.info_outline,
        _ => Icons.desktop_windows_outlined,
      },
      size: size,
      color: color,
    );
  }
}
