import 'package:flutter/foundation.dart';

import '../../../data/repositories/backup/backup_repository.dart';
import '../../../data/repositories/device/device_repository.dart';
import '../../../data/repositories/release/release_repository.dart';
import '../../../domain/models/app_error.dart';
import '../../../domain/models/config_backup.dart';
import '../../../domain/models/device_state.dart';
import '../../../domain/models/release.dart';
import '../../../domain/rules/update_rules.dart' as rules;
import '../../../utils/result.dart';
import '../../../utils/safe_notifier.dart';

/// What a long operation is doing (the progress card).
enum DeviceStep {
  joinApRestore,
  sendConfig,
  waitReboot,
  download,
  flashFw,
  flashFs,
  rebootingAfterFlash,
  backup,
  toSetupAp,
  rebooting,
}

/// Messages for the snackbar.
enum DeviceNoticeKind {
  backupFailed,
  invalidBackup,
  restoreDone,
  restoreSentNotFound,
  restoreFailed,
  restoreLater,
  updateNoAnswer,
  updateDone,
  updateFailed,
}

class DeviceNotice {
  const DeviceNotice(this.kind, {this.error, this.text = ''});
  final DeviceNoticeKind kind;
  final AppError? error;

  /// Firmware version ([DeviceNoticeKind.updateDone]) or backup path ([DeviceNoticeKind.restoreLater]).
  final String text;
}

/// Device info, Wi-Fi, firmware updates, config backup/restore, reboot (screen_specs §4).
class DeviceViewModel extends ChangeNotifier with SafeNotifier {
  DeviceViewModel({
    required DeviceRepository device,
    required ReleaseRepository releases,
    required BackupRepository backups,
    this.restoreAttempts = 21,
    this.restoreGap = const Duration(seconds: 6),
    this.toSetupApWait = const Duration(seconds: 20),
  })  : _device = device,
        _releases = releases,
        _backups = backups {
    _device.addListener(notifyListeners);
  }

  final DeviceRepository _device;
  final ReleaseRepository _releases;
  final BackupRepository _backups;

  /// Looking for the device after a restore: tries × gap.
  final int restoreAttempts;
  final Duration restoreGap;

  /// Full update: wait for the device to drop to glimmer-setup after the filesystem flash.
  final Duration toSetupApWait;

  Release? _release;
  AppError? _releaseError;
  DeviceStep? _step;
  String _stepArg = '';
  double? _progress;
  final _notices = <DeviceNotice>[];

  DeviceState? get state => _device.state;
  String get repo => _releases.repo;
  Release? get release => _release;
  AppError? get releaseError => _releaseError;

  /// R-TB-1.
  bool get updateAvailable => rules.updateAvailable(_device.state?.buildTime, _release);

  /// R-TB-4: a long operation is running; null when idle.
  DeviceStep? get step => _step;
  bool get busy => _step != null;

  /// File name for [DeviceStep.download].
  String get stepArg => _stepArg;

  /// 0..1, null = indeterminate.
  double? get progress => _progress;

  /// Snackbar messages since the last call.
  List<DeviceNotice> takeNotices() {
    final n = List<DeviceNotice>.of(_notices);
    _notices.clear();
    return n;
  }

  void _say(DeviceNotice n) {
    _notices.add(n);
    notifyListeners();
  }

  void _setStep(DeviceStep? s, [double? p, String arg = '']) {
    _step = s;
    _progress = p;
    _stepArg = arg;
    notifyListeners();
  }

  Future<void> checkRelease() async {
    switch (await _releases.latest()) {
      case Ok(:final value):
        _release = value;
      case Error(:final error):
        _releaseError = AppError.from(error);
    }
    notifyListeners();
  }

  void forget() => _device.forget();

  // ── backup ──
  Future<void> backup(String shareText) async {
    try {
      final cfg = _unwrap(await _device.exportConfig());
      final path = _unwrap(await _backups.save(cfg));
      _unwrap(await _backups.share(path, shareText));
    } catch (e) {
      _say(DeviceNotice(DeviceNoticeKind.backupFailed, error: AppError.from(e)));
    }
  }

  /// Let the user pick a file; null when cancelled or invalid (invalid → a notice, R-TB-2).
  Future<ConfigBackup?> pickBackup() async {
    switch (await _backups.pick()) {
      case Ok(:final value):
        return value;
      case Error(:final error):
        _say(DeviceNotice(DeviceNoticeKind.invalidBackup, error: AppError.from(error)));
        return null;
    }
  }

  Future<void> restore(ConfigBackup b) => _importConfig(b.config);

  /// Import a config: directly when reachable, else through glimmer-setup. Then wait for the device.
  Future<bool> _importConfig(Map<String, dynamic> cfg) async {
    var viaAp = false;
    try {
      String? at;
      if (!await _device.reachable()) {
        _setStep(DeviceStep.joinApRestore);
        if (!await _device.ensureWifiPermissions() || !await _device.joinSetupAp()) {
          throw const AppError(AppErrorKind.setupAp);
        }
        viaAp = true;
        at = DeviceRepository.setupApUrl;
      }
      _setStep(DeviceStep.sendConfig);
      _unwrap(await _device.importConfig(cfg, at: at));
      if (viaAp) {
        viaAp = false;
        await _device.leaveSetupAp();
      }
      _setStep(DeviceStep.waitReboot);
      final found = await _device.rediscover(attempts: restoreAttempts, gap: restoreGap, keep: true);
      _say(DeviceNotice(found ? DeviceNoticeKind.restoreDone : DeviceNoticeKind.restoreSentNotFound));
      return true;
    } catch (e) {
      if (viaAp) await _device.leaveSetupAp();
      _say(DeviceNotice(DeviceNoticeKind.restoreFailed, error: AppError.from(e)));
      return false;
    } finally {
      _setStep(null);
    }
  }

  // ── updates ──
  Future<Uint8List> _download(String name) async => _unwrap(await _releases.download(_release!, name,
      onProgress: (p) => _setStep(DeviceStep.download, p, name)));

  Future<void> _flash(String field, Uint8List image) async => _unwrap(await _device.upload(field, image,
      onProgress: (p) => _setStep(field == 'firmware' ? DeviceStep.flashFw : DeviceStep.flashFs, p)));

  /// Firmware only: keeps the filesystem (config, fonts, history).
  Future<void> updateFirmware() async {
    try {
      final fw = await _download('firmware.bin');
      await _flash('firmware', fw);
      _setStep(DeviceStep.rebootingAfterFlash);
      final s = await _device.waitOnline();
      _say(s == null
          ? const DeviceNotice(DeviceNoticeKind.updateNoAnswer)
          : DeviceNotice(DeviceNoticeKind.updateDone, text: s.fw));
      await _device.refresh();
    } catch (e) {
      _say(DeviceNotice(DeviceNoticeKind.updateFailed, error: AppError.from(e)));
    } finally {
      _setStep(null);
    }
  }

  /// R-TB-3: firmware + filesystem (fonts, web UI). The filesystem image carries no config, so: back it
  /// up, flash both, then restore it through the setup AP the device opens when it finds no config.
  Future<void> updateFull() async {
    try {
      _setStep(DeviceStep.backup);
      final cfg = _unwrap(await _device.exportConfig());
      if (!rules.isGlimmerConfig(cfg)) throw const AppError(AppErrorKind.configUnreadable);
      final backupPath = _unwrap(await _backups.save(cfg));
      final fw = await _download('firmware.bin');
      final fs = await _download('littlefs.bin');
      await _flash('firmware', fw);
      _setStep(DeviceStep.waitReboot);
      if (await _device.waitOnline() == null) throw const AppError(AppErrorKind.noAnswerAfterFlash);
      await _flash('filesystem', fs);
      _setStep(DeviceStep.toSetupAp);
      await Future<void>.delayed(toSetupApWait);
      if (!await _importConfig(cfg)) {
        _say(DeviceNotice(DeviceNoticeKind.restoreLater, text: backupPath));
      }
    } catch (e) {
      _say(DeviceNotice(DeviceNoticeKind.updateFailed, error: AppError.from(e)));
    } finally {
      _setStep(null);
    }
  }

  Future<void> reboot() async {
    await _device.reboot();
    _setStep(DeviceStep.rebooting);
    await _device.waitOnline();
    _setStep(null);
    await _device.refresh();
  }

  static T _unwrap<T>(Result<T> r) => switch (r) {
        Ok(:final value) => value,
        Error(:final error) => throw AppError.from(error),
      };

  @override
  void dispose() {
    _device.removeListener(notifyListeners);
    super.dispose();
  }
}
