import 'package:flutter/material.dart';

import '../../../domain/models/control.dart';
import '../../../domain/models/touch.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/labels.dart';
import '../../core/themes/app_colors.dart';
import '../../../utils/durations.dart';
import '../view_models/control_view_model.dart';
import 'control_parts.dart';
import 'control_toggles.dart';
import 'device_mirror/channels/photo_channel.dart';
import 'device_mirror/mirror_channel.dart';
import 'device_mirror/touch_mirror.dart';
import 'hold_card_panel.dart';
import 'program_style.dart';
import 'start_menu_sheet.dart';

/// Điều khiển (tab 1, screen_specs §8, design 2026-11-26.6 / .7 / .8): đầu màn, thanh báo (firmware chưa nhận chạm /
/// glimmer-setup / mất kết nối), `TouchMirror` chạm như chuột, `HoldCardPanel` hoặc dòng màn tắt / ban đêm,
/// `BrightnessSlider`, `RoundToggle` (tắt màn, chế độ đêm, số liệu); chạm start → `StartMenuSheet`; `CommandSnackbar`
/// nổi trên thanh dưới khi lệnh không được nhận. Không chip, không chữ nào về chuyển / thu nhỏ / tắt app.
class ControlScreen extends StatelessWidget {
  const ControlScreen({
    super.key,
    required this.viewModel,
    required this.onOpenDetails,
    required this.onUpdateFirmware,
    required this.onSetupWifi,
    required this.onOpenSettings,
    required this.onOpenSkills,
  });

  final ControlViewModel viewModel;

  /// Số liệu (push), at the tab of skill (null = first); completes when it closes.
  final Future<void> Function(String? skill) onOpenDetails;

  /// [onUpdateFirmware] = tab Thiết bị (also Start → Thiết bị).
  final VoidCallback onUpdateFirmware, onSetupWifi, onOpenSettings, onOpenSkills;

  static const _snackSide = 12.0;
  static const _bottomPad = 16.0;
  static const _mirrorTop = 6.0;

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
      final touches = vm.usable;
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
                child: TouchMirror(
                  frame: vm.frame,
                  channels: withPhoto(mirrorChannels, vm.photoImage),
                  semanticLabel: l.controlScreenA11y(_title(l, vm)),
                  dim: vm.dim,
                  offline: mode == ControlMode.offline,
                  onTap: touches ? (x, y) => _tap(context, vm, x, y) : null,
                  // R-DK-11: giữ = chuột phải → menu ngữ cảnh vẽ trên thiết bị.
                  onHold: vm.touchable && vm.caps.windows ? (x, y) => vm.hold(x, y) : null,
                ),
              ),
              ?_status(l, vm),
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

  /// A touch on the mirror; start opens Start (R-DK-10: also on firmware without touches).
  void _tap(BuildContext context, ControlViewModel vm, double x, double y) {
    if (vm.tap(x, y).kind == TouchKind.start) _start(context, vm);
  }

  void _start(BuildContext context, ControlViewModel vm) => showStartMenu(
    context,
    StartActions(
      programs: vm.programs,
      open: {...vm.windows.open},
      programsEnabled: vm.usable,
      onOpen: vm.openProgram,
      onDesktop: vm.desktop,
      onDetails: () => _details(vm),
      onControlPanel: onOpenSettings,
      onAddRemove: onOpenSkills,
      onDevice: onUpdateFirmware,
      onTurnOff: vm.toggleScreen,
      onRestart: () => _confirmRestart(context, vm),
    ),
  );

  Future<void> _confirmRestart(BuildContext context, ControlViewModel vm) async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.deviceReboot),
        content: Text(l.deviceRebootBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(false), child: Text(l.commonCancel)),
          TextButton(onPressed: () => Navigator.of(c).pop(true), child: Text(l.startRestart)),
        ],
      ),
    );
    if (ok == true) await vm.restart();
  }

  /// R-DK-6: back from Số liệu → read the device again.
  Future<void> _details(ControlViewModel vm) async {
    await onOpenDetails(vm.channelSkill);
    await vm.reload();
  }

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
    ControlMode.normal when !vm.caps.touch => ControlBanner(
      title: l.controlOldFwTitle,
      body: l.controlOldFwBody(vm.firmware),
      color: AppColors.amber,
      action: l.controlUpdateFirmware,
      onAction: onUpdateFirmware,
    ),
    _ => null,
  };

  /// The card that holds the screen, or the screen-off / night line; nothing otherwise (2026-11-26.7).
  Widget? _status(AppLocalizations l, ControlViewModel vm) {
    if (vm.mode == ControlMode.setup) return null;
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
    if (vm.screenOff) {
      return ChannelLine(
        title: l.controlScreenOffTitle,
        note: l.controlScreenOffNote,
        noteColor: AppColors.amber,
        accent: AppColors.muted,
      );
    }
    if (vm.nightFace) {
      return ChannelLine(
        title: l.controlNightTitle,
        note: l.controlNightNote(vm.nightEnd),
        noteColor: AppColors.lilac,
        accent: AppColors.lilac,
      );
    }
    return null;
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

  /// Name of what the mirror shows ("Claude", "Desktop", card title…).
  static String _title(AppLocalizations l, ControlViewModel vm) => switch (vm.channel) {
    'Attention' => l.cardKind(vm.cards.isEmpty ? '' : vm.cards.first.kind),
    'Night' => l.controlNightTitle,
    'Setup' => l.devXpTitleSetup,
    final c => ProgramStyle.name(l, c),
  };

  /// Command name in the "not done" snackbar.
  static String _commandName(AppLocalizations l, ControlViewModel vm, ControlCommand c) {
    final app = ProgramStyle.name(l, vm.failedApp);
    return switch (c) {
      ControlCommand.open => l.devControlCmdOpen(app),
      ControlCommand.minimize => l.devControlCmdMinimize(app),
      ControlCommand.close => l.devControlCmdClose(app),
      ControlCommand.desktop => l.startDesktop,
      ControlCommand.screenOff => l.controlScreenOff,
      ControlCommand.screenOn => l.controlScreenOn,
      ControlCommand.dismissCard => l.controlDismissCard,
      ControlCommand.brightness => l.controlBrightness,
      ControlCommand.night => l.controlNight,
      ControlCommand.refresh => l.controlRefreshA11y,
    };
  }
}
