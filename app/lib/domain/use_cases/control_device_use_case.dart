import '../../data/repositories/device/device_repository.dart';
import '../../utils/result.dart';
import '../models/app_error.dart';
import '../models/clock_view.dart';
import '../models/control.dart';
import '../models/device_state.dart';
import '../models/cursor.dart';
import '../models/mines_game.dart';
import '../models/touch.dart';
import '../models/windows.dart';
import '../rules/control_rules.dart';
import '../rules/cursor_rules.dart';
import '../rules/mines_rules.dart';

/// The app remote (tab Điều khiển, R-DK-1…10): sends one command, once, and says whether the device did what was
/// asked. Optimistic display is the caller's; this only reconciles (R-DK-1: no automatic retry). A command the
/// firmware lacks is refused without sending (R-DK-3).
class ControlDeviceUseCase {
  ControlDeviceUseCase({required DeviceRepository device}) : _device = device;

  final DeviceRepository _device;
  int _cursorSeq = 0;

  /// R-DK-7 (L-7): the open windows of this run of the app. The Điều khiển tab's ViewModel goes away with the tab;
  /// coming back to it is not "the app just opened" — it takes these back instead of sending the desktop.
  WindowStack? session;

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
  /// R-DK-18: [hover] = the item lit under the pointer / by the arrow keys (only with the mouse firmware).
  Future<Result<void>> menu(MenuView? m, {MenuItem? hover}) async {
    if (!caps.windows) return Result.error(AppError(AppErrorKind.controlUnsupported, detail: 'menu'));
    if (m == null) return _device.setMenu(const {'kind': 'none'});
    return _device.setMenu({...m.toJson(), if (caps.mouse && hover != null) 'hover': menuHoverIndex(m, hover)});
  }

  /// R-DK-17: the pointer to the device (UDP, ~30 / s, the caller sends only on change). False = not sent (R-DK-21:
  /// firmware without the mouse, or no network); nothing to undo.
  Future<bool> cursor(Cursor c) async {
    if (!caps.mouse) return false;
    _cursorSeq = (_cursorSeq + 1) & 0xFFFF;
    return _device.sendCursor(cursorPacket(_cursorSeq, c));
  }

  /// R-DK-23: the Dò mìn game [g] at [now] goes down to be drawn. Nothing on firmware without it.
  Future<Result<void>> mines(MinesGame g, DateTime now) async {
    if (!caps.mines) return const Result.ok(null);
    return _device.setMines(minesBody(g, now));
  }

  /// R-DK-24…29: the XP programs this firmware draws.
  XpPrograms get xp => _device.state?.xpPrograms ?? const XpPrograms();

  /// R-DK-24, 26, 27, 28: the view of XP program [program] (`taskmgr`, `display`, `calc`, `explorer`) to draw.
  /// Nothing on firmware without it.
  Future<Result<void>> programView(String program, Map<String, Object?> body) async {
    final has = switch (program) {
      'taskmgr' => xp.taskMgr,
      'display' => xp.display,
      'calc' => xp.calc,
      'explorer' => xp.explorer,
      _ => false,
    };
    if (!has) return const Result.ok(null);
    return _device.setProgramView(program, body);
  }

  /// R-DK-25: the Alt+Tab box with tile [sel] chosen; null closes it.
  Future<Result<void>> altTab(int? sel) async {
    if (!xp.altTab) return const Result.ok(null);
    return _device.setMenu(sel == null ? const {'kind': 'none'} : {'kind': 'alttab', 'sel': sel});
  }

  /// R-DK-26: Thuộc tính màn hình's OK / Áp dụng — the pending values saved as the device's settings.
  Future<Result<ControlOutcome>> saveSettings(Map<String, dynamic> values) => _setting(values);

  /// R-DK-30: the device works out clicks itself (`input.stage` ≥ 1): the app sends mouse v2.
  bool get deviceInput => (_device.state?.inputStage ?? 0) >= 1 && caps.mouse;

  /// R-DK-30: the pointer at [c] with [buttons] held (mouse v2). A button change goes out [mouseRepeats] times with
  /// one seq. False = not sent.
  Future<bool> mouse(Cursor c, {int buttons = 0, bool change = false}) async {
    if (!caps.mouse) return false;
    _cursorSeq = (_cursorSeq + 1) & 0xFFFF;
    final p = mousePacket(_cursorSeq, c, buttons);
    var ok = false;
    for (var i = 0; i < (change ? mouseRepeats : 1); i++) {
      ok = await _device.sendCursor(p) || ok;
    }
    return ok;
  }

  /// R-DK-31: the device also opens the context menus and takes the keys (`input.stage` ≥ 3).
  bool get deviceKeys => (_device.state?.inputStage ?? 0) >= 3 && caps.mouse;

  int _keySeq = 0;

  /// R-DK-31: key [key] to the device, [mouseRepeats] copies with one seq.
  Future<bool> key(ControlKey key) async {
    if (!caps.mouse) return false;
    _keySeq = (_keySeq + 1) & 0xFFFF;
    final p = keyPacket(_keySeq, key);
    var ok = false;
    for (var i = 0; i < mouseRepeats; i++) {
      ok = await _device.sendCursor(p) || ok;
    }
    return ok;
  }

  /// R-DK-30: a click of button [button] (1 left, 2 right) at [c]: pressed, then let go.
  Future<bool> click(Cursor c, {int button = 1}) async {
    final down = await mouse(c, buttons: button, change: true);
    final up = await mouse(c, change: true);
    return down && up;
  }

  /// R-DK-20: the power button. Refused without the mouse firmware (R-DK-21).
  Future<Result<PowerState>> power(bool on) async {
    if (!caps.mouse) return Result.error(AppError(AppErrorKind.controlUnsupported, detail: 'power'));
    return _device.setPower(on);
  }

  /// R-DK-13: the desktop's tray balloon (tray icon → show 10 s, × → hide). Refused without the firmware for it.
  Future<Result<bool>> balloon(bool show) async {
    if (!caps.balloon) return Result.error(AppError(AppErrorKind.controlUnsupported, detail: 'balloon'));
    return _device.setBalloon(show);
  }

  /// R-DK-16: the Ngày và Giờ window as touched ([sync]: ask the time servers again now). Nothing on older firmware.
  Future<Result<void>> clock(ClockView v, {bool sync = false}) async {
    if (!caps.clock) return const Result.ok(null);
    return _device.setClock({...v.toJson(), if (sync) 'sync': true});
  }

  /// R-DK-16: the device's time zone picked in the Múi giờ list (`tzMinutes`, as Cài đặt).
  Future<Result<ControlOutcome>> timeZone(int minutes) => _setting({'tzMinutes': minutes});

  /// R-DK-15: XP's Start menu on the device (panel P-2026-11-26.20) — open ([all] = Tất cả chương trình) or closed.
  /// Nothing on firmware without menus.
  Future<Result<void>> startMenu(bool open, {bool all = false}) async {
    if (!caps.windows) return const Result.ok(null);
    return _device.setMenu(open ? {'kind': 'start', 'all': all} : const {'kind': 'none'});
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
