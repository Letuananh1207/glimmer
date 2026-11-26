import '../../data/repositories/device/device_repository.dart';
import '../../utils/result.dart';
import '../models/app_error.dart';
import '../models/control.dart';
import '../models/touch.dart';
import '../models/windows.dart';
import '../rules/control_rules.dart';

/// The app remote (tab Điều khiển, R-DK-1…10): sends one command, once, and says whether the device did what was
/// asked. Optimistic display is the caller's; this only reconciles (R-DK-1: no automatic retry). A command the
/// firmware lacks is refused without sending (R-DK-3).
class ControlDeviceUseCase {
  ControlDeviceUseCase({required DeviceRepository device}) : _device = device;

  final DeviceRepository _device;

  /// R-DK-3: what the connected firmware supports.
  ControlCaps get caps => controlCaps(_device.state);

  Result<ControlOutcome>? _refuse(ControlCommand c) =>
      caps.supports(c) ? null : Result.error(AppError(AppErrorKind.controlUnsupported, detail: c.name));

  /// R-DK-7/8: show [program] (or `Home`, the desktop) now — `/api/channel {name}`. [c] = the touch it comes from
  /// (minimize / close / desktop need the touch firmware, R-DK-10; opening works on any firmware with the remote).
  Future<Result<ControlOutcome>> open(String program, {ControlCommand c = ControlCommand.open}) async {
    final refused = _refuse(c);
    if (refused != null) return refused;
    // `_` minimizes: the device zooms the window down to its button (XP); close / Show desktop do not.
    final r = await _device.channel(name: program, zoomMin: c == ControlCommand.minimize);
    return switch (r) {
      Ok(:final value) => Result.ok(ControlOutcome(active: value.active, matched: value.active == program)),
      Error(:final error) => Result.error(error),
    };
  }

  /// Jump to the first channel of [skill] (`{"name"}`); a 404 means that channel is off → the skill's next one.
  /// [settings] = `/api/settings` (agent channels follow their `show*` flags).
  Future<Result<ControlOutcome>> jump(String skill, {Map<String, dynamic>? settings}) async {
    Result<ChannelAnswer>? last;
    final names = jumpCandidates(skill, settings);
    for (final name in names) {
      last = await _device.channel(name: name);
      final e = last is Error<ChannelAnswer> ? last.error : null;
      if (e is AppError && e.kind == AppErrorKind.http && e.status == 404) continue;
      break;
    }
    return switch (last!) {
      Ok(:final value) => Result.ok(ControlOutcome(active: value.active, matched: channelSkill(value.active) == skill)),
      Error(:final error) => Result.error(error),
    };
  }

  /// R-DK-7: the device never rotates — `autoRotate` off (sent only when [settings] still have it on).
  Future<Result<ControlOutcome>> stopRotation(Map<String, dynamic>? settings) async {
    if (!rotationOn(settings)) return const Result.ok(ControlOutcome());
    return _setting({'autoRotate': false});
  }

  /// The app's open windows go down to the device (panel P-2026-11-26.14); nothing on firmware without it.
  Future<Result<void>> sendWindows(WindowStack w) async {
    if (!caps.windows) return const Result.ok(null);
    return _device.setWindows(w.toJson());
  }

  /// R-DK-11: a context menu over the device screen; null closes it. Refused without the firmware for it.
  Future<Result<void>> menu(MenuView? m) async {
    if (!caps.windows) return Result.error(AppError(AppErrorKind.controlUnsupported, detail: 'menu'));
    return _device.setMenu(m == null ? const {'kind': 'none'} : m.toJson());
  }

  /// R-DK-13: the desktop's tray balloon (tray icon → show 10 s, × → hide). Refused without the firmware for it.
  Future<Result<bool>> balloon(bool show) async {
    if (!caps.balloon) return Result.error(AppError(AppErrorKind.controlUnsupported, detail: 'balloon'));
    return _device.setBalloon(show);
  }

  /// Start → Khởi động lại (asked again by the screen first).
  Future<Result<void>> restart() => _device.reboot();

  /// Backlight off / on now.
  Future<Result<ControlOutcome>> screen(bool on) async {
    final refused = _refuse(on ? ControlCommand.screenOn : ControlCommand.screenOff);
    if (refused != null) return refused;
    final r = await _device.setScreen(on);
    return switch (r) {
      Ok(:final value) => Result.ok(ControlOutcome(screenOn: value, matched: value == on)),
      Error(:final error) => Result.error(error),
    };
  }

  /// R-DK-2: take card [id] off the device screen; nothing is answered for the agent.
  Future<Result<ControlOutcome>> dismissCard(String id) async {
    final refused = _refuse(ControlCommand.dismissCard);
    if (refused != null) return refused;
    final r = await _device.clearCard(id);
    if (r is Error<void>) return Result.error(r.error);
    await _device.refresh();
    return const Result.ok(ControlOutcome());
  }

  /// R-DK-5: brightness 5…100, sent once on release like Cài đặt.
  Future<Result<ControlOutcome>> brightness(int pct) => _setting({'brightness': pct.clamp(5, 100)});

  /// Night mode of Cài đặt (`nightMode`): 0 off, 1 dim, 2 clock face, 3 dark.
  Future<Result<ControlOutcome>> nightMode(int mode) => _setting({'nightMode': mode});

  Future<Result<ControlOutcome>> _setting(Map<String, dynamic> change) async {
    final r = await _device.saveSettings(change);
    return switch (r) {
      Ok() => const Result.ok(ControlOutcome()),
      Error(:final error) => Result.error(error),
    };
  }

  /// "Làm mới số liệu": the device fetches its sources now, then the app re-reads its state.
  Future<Result<ControlOutcome>> refreshData() async {
    final r = await _device.refreshNow();
    if (r is Error<void>) return Result.error(r.error);
    await _device.refresh();
    return const Result.ok(ControlOutcome());
  }
}
