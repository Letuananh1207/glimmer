import 'package:flutter/material.dart';

import '../../../domain/models/control.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/labels.dart';
import '../../core/skill_style.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text.dart';
import '../../../utils/durations.dart';
import '../view_models/control_view_model.dart';
import 'control_pad.dart';
import 'control_parts.dart';
import 'control_toggles.dart';
import 'device_mirror/device_mirror.dart';
import 'device_mirror/channels/photo_channel.dart';
import 'device_mirror/mirror_channel.dart';
import 'hold_card_panel.dart';

/// Điều khiển (tab 1, screen_specs §8, design 2026-11-26.5): đầu màn, thanh báo (firmware cũ / glimmer-setup / mất
/// kết nối), `DeviceMirror`, dòng kênh hoặc `HoldCardPanel`, `ControlPad`, `JumpTabBar`, `BrightnessSlider`,
/// `RoundToggle` (tắt màn, chế độ đêm, số liệu); `CommandSnackbar` nổi trên thanh dưới khi lệnh không được nhận.
class ControlScreen extends StatelessWidget {
  const ControlScreen({
    super.key,
    required this.viewModel,
    required this.onOpenDetails,
    required this.onUpdateFirmware,
    required this.onSetupWifi,
  });

  final ControlViewModel viewModel;

  /// Số liệu (push), at the tab of skill (null = first); completes when it closes.
  final Future<void> Function(String? skill) onOpenDetails;
  final VoidCallback onUpdateFirmware, onSetupWifi;

  static const _snackSide = 12.0;
  static const _bottomPad = 16.0;
  static const _mirrorTop = 4.0;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: viewModel,
    builder: (context, _) {
      final vm = viewModel;
      final s = vm.state;
      if (s == null) return const Center(child: CircularProgressIndicator());
      final l = AppLocalizations.of(context);
      final mode = vm.mode;
      final failed = vm.failed;
      return Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(bottom: _bottomPad),
            children: [
              ControlHeader(
                network: switch (mode) {
                  ControlMode.setup => 'glimmer-setup · ${s.ip}',
                  ControlMode.offline => '${l.controlOfflineOverlay} · ${s.ip}',
                  ControlMode.normal => '${s.ssid} · ${s.ip}',
                },
                dot: switch (mode) {
                  ControlMode.setup => AppColors.amber,
                  ControlMode.offline => AppColors.coral,
                  ControlMode.normal => AppColors.mint,
                },
                onRefresh: mode == ControlMode.normal ? vm.refreshData : null,
              ),
              ?_banner(l, vm),
              const SizedBox(height: _mirrorTop),
              Center(
                child: DeviceMirror(
                  frame: vm.frame,
                  channels: withPhoto(mirrorChannels, vm.photoImage),
                  semanticLabel: l.controlScreenA11y(_channelTitle(l, vm)),
                  dim: vm.dim,
                  offline: mode == ControlMode.offline,
                  chip: vm.sending ? SendingChip(label: l.controlSending) : null,
                  onTap: () => _details(vm),
                  onNext: _usable(vm) ? () => vm.step(ControlCommand.next) : null,
                  onPrev: _usable(vm) && vm.caps.prev ? () => vm.step(ControlCommand.prev) : null,
                ),
              ),
              _status(l, vm),
              ControlPad(items: _pad(l, vm)),
              if (vm.skills.length > 1)
                JumpTabBar(
                  skills: vm.skills,
                  lit: vm.channelSkill,
                  badge: vm.badge,
                  onJump: vm.jump,
                  enabled: _usable(vm),
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpace.xxl, 10, AppSpace.xxl, 0),
                  child: Text(
                    l.controlSingleNote(SkillStyle.name(l, vm.skills.isEmpty ? 'agent' : vm.skills.first)),
                    style: AppFonts.label.copyWith(letterSpacing: 0),
                  ),
                ),
              BrightnessSlider(
                value: vm.brightness,
                dragging: vm.dragging,
                onChanged: vm.dragBrightness,
                onRelease: vm.releaseBrightness,
                enabled: mode == ControlMode.normal && !vm.screenOff,
              ),
              RoundToggleRow(items: _toggles(l, vm)),
            ],
          ),
          if (failed != null)
            Positioned(
              left: _snackSide,
              right: _snackSide,
              bottom: _snackSide,
              child: CommandSnackbar(text: l.controlFailed(_commandName(l, vm, failed)), onRetry: vm.retry),
            ),
        ],
      );
    },
  );

  /// R-DK-6: back from Số liệu → read the device again.
  Future<void> _details(ControlViewModel vm) async {
    await onOpenDetails(vm.channelSkill);
    await vm.reload();
  }

  /// D-pad and jump tabs work: connected, screen on, not on the night face.
  static bool _usable(ControlViewModel vm) => vm.mode == ControlMode.normal && !vm.screenOff && !vm.nightFace;

  Widget? _banner(AppLocalizations l, ControlViewModel vm) => switch (vm.mode) {
    ControlMode.setup => ControlBanner(
      title: l.controlSetupTitle,
      body: l.controlSetupBody,
      color: AppColors.amber,
      action: l.controlSetupAction,
      onAction: onSetupWifi,
    ),
    ControlMode.offline => ControlBanner(
      title: l.controlOfflineTitle,
      body: l.controlOfflineBody(vm.state!.ip, agoShort(vm.offlineForS)),
      color: AppColors.coral,
      action: l.commonRetry,
      onAction: vm.reload,
    ),
    ControlMode.normal when vm.missing.isNotEmpty => ControlBanner(
      title: l.controlOldFwTitle,
      body: l.controlOldFwBody(
        vm.firmware,
        [
          for (final c in vm.missing)
            switch (c) {
              ControlCommand.prev => l.devControlMissingPrev,
              ControlCommand.pause => l.devControlMissingPause,
              _ => l.devControlMissingScreen,
            },
        ].join(', '),
      ),
      color: AppColors.amber,
      action: l.controlUpdateFirmware,
      onAction: onUpdateFirmware,
    ),
    _ => null,
  };

  /// Channel line, or the card that holds the screen.
  Widget _status(AppLocalizations l, ControlViewModel vm) {
    if (vm.mode == ControlMode.setup) return const SizedBox.shrink();
    final card = vm.holding;
    if (card != null) {
      return HoldCardPanel(
        agent: _agentName(card.agent),
        project: card.project,
        tool: card.value,
        input: card.kind == 'input',
        onDismiss: vm.sending || !vm.caps.dismissCard ? null : vm.dismissCard,
      );
    }
    final skill = vm.channelSkill;
    final accent = skill == null ? AppColors.muted : SkillStyle.of(skill).accent;
    if (vm.screenOff) {
      return ChannelProgress(
        title: l.controlScreenOffTitle,
        note: l.controlScreenOffNote,
        noteColor: AppColors.amber,
        progress: 0,
        accent: AppColors.muted,
      );
    }
    if (vm.nightFace) {
      return ChannelProgress(
        title: l.controlNightTitle,
        note: l.controlNightNote(vm.nightEnd),
        noteColor: AppColors.lilac,
        progress: 0,
        accent: AppColors.lilac,
      );
    }
    if (vm.paused) {
      return ChannelProgress(
        title: _channelTitle(l, vm),
        note: l.controlPausedNote,
        noteColor: AppColors.amber,
        progress: vm.progress,
        accent: AppColors.amber,
      );
    }
    final left = vm.secondsLeft;
    return ChannelProgress(
      title: _channelTitle(l, vm),
      note: vm.switching ? l.controlJustSwitched : (left == null ? '' : l.controlNextIn(left)),
      noteColor: AppColors.muted,
      progress: vm.switching ? 0 : vm.progress,
      accent: accent,
    );
  }

  List<PadItem> _pad(AppLocalizations l, ControlViewModel vm) {
    final usable = _usable(vm);
    PadLook look(ControlCommand c) =>
        !vm.caps.supports(c) ? PadLook.locked : (usable ? PadLook.normal : PadLook.disabled);
    final paused = vm.paused;
    return [
      PadItem(
        icon: Icons.chevron_left,
        label: l.controlPrev,
        look: look(ControlCommand.prev),
        onTap: () => vm.step(ControlCommand.prev),
      ),
      PadItem(
        icon: paused ? Icons.play_arrow : Icons.pause,
        label: paused ? l.controlResume : l.controlPause,
        look: look(ControlCommand.pause),
        lit: paused ? AppColors.amber : null,
        onTap: vm.togglePause,
      ),
      PadItem(
        icon: Icons.chevron_right,
        label: l.controlNext,
        look: look(ControlCommand.next),
        onTap: () => vm.step(ControlCommand.next),
      ),
    ];
  }

  List<RoundItem> _toggles(AppLocalizations l, ControlViewModel vm) {
    final normal = vm.mode == ControlMode.normal;
    final off = vm.screenOff;
    return [
      RoundItem(
        icon: Icons.power_settings_new,
        label: off ? l.controlScreenOn : l.controlScreenOff,
        on: off ? AppColors.amber : null,
        look: !vm.caps.screen ? PadLook.locked : (normal ? PadLook.normal : PadLook.disabled),
        onTap: vm.toggleScreen,
      ),
      RoundItem(
        icon: Icons.dark_mode_outlined,
        label: l.controlNight,
        on: vm.nightOn ? AppColors.lilac : null,
        look: normal && !off ? PadLook.normal : PadLook.disabled,
        onTap: vm.toggleNight,
      ),
      RoundItem(
        icon: Icons.bar_chart,
        label: l.controlDetails,
        look: vm.mode == ControlMode.setup ? PadLook.disabled : PadLook.normal,
        onTap: () => _details(vm),
      ),
    ];
  }

  static String _agentName(String agent) => agent.isEmpty ? agent : '${agent[0].toUpperCase()}${agent.substring(1)}';

  /// Name of the channel on the mirror ("Claude", "Thời tiết", card title…).
  static String _channelTitle(AppLocalizations l, ControlViewModel vm) => switch (vm.channel) {
    'Attention' => l.cardKind(vm.cards.isEmpty ? '' : vm.cards.first.kind),
    'Night' => l.controlNightTitle,
    'Setup' => l.devXpTitleSetup,
    'Home' => 'glimmer',
    'Agents' => l.devXpTitleAgents,
    'AI' => l.devXpTitleAi,
    'Trend' => l.devXpTitleTrend,
    'Photo' => l.devXpTitlePhoto,
    'Weather' => l.devXpTitleWeather,
    'Forecast' => l.devXpTitleForecast,
    'Clock' => l.devXpTitleClock,
    'Info' => l.devXpTitleInfo,
    final c => c,
  };

  /// Button name in the "not done" snackbar.
  static String _commandName(AppLocalizations l, ControlViewModel vm, ControlCommand c) => switch (c) {
    ControlCommand.prev => l.controlPrev,
    ControlCommand.next => l.controlNext,
    ControlCommand.pause => l.controlPause,
    ControlCommand.resume => l.controlResume,
    ControlCommand.jump => SkillStyle.name(l, vm.failedSkill),
    ControlCommand.screenOff => l.controlScreenOff,
    ControlCommand.screenOn => l.controlScreenOn,
    ControlCommand.dismissCard => l.controlDismissCard,
    ControlCommand.brightness => l.controlBrightness,
    ControlCommand.night => l.controlNight,
    ControlCommand.refresh => l.controlRefreshA11y,
  };
}
