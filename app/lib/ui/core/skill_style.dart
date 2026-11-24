// How each skill looks in the app: name, description, accent, icon (design/docs/navigation.json skills.catalog).
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'themes/app_colors.dart';
import 'widgets/clawd.dart';

/// Skill id → look. Ids stay English (they go to the device).
class SkillStyle {
  const SkillStyle._(this.accent, this.tint, this.icon);

  final Color accent;

  /// Background of the icon badge.
  final Color tint;

  /// Material icon; null = Clawd (Agent).
  final IconData? icon;

  static SkillStyle of(String id) => switch (id) {
        'agent' => const SkillStyle._(AppColors.skillAgent, AppColors.skillAgentTint, null),
        'music' => const SkillStyle._(AppColors.skillMusic, AppColors.skillMusicTint, Icons.music_note),
        'social' => const SkillStyle._(AppColors.skillSocial, AppColors.skillSocialTint, Icons.forum),
        _ => const SkillStyle._(AppColors.skillFun, AppColors.skillFunTint, Icons.celebration),
      };

  static String name(AppLocalizations l, String id) => switch (id) {
        'agent' => l.skillAgentName,
        'music' => l.skillMusicName,
        'social' => l.skillSocialName,
        'fun' => l.skillFunName,
        _ => id,
      };

  static String description(AppLocalizations l, String id) => switch (id) {
        'agent' => l.skillAgentDesc,
        'music' => l.skillMusicDesc,
        'social' => l.skillSocialDesc,
        'fun' => l.skillFunDesc,
        _ => '',
      };

  /// Device channels of the skill (static text — the device does not list them).
  static String channels(AppLocalizations l, String id) => switch (id) {
        'agent' => l.skillAgentChannels,
        _ => '',
      };

  /// Icon of [id] at [size] in [color] (Agent: Clawd, [mood] sleep = no eyes).
  static Widget glyph(String id, {required double size, required Color color, ClawdMood mood = ClawdMood.open}) {
    final icon = of(id).icon;
    return icon == null ? Clawd(size: size, color: color, mood: mood) : Icon(icon, size: size, color: color);
  }
}
