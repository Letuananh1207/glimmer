import 'package:flutter/material.dart';

import '../../../domain/models/device_state.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text.dart';
import '../../core/widgets/clawd.dart';

/// Clawd + "glimmer" + online dot and network line.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key, required this.state, required this.mood, required this.walking});

  final DeviceState state;
  final ClawdMood mood;
  final bool walking;

  static const _dot = 9.0;
  static const _dotGap = 6.0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final online = !state.inSetupMode;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.xl, AppSpace.l, AppSpace.xl, AppSpace.s),
      child: Row(children: [
        Clawd(mood: mood, walking: walking, size: AppSize.clawdHeader),
        const SizedBox(width: AppSpace.l),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('glimmer', style: AppFonts.screenTitle.copyWith(color: AppColors.ink)),
            const SizedBox(height: AppSpace.xs),
            Row(children: [
              Icon(Icons.circle, size: _dot, color: online ? AppColors.mint : AppColors.amber),
              const SizedBox(width: _dotGap),
              Flexible(
                child: Text(
                  online ? '${state.ssid} · ${state.ip}' : l.dashboardSetupMode(state.ip),
                  style: AppFonts.label,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]),
          ]),
        ),
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
