import 'package:flutter/material.dart';

import '../../../domain/models/device_state.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text.dart';
import '../../core/widgets/clawd.dart';

/// Đầu màn gọn (2026-11-25.3): Clawd 44 + 12 + "glimmer" 18/700 / chấm trực tuyến + mạng; nút icon refresh 44 inkDim
/// bên phải (nhãn đọc màn hình `dashboardRefreshNow`). Đệm 12 16 8 20 (nút lấn 8 vào lề phải).
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.state,
    required this.mood,
    required this.walking,
    required this.onRefresh,
  });

  final DeviceState state;
  final ClawdMood mood;
  final bool walking;
  final VoidCallback onRefresh;

  static const _dot = 9.0;
  static const _dotGap = 6.0;
  static const _title = 18.0;
  static const _refreshNudge = 8.0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final online = !state.inSetupMode;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.xl, AppSpace.m, AppSpace.l - _refreshNudge, AppSpace.s),
      child: Row(children: [
        Clawd(mood: mood, walking: walking, size: AppSize.headerClawd),
        const SizedBox(width: AppSpace.m),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('glimmer', style: AppFonts.screenTitle.copyWith(fontSize: _title, color: AppColors.ink)),
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
        IconButton(
          onPressed: onRefresh,
          tooltip: l.dashboardRefreshNow,
          constraints: const BoxConstraints.tightFor(width: AppSize.tapMin, height: AppSize.tapMin),
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.refresh, color: AppColors.inkDim),
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
