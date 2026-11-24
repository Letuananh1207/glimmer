import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/labels.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text.dart';
import '../view_models/device_view_model.dart';
import 'device_parts.dart';

/// Device info, Wi-Fi, firmware updates, config backup/restore, reboot (screen_specs §4).
class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key, required this.viewModel, required this.onChangeWifi});

  final DeviceViewModel viewModel;

  /// "Đổi Wi-Fi cho thiết bị" → Cài Wi-Fi.
  final VoidCallback onChangeWifi;

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  DeviceViewModel get vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    vm.addListener(_showNotices);
    vm.checkRelease();
  }

  @override
  void dispose() {
    vm.removeListener(_showNotices);
    super.dispose();
  }

  void _showNotices() {
    final notices = vm.takeNotices();
    if (notices.isEmpty || !mounted) return;
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    for (final n in notices) {
      final err = n.error == null ? '' : l.error(n.error!);
      messenger.showSnackBar(SnackBar(
        content: Text(switch (n.kind) {
          DeviceNoticeKind.backupFailed => l.devBackupFailed(err),
          DeviceNoticeKind.invalidBackup => err,
          DeviceNoticeKind.restoreDone => l.devRestoreDone,
          DeviceNoticeKind.restoreSentNotFound => l.devRestoreSentNotFound,
          DeviceNoticeKind.restoreFailed => l.devRestoreFailed(err),
          DeviceNoticeKind.restoreLater => l.devRestoreLater(n.text),
          DeviceNoticeKind.updateNoAnswer => l.devUpdateNoAnswer,
          DeviceNoticeKind.updateDone => l.devUpdateDone(n.text),
          DeviceNoticeKind.updateFailed => l.devUpdateFailed(err),
        }),
      ));
    }
  }

  Future<bool> _confirm(String title, String body, String ok) async {
    final l = AppLocalizations.of(context);
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title),
            content: Text(body),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.commonCancel)),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ok)),
            ],
          ),
        ) ==
        true;
  }

  String _step(AppLocalizations l) => switch (vm.step!) {
        DeviceStep.joinApRestore => l.devStepJoinApRestore,
        DeviceStep.sendConfig => l.deviceStepSendConfig,
        DeviceStep.waitReboot => l.devStepWaitReboot,
        DeviceStep.download => l.deviceStepDownload(vm.stepArg),
        DeviceStep.flashFw => l.deviceStepFlashFw,
        DeviceStep.flashFs => l.deviceStepFlashFs,
        DeviceStep.rebootingAfterFlash => l.deviceStepRebooting,
        DeviceStep.backup => l.deviceStepBackup,
        DeviceStep.toSetupAp => l.devStepToSetupAp,
        DeviceStep.rebooting => l.devStepRebootingShort,
      };

  Future<void> _backup(AppLocalizations l) async {
    if (await _confirm(l.deviceBackup, l.deviceBackupBody, l.deviceBackup)) await vm.backup(l.devBackupShareText);
  }

  Future<void> _restore(AppLocalizations l) async {
    final b = await vm.pickBackup();
    if (b == null) return;
    if (await _confirm(l.deviceRestore, l.deviceRestoreBody(b.fileName), l.deviceRestoreOk)) await vm.restore(b);
  }

  Future<void> _updateFirmware(AppLocalizations l) async {
    if (await _confirm(l.deviceUpdateFw, l.deviceUpdateFwBody(vm.repo), l.deviceUpdate)) await vm.updateFirmware();
  }

  Future<void> _updateFull(AppLocalizations l) async {
    if (await _confirm(l.deviceUpdateFull, l.deviceUpdateFullBody, l.deviceStart)) await vm.updateFull();
  }

  Future<void> _reboot(AppLocalizations l) async {
    if (await _confirm(l.deviceReboot, l.deviceRebootBody, l.deviceReboot)) await vm.reboot();
  }

  String _releaseText(AppLocalizations l) {
    final r = vm.release;
    if (r == null) return vm.releaseError == null ? l.deviceChecking : l.error(vm.releaseError!);
    final latest = '${formatDate(r.published)}${r.commit.isEmpty ? '' : ' · ${r.commit}'}';
    return '${l.deviceLatest(latest)}\n${vm.updateAvailable ? l.deviceNewer : l.deviceUpToDate}';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        final s = vm.state;
        if (s == null) return const Center(child: CircularProgressIndicator());
        final busy = vm.busy;
        final hasRelease = vm.release != null;
        return ListView(padding: const EdgeInsets.only(bottom: AppSpace.xxl), children: [
          if (busy) BusyCard(text: _step(l), progress: vm.progress),
          DeviceInfoCard(state: s),
          Card(
            child: Column(children: [
              ListTile(
                leading: const Icon(Icons.wifi),
                title: Text(l.deviceChangeWifi),
                subtitle: Text(l.deviceChangeWifiSub, style: AppFonts.label),
                enabled: !busy,
                onTap: widget.onChangeWifi,
              ),
              ListTile(
                leading: const Icon(Icons.restart_alt),
                title: Text(l.deviceReboot),
                enabled: !busy,
                onTap: () => _reboot(l),
              ),
              ListTile(
                leading: const Icon(Icons.link_off),
                title: Text(l.deviceForget),
                enabled: !busy,
                onTap: vm.forget,
              ),
            ]),
          ),
          Card(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpace.l, AppSpace.l, AppSpace.l, AppSpace.xs),
                child: Text(l.deviceUpdates, style: AppFonts.label),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.l),
                child: Text(
                  _releaseText(l),
                  style: TextStyle(color: vm.updateAvailable ? AppColors.mint : AppColors.inkDim, fontSize: valueSize),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.system_update),
                title: Text(l.deviceUpdateFw),
                subtitle: Text(l.deviceUpdateFwSub, style: AppFonts.label),
                enabled: !busy && hasRelease,
                onTap: () => _updateFirmware(l),
              ),
              ListTile(
                leading: const Icon(Icons.layers),
                title: Text(l.deviceUpdateFull),
                subtitle: Text(l.deviceUpdateFullSub, style: AppFonts.label),
                enabled: !busy && hasRelease,
                onTap: () => _updateFull(l),
              ),
            ]),
          ),
          Card(
            child: Column(children: [
              ListTile(
                leading: const Icon(Icons.save_alt),
                title: Text(l.deviceBackup),
                subtitle: Text(l.deviceBackupSub, style: AppFonts.label),
                enabled: !busy,
                onTap: () => _backup(l),
              ),
              ListTile(
                leading: const Icon(Icons.settings_backup_restore),
                title: Text(l.deviceRestore),
                enabled: !busy,
                onTap: () => _restore(l),
              ),
            ]),
          ),
        ]);
      },
    );
  }
}
