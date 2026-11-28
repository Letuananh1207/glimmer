// How each skill looks in the app: name, description, accent, icon (design/docs/navigation.json skills.catalog).
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'themes/app_colors.dart';
import 'widgets/clawd.dart';
import 'widgets/pixel_icon.dart';

/// Skill id → look. Ids stay English (they go to the device).
class SkillStyle {
  const SkillStyle._(this.accent, this.tint, {this.icon, this.dock, this.dockScale = 1});

  final Color accent;

  /// Background of the icon badge.
  final Color tint;

  /// Material icon (chips "Sắp có"); null = pixel icon [dock] or Clawd.
  final IconData? icon;

  /// Pixel icon of the device dock (`assets/icons/dock-*.svg`), null = none.
  final String? dock;

  /// Pixels per dock-icon pixel in a skill row (Clawd ×1.75, others ×1.5).
  final double dockScale;

  static const _clawdScale = 1.75;
  static const _pixelScale = 1.5;
  static const _icons = 'assets/icons';

  static SkillStyle of(String id) => switch (id) {
        'agent' => const SkillStyle._(AppColors.skillAgent, AppColors.skillAgentTint,
            dock: '$_icons/dock-clawd.svg', dockScale: _clawdScale),
        'photo' => const SkillStyle._(AppColors.skillPhoto, AppColors.skillPhotoTint,
            dock: '$_icons/dock-photo.svg', dockScale: _pixelScale),
        'weather' => const SkillStyle._(AppColors.skillWeather, AppColors.skillWeatherTint,
            dock: '$_icons/dock-weather.svg', dockScale: _pixelScale),
        'clock' => const SkillStyle._(AppColors.skillClock, AppColors.skillClockTint,
            dock: '$_icons/dock-clock.svg', dockScale: _pixelScale),
        'chat' => const SkillStyle._(AppColors.muted, AppColors.panel2, dock: '$_icons/dock-chat.svg'),
        'music' => const SkillStyle._(AppColors.skillMusic, AppColors.skillMusicTint, icon: Icons.music_note),
        'social' => const SkillStyle._(AppColors.skillSocial, AppColors.skillSocialTint, icon: Icons.forum),
        _ => const SkillStyle._(AppColors.skillFun, AppColors.skillFunTint, icon: Icons.videogame_asset),
      };

  static String name(AppLocalizations l, String id) => switch (id) {
        'agent' => l.skillAgentName,
        'photo' => l.skillPhotoName,
        'weather' => l.skillWeatherName,
        'clock' => l.skillClockName,
        'chat' => l.skillChatName,
        'music' => l.skillMusicName,
        'social' => l.skillSocialName,
        'fun' => l.skillFunName,
        _ => id,
      };

  /// One-line description of a skill row.
  static String description(AppLocalizations l, String id) => switch (id) {
        'agent' => l.skillAgentDesc,
        'photo' => l.skillPhotoDesc,
        'weather' => l.skillWeatherDesc,
        'clock' => l.skillClockDesc,
        'fun' => l.skillFunDesc,
        _ => '',
      };

  /// Icon of [id] at [size] in [color] (Agent: Clawd, [mood] sleep = no eyes; dock skills: their pixel icon).
  static Widget glyph(String id, {required double size, required Color color, ClawdMood mood = ClawdMood.open}) {
    final s = of(id);
    if (id == 'agent') return Clawd(size: size, color: color, mood: mood);
    if (s.icon != null) return Icon(s.icon, size: size, color: color);
    return SizedBox.square(
      dimension: size,
      child: Center(child: PixelIcon(s.dock!, scale: size / 16, color: color)),
    );
  }

  /// Dock pixel icon of [id] at its skill-row scale (or [scale]). A skill without a pixel icon yet (Giải trí, a pack
  /// since 2026-11-27 — phiếu thiết kế docs/phieu_thiet_ke/2026-11-27-skill-giai-tri.md) shows its chip icon.
  static Widget dockIcon(String id, {required Color color, double? scale}) {
    final s = of(id);
    final dock = s.dock;
    if (dock == null) return Icon(s.icon, size: 16 * (scale ?? s.dockScale), color: color);
    return PixelIcon(dock, scale: scale ?? s.dockScale, color: color);
  }
}
