import 'dart:async';

import 'package:flutter/material.dart';

import '../../../domain/models/control.dart';
import '../../../domain/models/cursor.dart';
import '../../../domain/models/start_pick.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text.dart';
import '../../../utils/durations.dart';
import '../view_models/control_view_model.dart';
import 'control_parts.dart';
import 'control_toggles.dart';
import 'hold_card_panel.dart';
import 'key_pad.dart';
import 'power_button.dart';
import 'program_style.dart';
import 'trackpad.dart';

/// Điều khiển (tab 1, screen_specs §8, design 2026-11-27.10): the app is the computer's mouse, keyboard and power
/// button, the device its screen (R-DK-17…22). Đầu màn + `PowerButton`; thanh báo (firmware chưa có chuột /
/// glimmer-setup / mất kết nối); `HoldCardPanel` khi thẻ agent giữ màn; `Trackpad` + `MouseButtons`; `KeyPad`; hàng
/// cuối độ sáng + chế độ đêm + Số liệu; `CommandSnackbar` khi lệnh không được nhận. No picture of the screen.
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

  /// [onUpdateFirmware] = tab Thiết bị (also Start → Thiết bị on the device, R-DK-22).
  final VoidCallback onUpdateFirmware, onSetupWifi, onOpenSettings, onOpenSkills;

  static const _snackSide = 12.0;
  static const _bottomPad = 16.0;
  static const _padH = 190.0, _padBanner = 220.0;
  static const _nightWash = 0.16;

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
      final power = vm.power;
      final pointer = vm.pointerUsable;
      final banner = _banner(l, vm);
      final card = mode == ControlMode.setup ? null : vm.holding;
      final settled = power == PowerState.on || power == PowerState.off;
      final rowOn = mode == ControlMode.normal && power == PowerState.on;
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
                trailing: PowerButton(power: power, onPressed: vm.mouseReady ? vm.pressPower : null),
              ),
              ?banner,
              if (card != null)
                HoldCardPanel(
                  agent: _agentName(card.agent),
                  project: card.project,
                  tool: card.value,
                  input: card.kind == 'input',
                  onDismiss: vm.sending || !vm.caps.dismissCard ? null : vm.dismissCard,
                ),
              Trackpad(
                height: card != null ? _padH : (banner != null ? _padBanner : AppSize.trackpad),
                enabled: pointer,
                onMove: vm.movePointer,
                onTap: () => unawaited(_click(context, vm)),
                onPowerOn: vm.mouseReady && power == PowerState.off ? vm.pressPower : null,
              ),
              MouseButtons(
                enabled: pointer,
                pressedRight: vm.menuOpen,
                onLeft: () => unawaited(_click(context, vm)),
                onRight: () => unawaited(vm.clickRight()),
              ),
              KeyPad(enabled: pointer, onKey: (k) => unawaited(vm.pressKey(k))),
              _bottomRow(context, l, vm, enabled: rowOn && settled),
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

  /// A left click; with Start open on the device it may pick a phone screen or Khởi động lại (R-DK-22).
  Future<void> _click(BuildContext context, ControlViewModel vm) async {
    final pick = await vm.clickLeft();
    if (pick == null || !context.mounted) return;
    switch (pick.screen) {
      case AppScreen.details:
        await _details(vm);
      case AppScreen.settings:
        onOpenSettings();
      case AppScreen.skills:
        onOpenSkills();
      case AppScreen.device:
        onUpdateFirmware();
      case null:
        if (pick.kind == StartPickKind.restart) {
          await _confirmRestart(context, vm);
        }
    }
  }

  Future<void> _confirmRestart(BuildContext context, ControlViewModel vm) async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.deviceReboot),
        content: Text(l.deviceRebootBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(false), child: Text(l.commonCancel)),
          TextButton(onPressed: () => Navigator.of(c).pop(true), child: Text(l.deviceReboot)),
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

  /// Hàng cuối (lề 12 16 0, cách 8): thẻ độ sáng co giãn + chế độ đêm + Số liệu, vuông 52 bo 14 viền `line`.
  Widget _bottomRow(BuildContext context, AppLocalizations l, ControlViewModel vm, {required bool enabled}) => Padding(
    padding: const EdgeInsets.fromLTRB(AppSpace.l, AppSpace.m, AppSpace.l, 0),
    child: Opacity(
      opacity: enabled || vm.mode == ControlMode.normal ? 1 : Trackpad.dimOpacity,
      child: Row(
        children: [
          Expanded(
            child: BrightnessSlider(
              value: vm.brightness,
              dragging: vm.dragging,
              onChanged: vm.dragBrightness,
              onRelease: vm.releaseBrightness,
              enabled: vm.mode == ControlMode.normal && vm.power != PowerState.off,
              margin: EdgeInsets.zero,
            ),
          ),
          const SizedBox(width: AppSpace.s),
          _SquareButton(
            icon: Icons.dark_mode_outlined,
            label: l.controlNightA11y,
            lit: vm.nightOn ? AppColors.lilac : null,
            onTap: enabled ? vm.toggleNight : null,
          ),
          const SizedBox(width: AppSpace.s),
          _SquareButton(
            icon: Icons.bar_chart,
            label: l.controlDetailsA11y,
            onTap: vm.mode == ControlMode.setup ? null : () => unawaited(_details(vm)),
          ),
        ],
      ),
    ),
  );

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
    ControlMode.normal when !vm.caps.mouse => ControlBanner(
      title: l.controlOldFwTitle,
      body: l.controlOldFwBody(vm.firmware),
      color: AppColors.amber,
      action: l.controlUpdateFirmware,
      onAction: onUpdateFirmware,
    ),
    _ => null,
  };

  static String _agentName(String agent) => agent.isEmpty ? agent : '${agent[0].toUpperCase()}${agent.substring(1)}';

  /// Command name in the "not done" snackbar.
  static String _commandName(AppLocalizations l, ControlViewModel vm, ControlCommand c) {
    final app = ProgramStyle.name(l, vm.failedApp);
    return switch (c) {
      ControlCommand.open => l.devControlCmdOpen(app),
      ControlCommand.minimize => l.devControlCmdMinimize(app),
      ControlCommand.close => l.devControlCmdClose(app),
      ControlCommand.desktop => l.devControlCmdDesktop,
      ControlCommand.screenOff => l.powerOff,
      ControlCommand.screenOn => l.powerOn,
      ControlCommand.dismissCard => l.controlDismissCard,
      ControlCommand.brightness => l.controlBrightness,
      ControlCommand.night => l.controlNight,
      ControlCommand.refresh => l.controlRefreshA11y,
    };
  }
}

/// Nút vuông 52 bo 14 viền `line` nền `panel`, icon 22; [lit] = bật (nền 16 %, viền + icon màu đó).
class _SquareButton extends StatelessWidget {
  const _SquareButton({required this.icon, required this.label, required this.onTap, this.lit});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? lit;

  static const _icon = 22.0;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: Opacity(
      opacity: onTap == null ? padDisabledOpacity : 1,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: AppSize.controlSquare,
          height: AppSize.controlSquare,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSize.radiusCard),
            border: Border.all(color: lit ?? AppColors.line),
            color: lit?.withValues(alpha: ControlScreen._nightWash) ?? AppColors.panel,
          ),
          child: Icon(icon, size: _icon, color: lit ?? AppColors.inkDim),
        ),
      ),
    ),
  );
}
