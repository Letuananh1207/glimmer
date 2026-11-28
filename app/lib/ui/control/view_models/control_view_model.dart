import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../../data/repositories/device/device_repository.dart';
import '../../../domain/models/app_error.dart';
import '../../../domain/models/attention_card.dart';
import '../../../domain/models/calc_state.dart';
import '../../../domain/models/clock_view.dart';
import '../../../domain/models/control.dart';
import '../../../domain/models/cursor.dart';
import '../../../domain/models/mines_game.dart';
import '../../../domain/models/device_state.dart';
import '../../../domain/models/mirror_frame.dart';
import '../../../domain/models/touch.dart';
import '../../../domain/models/windows.dart';
import '../../../domain/models/xp_views.dart';
import '../../../domain/rules/board_rules.dart';
import '../../../domain/rules/calc_rules.dart';
import '../../../domain/rules/clock_rules.dart';
import '../../../domain/rules/control_rules.dart' as rules;
import '../../../domain/rules/cursor_rules.dart';
import '../../../domain/rules/keyboard_rules.dart';
import '../../../domain/rules/mines_rules.dart';
import '../../../domain/rules/start_rules.dart';
import '../../../domain/rules/mirror_rules.dart';
import '../../../domain/rules/touch_rules.dart';
import '../../../domain/rules/xp_program_rules.dart';
import '../../../domain/use_cases/control_device_use_case.dart';
import '../../../utils/result.dart';
import '../../../utils/safe_notifier.dart';

part 'control_pointer.dart';
part 'control_programs.dart';

/// Whole-screen situation of the remote (screen_specs §8 `setup` / `offline`).
enum ControlMode { normal, setup, offline }

/// Điều khiển (tab 1, screen_specs §8, design 2026-11-26.6 / .7 / .8): the device screen, touched like a mouse — the app is the
/// computer (open windows, installed programs), the device its screen (R-DK-7…10).
/// R-DK-1 optimistic: a touch changes the mirror at once (that is the feedback: no ripple, no chip), the command goes
/// out once; a different answer or none →
/// the mirror and the windows follow the device and [failed] is set (the snackbar's Thử lại is the user's).
/// R-DK-6: the state is re-read when the screen opens and on [reload] (back from Số liệu).
class ControlViewModel extends ChangeNotifier with SafeNotifier {
  ControlViewModel({
    required DeviceRepository device,
    required ControlDeviceUseCase control,
    DateTime Function() now = DateTime.now,
    math.Random? random,
    this.failureFor = const Duration(seconds: 6),
  }) : _device = device,
       _control = control,
       _now = now,
       _random = random ?? math.Random() {
    // R-DK-7 (L-7): back on the tab in the same run of the app → the windows as they were, no `Home`.
    final kept = control.session;
    if (kept != null) {
      _windows = kept;
      _sentWindows = kept;
      _started = true;
    }
    _device.addListener(_onDevice);
    _onDevice();
    unawaited(reload());
  }

  final DeviceRepository _device;
  final ControlDeviceUseCase _control;

  final DateTime Function() _now;

  /// Where Dò mìn's mines go (R-DK-23); seeded in tests.
  final math.Random _random;

  /// R-DK-23: the Dò mìn game the app keeps (the device draws it).
  MinesGame _minesGame = MinesGame.fresh;

  /// R-DK-24…29: the XP programs' views the app keeps (control_programs.dart).
  final _p = _XpPrograms();

  /// How long the "not done" snackbar stays.
  final Duration failureFor;

  Map<String, dynamic>? _settings;

  /// R-DK-14: the Weather window's last tab (Weather = Hiện tại, Forecast = Dự báo) — restoring it shows that tab, as XP.
  String _weatherTab = 'Weather';

  bool get _real => rules.xpReal(_settings);
  String _windowOf(String channel) => rules.windowOf(channel, real: _real);
  String? _pendingChannel;
  bool? _pendingScreen;
  int? _pendingNight;
  int? _brightness;
  double? _drag;
  ControlCommand? _sending;
  ControlCommand? _failed;
  String _failedApp = '';
  Future<void> Function()? _retry;
  Timer? _failureTimer;
  DateTime? _lastOk;
  int _lastNight = 2;
  bool _rotationStopped = false;

  /// R-DK-7: the windows the app keeps for the device screen; empty when the app opens (the desktop shows).
  WindowStack _windows = WindowStack.empty;

  /// R-DK-7: the first state read decided the start (desktop sent, or already there); before it nothing is adopted.
  bool _started = false;

  /// What the device last took from `POST /api/windows` (sent again only when it changes).
  WindowStack? _sentWindows;

  /// R-DK-11: the context menu over the device screen (optimistic), or null.
  MenuView? _menu;

  /// Skills on at the last state read (R-DK-9: a skill turned on → its desktop icon selected).
  List<String>? _skillsBefore;

  // R-DK-17…20 (control_pointer.dart): the pointer, the lit menu item, Start open, the power button pressed.
  Cursor _cursor = Cursor.home;
  MenuItem? _lit;
  bool _startOpen = false;
  bool _startAll = false;
  PowerState? _pendingPower;
  DateTime? _cursorSentAt;
  Timer? _cursorTimer;

  // ── what the device shows ──

  DeviceState? get state => _device.state;
  List<AttentionCard> get cards => _device.cards;
  ControlCaps get caps => _control.caps;

  ControlMode get mode {
    final s = _device.state;
    if (s != null && _device.error?.kind == AppErrorKind.unreachable) return ControlMode.offline;
    if (s != null && s.inSetupMode) return ControlMode.setup;
    return ControlMode.normal;
  }

  /// Seconds since the device last answered (offline banner).
  int get offlineForS => _lastOk == null ? 0 : _now().difference(_lastOk!).inSeconds;

  /// Channel on the mirror: the optimistic one while a command is on its way, else the device's.
  String get channel => _pendingChannel ?? _device.state?.activeChannel ?? '';

  /// Skill of [channel] (accent of the program line); null = system channel / desktop.
  String? get channelSkill => channel.isEmpty || channel == 'Home' ? null : rules.channelSkill(channel);

  bool get screenOff => !(_pendingScreen ?? _device.state?.screenOn ?? true);
  bool get nightFace => _device.state?.nightFace ?? false;

  /// R-DK-7: open windows, the one on top, the minimized ones.
  WindowStack get windows => _windows;

  /// R-DK-9: programs of the enabled skills, by group (Start, Tất cả chương trình).
  Map<ProgramGroup, List<String>> get programs => rules.programsOf(_device.state?.skillsOn ?? const [], _settings);

  /// Commands can be sent at all: connected, screen on, not on the night face.
  bool get usable => mode == ControlMode.normal && !screenOff && !nightFace;

  /// Touches reach the device (R-DK-10: the firmware has them).
  bool get touchable => usable && caps.touch;

  /// `nightMode` of Cài đặt ≠ 0 (the Chế độ đêm toggle).
  bool get nightOn => (_pendingNight ?? (_settings?['nightMode'] as num?)?.toInt() ?? 0) != 0;

  /// Night window end "07:00" (night note).
  String get nightEnd {
    final m = (_settings?['nightEndMin'] as num?)?.toInt() ?? 0;
    return '${(m ~/ 60 % 24).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
  }

  /// The agent card holding the device screen (HoldCardPanel), or null.
  AttentionCard? get holding => rules.holdingCard(_device.state, _device.cards);

  String? get badge => badgeText(agentsWaiting(_device.cards));

  /// A command is on its way.
  bool get sending => _sending != null;

  /// The last command the device did not take (snackbar), or null.
  ControlCommand? get failed => _failed;

  /// Program of a failed open / close / minimize (the snackbar names it).
  String get failedApp => _failedApp;

  /// Brightness shown (5…100): the dragged value while dragging, else the device's.
  int get brightness =>
      (_drag ?? (_brightness ?? (_settings?['brightness'] as num?)?.toInt() ?? 50).toDouble()).round();
  bool get dragging => _drag != null;

  /// Mirror veil while dragging (illustration): darker as brightness goes down.
  double get dim => _drag == null ? 0 : (1 - _drag! / 100) * 0.6;

  /// Old firmware (R-DK-3 / R-DK-10): what this device lacks, and its version.
  List<ControlCommand> get missing => caps.missing;
  String get firmware => _device.state?.fw ?? '';

  /// The picture of the device screen (no slide progress: the device does not rotate, design 2026-11-26.6).
  MirrorFrame? get frame {
    final s = _device.state;
    if (s == null) return null;
    return mirrorFrameOf(
      _pendingScreen == null ? s : s.withControl(screenOn: _pendingScreen),
      channel: _pendingChannel,
      cards: _device.cards,
      settings: _settings,
      now: _now(),
      windows: _windows,
      menu: _menu,
      clockView: _clockView,
    );
  }

  // ── device updates ──

  void _onDevice() {
    final s = _device.state;
    if (s != null && _device.error == null) _lastOk = _now();
    if (s != null) _noticeInstalled(s.skillsOn);
    if (s != null && _sending == null && _started) _follow(s.activeChannel);
    _pushWindows();
    notifyListeners();
  }

  /// R-DK-9: a skill just turned on (Skill tab, web) → its first desktop icon is selected, as XP shows a new program.
  void _noticeInstalled(List<String> on) {
    final before = _skillsBefore;
    _skillsBefore = on;
    if (before == null) return;
    for (final k in on) {
      if (before.contains(k)) continue;
      final icon = rules.deskProgramOf(k);
      if (icon != null) _windows = _windows.select(icon);
    }
  }

  /// The open windows down to the device whenever they change (panel P-2026-11-26.14); a miss is tried again on
  /// the next change or state read — the screen still follows the app's own list.
  void _pushWindows() {
    if (!_started || !caps.windows || _windows == _sentWindows) return;
    final w = _windows;
    _sentWindows = w;
    unawaited(
      _control.sendWindows(w).then((r) {
        if (r is Error<void> && identical(_sentWindows, w)) _sentWindows = null;
      }),
    );
  }

  /// R-DK-16: the Ngày và Giờ window as the user touched it here (the device keeps the same, POST /api/clock).
  ClockView _clockView = ClockView.today;
  ClockView get clockView => _clockView;

  /// R-DK-11: the menu on screen.
  MenuView? get menu => _menu;

  /// R-DK-7: the device shows a program the app did not open → it is on top now; the desktop → the top one went down.
  /// Cards, the night face and setup leave the windows alone. R-DK-9: windows of programs no longer installed go.
  void _follow(String active) {
    final skillsOn = _device.state?.skillsOn ?? const <String>[];
    final installed = rules.programSet(skillsOn, _settings);
    bool kept(String p) => installed.contains(p) || rules.keepsWindow(p, skillsOn);
    var w = _windows.only(kept);
    final win = _windowOf(active);
    if (win == 'Weather' && _real) _weatherTab = active;
    if (rules.isProgram(active) && kept(win) && w.top != win) {
      w = w.opened(win);
    } else if (active == 'Home' && w.top != null) {
      w = w.minimize(w.top!);
    }
    _windows = w;
  }

  /// R-DK-6: read the device state and its settings now.
  Future<void> reload() async {
    await _device.refresh();
    final r = await _device.settings();
    if (r is Ok<Map<String, dynamic>>) {
      _settings = r.value;
      final n = (r.value['nightMode'] as num?)?.toInt() ?? 0;
      if (n != 0) _lastNight = n;
      await _stopRotation();
    }
    final s = _device.state;
    if (!_started && s != null && mode == ControlMode.normal) {
      _started = true;
      await _startAtDesktop(s.activeChannel);
    } else if (s != null && _sending == null && _started) {
      _follow(s.activeChannel);
    }
    _pushWindows();
    notifyListeners();
  }

  /// R-DK-7: the app opens on the desktop with no windows; a program on the device screen is sent back to `Home`
  /// once (a refusal leaves the device as it is and adopts what it shows).
  Future<void> _startAtDesktop(String active) async {
    if (!rules.isProgram(active) || !caps.touch) {
      if (rules.isProgram(active)) _follow(active);
      return;
    }
    _pendingChannel = 'Home';
    await _run(ControlCommand.desktop, () => _control.open('Home', c: ControlCommand.desktop));
  }

  /// R-DK-7: the device never rotates on its own; `autoRotate` still on → off, once per screen.
  Future<void> _stopRotation() async {
    if (_rotationStopped || mode != ControlMode.normal || !rules.rotationOn(_settings)) return;
    _rotationStopped = true;
    final r = await _control.stopRotation(_settings);
    if (r is Ok<ControlOutcome>) _settings = {...?_settings, 'autoRotate': false};
  }

  // ── commands ──

  /// Runs [send] with the optimistic values already set; clears them after and reports a miss (R-DK-1). [undo] puts
  /// the app's own state back on a miss, before the windows follow the device again.
  Future<void> _run(
    ControlCommand c,
    Future<Result<ControlOutcome>> Function() send, {
    String app = '',
    void Function()? undo,
  }) async {
    _sending = c;
    _clearFailure();
    notifyListeners();
    final r = await send();
    _sending = null;
    _pendingChannel = null;
    _pendingScreen = null;
    final miss = switch (r) {
      Ok(:final value) => !value.matched,
      Error() => true,
    };
    if (miss) {
      _pendingNight = null;
      _brightness = null;
      undo?.call();
      _fail(c, app, () => _run(c, send, app: app, undo: undo));
    }
    final s = _device.state;
    if (s != null) _follow(s.activeChannel);
    _menu = null; // any channel command closes the device's menu
    _pushWindows();
    notifyListeners();
  }

  void _fail(ControlCommand c, String app, Future<void> Function() retry) {
    _failed = c;
    _failedApp = app;
    _retry = retry;
    _failureTimer?.cancel();
    _failureTimer = Timer(failureFor, () {
      _clearFailure();
      notifyListeners();
    });
  }

  void _clearFailure() {
    _failureTimer?.cancel();
    _failureTimer = null;
    _failed = null;
    _retry = null;
  }

  /// Snackbar "Thử lại": the user sends the failed command again (never automatic, R-DK-1).
  Future<void> retry() async {
    final r = _retry;
    if (r != null) await r();
  }

  void dismissFailure() {
    _clearFailure();
    notifyListeners();
  }

  bool _can(ControlCommand c) => caps.supports(c) && !sending;

  // ── touches (R-DK-8) ──

  /// A tap at ([x], [y]) in device pixels; returns what it hit. [TouchKind.start] is the screen's to handle (opens
  /// Start, the app's own — also on firmware without touches). R-DK-10: nothing is sent while not [touchable].
  TouchTarget tap(double x, double y) {
    final f = frame;
    if (f == null || !usable || sending) return TouchTarget.none;
    final m = _menu;
    if (m != null) {
      _menuTap(m, x, y);
      return TouchTarget.none;
    }
    if (f.channel == 'Clock' && touchable && caps.clock) {
      final d = f.deviceNow;
      final h = clockHitAt(x, y, _clockView, year: d.year, month: d.month);
      if (h.kind != ClockHitKind.none) {
        unawaited(_clockTouch(h, d));
        return TouchTarget.none;
      }
    }
    if (touchable && _programTap(f.channel, x, y)) return TouchTarget.none; // R-DK-24…28
    final t = touchTargetAt(x, y, f);
    if (!touchable) return t.kind == TouchKind.start ? t : TouchTarget.none;
    switch (t.kind) {
      case TouchKind.minimize:
        unawaited(minimizeTop());
      case TouchKind.close:
        unawaited(closeTop());
      case TouchKind.taskbar:
        unawaited(taskbar(t.program!));
      case TouchKind.icon:
        unawaited(openProgram(t.program!));
      case TouchKind.tray:
        unawaited(openProgram('Weather')); // R-DK-13 (P-2026-11-26.21): the tray icon opens the Weather window
      case TouchKind.balloonClose:
        unawaited(balloon(false));
      case TouchKind.trayClock:
        unawaited(openProgram('Clock')); // R-DK-14: XP's tray clock opens Date and Time Properties
      case TouchKind.balloonBody:
        unawaited(openProgram('Weather'));
      case TouchKind.tab:
        unawaited(weatherTab(t.program!));
      case TouchKind.trash:
        if (_control.xp.explorer) unawaited(openExplorer(ExplorerPlace.trash)); // R-DK-29
      case TouchKind.none when f.channel == 'Home' && _windows.sel != null:
        _windows = _windows.select(null); // a tap on an empty spot drops the selection (XP)
        _pushWindows();
        notifyListeners();
      case TouchKind.none || TouchKind.maximize || TouchKind.start:
        break; // □: windows on the device are always full screen
    }
    return t;
  }

  /// R-DK-13: the desktop's tray balloon. The mirror follows the answer (the repository patches `balloon`); a refusal
  /// changes nothing on screen.
  Future<void> balloon(bool show) async {
    if (!caps.balloon) return;
    await _control.balloon(show);
  }

  // ── context menus (R-DK-11) ──

  /// A hold (≥ 500 ms) at ([x], [y]): the XP right-click menu of what is under the finger, drawn on the device.
  Future<void> hold(double x, double y) async {
    final f = frame;
    if (f == null || !touchable || !caps.windows || sending) return;
    if (_menu != null) return closeMenu();
    final m = holdMenuAt(x, y, f, minimized: _windows.minimized);
    if (m == null) return;
    _menu = m;
    notifyListeners();
    final r = await _control.menu(m);
    if (r is Error<void> && _menu == m) {
      _menu = null;
      notifyListeners();
    }
  }

  /// R-DK-15: the app's Start sheet opened / switched to Tất cả chương trình ([all]) / closed — the device draws XP's
  /// Start menu meanwhile (it only draws; the sheet picks). A context menu on screen gives way to it.
  Future<void> startMenu(bool open, {bool all = false}) async {
    if (!touchable || !caps.windows) return;
    if (open && _menu != null) {
      _menu = null;
      notifyListeners();
    }
    await _control.startMenu(open, all: all);
  }

  /// Close the menu without choosing (a tap outside it, XP).
  Future<void> closeMenu() async {
    if (_menu == null) return;
    _menu = null;
    notifyListeners();
    await _control.menu(null);
  }

  /// A tap while the menu is open: outside → close; a lit item → do it (the command closes the device's menu).
  void _menuTap(MenuView m, double x, double y) {
    if (!menuContains(m, x, y)) {
      unawaited(closeMenu());
      return;
    }
    final item = menuItemAt(m, x, y);
    if (item == null || !m.enabled(item)) return;
    _menuDo(m, item);
  }

  /// Item [item] of menu [m] chosen (a tap / click on it, Enter on the lit one — R-DK-19).
  void _menuDo(MenuView m, MenuItem item) {
    final p = m.program;
    switch (item) {
      case MenuItem.refresh:
        unawaited(closeMenu()); // the device repaints the desktop when the menu closes
      case MenuItem.properties:
        // R-DK-29: the desktop's Thuộc tính = Display Properties (XP); older firmware: System Properties.
        unawaited(openProgram(_control.xp.display ? displayProgram : 'Info'));
      case MenuItem.restore when p != null:
        unawaited(openProgram(p));
      case MenuItem.minimize when p != null:
        unawaited(p == _shownWindow ? minimizeTop() : _windowOff(p, close: false));
      case MenuItem.close when p != null:
        unawaited(p == _shownWindow ? closeTop() : _windowOff(p, close: true));
      default:
        break; // Sắp xếp biểu tượng ▸: its sub-menu is not drawn yet
    }
  }

  /// Minimize / close a window that is not on screen: only the list (and the device's taskbar) changes.
  Future<void> _windowOff(String program, {required bool close}) async {
    _windows = close ? _windows.close(program) : _windows.minimize(program);
    await closeMenu();
    _pushWindows();
    notifyListeners();
  }

  /// The window on the device screen: the program shown, if it is one.
  String? get _shownWindow => rules.isProgram(channel) ? _windowOf(channel) : null;

  /// Open [program] (desktop icon, Start, Tất cả chương trình): it comes to the top. R-DK-14: the Weather window
  /// comes back on its last tab.
  Future<void> openProgram(String program) async {
    if (_device.state == null || !usable || !_can(ControlCommand.open)) return;
    final win = _windowOf(program);
    if (win == 'Clock' && channel != 'Clock') _clockView = ClockView.today; // XP's dialog opens on today
    final show = win == 'Weather' && _real && program == 'Weather' ? _weatherTab : program;
    if (win == 'Mines') unawaited(_sendMines()); // the device draws the game the app keeps (R-DK-23)
    _programOpening(win); // R-DK-24…28: so do the XP programs
    final before = _windows;
    _windows = _windows.opened(win);
    _pendingChannel = show;
    await _run(ControlCommand.open, () => _control.open(show), app: win, undo: () => _windows = before);
  }

  /// R-DK-16: a touch on the Ngày và Giờ window — the view changes at once (the device draws the same), a picked
  /// zone goes to the settings (`tzMinutes`), "Cập nhật ngay" asks the time servers again.
  Future<void> _clockTouch(ClockHit h, DateTime today) async {
    final v = _clockView;
    final year = v.year ?? today.year, month = v.month ?? today.month;
    final zone = clockZones.indexOf((_settings?['tzMinutes'] as num?)?.toInt() ?? 0);
    var sync = false;
    int? newZone;
    _clockView = switch (h.kind) {
      ClockHitKind.tab => v.copyWith(tab: ClockTab.values[h.value], list: ClockList.none),
      ClockHitKind.monthList =>
        v.list == ClockList.month
            ? v.copyWith(list: ClockList.none)
            : v.copyWith(list: ClockList.month, top: listTopFor(ClockList.month, month - 1)),
      ClockHitKind.yearUp => v.copyWith(year: (year + 1).clamp(1970, 2099), month: month, clearDay: true),
      ClockHitKind.yearDown => v.copyWith(year: (year - 1).clamp(1970, 2099), month: month, clearDay: true),
      ClockHitKind.day => v.copyWith(year: year, month: month, day: h.value),
      ClockHitKind.pickMonth => v.copyWith(year: year, month: h.value, list: ClockList.none, clearDay: true),
      ClockHitKind.zoneList =>
        v.list == ClockList.zone
            ? v.copyWith(list: ClockList.none)
            : v.copyWith(list: ClockList.zone, top: listTopFor(ClockList.zone, zone < 0 ? 0 : zone)),
      ClockHitKind.pickZone => v.copyWith(list: ClockList.none),
      ClockHitKind.scrollUp => v.copyWith(top: (v.top - 1).clamp(0, listMaxTop(v.list))),
      ClockHitKind.scrollDown => v.copyWith(top: (v.top + 1).clamp(0, listMaxTop(v.list))),
      ClockHitKind.closeList => v.copyWith(list: ClockList.none),
      ClockHitKind.sync || ClockHitKind.none => v,
    };
    if (h.kind == ClockHitKind.sync) sync = true;
    if (h.kind == ClockHitKind.pickZone) newZone = clockZones[h.value];
    notifyListeners();
    await _control.clock(_clockView, sync: sync);
    if (newZone != null) {
      final r = await _control.timeZone(newZone);
      if (r is Ok<ControlOutcome>) _settings = {...?_settings, 'tzMinutes': newZone};
      notifyListeners();
    }
  }

  /// R-DK-14: a tab of the Weather window (Weather = Hiện tại, Forecast = Dự báo); the shown tab does nothing.
  Future<void> weatherTab(String tab) async {
    if (tab == channel) return;
    _weatherTab = tab;
    await openProgram(tab);
  }

  /// `_`: the desktop shows, the window keeps its taskbar button.
  Future<void> minimizeTop() async {
    final w = _shownWindow;
    if (w == null || !usable || !_can(ControlCommand.minimize)) return;
    final before = _windows;
    _windows = _windows.opened(w).minimize(w);
    _pendingChannel = 'Home';
    await _run(
      ControlCommand.minimize,
      () => _control.open('Home', c: ControlCommand.minimize),
      app: w,
      undo: () => _windows = before,
    );
  }

  /// `×`: the window is gone, the one before it comes up (none → the desktop).
  Future<void> closeTop() async {
    final w = _shownWindow;
    if (w == null || !usable || !_can(ControlCommand.close)) return;
    final before = _windows;
    _windows = _windows.opened(w).close(w);
    final next = _windows.top ?? 'Home';
    _pendingChannel = next;
    await _run(
      ControlCommand.close,
      () => _control.open(next, c: ControlCommand.close),
      app: w,
      undo: () => _windows = before,
    );
  }

  /// A taskbar button = an open window (R-DK-8): the one on screen goes down (as XP); another comes to the top.
  Future<void> taskbar(String program) async {
    if (program == _shownWindow) return minimizeTop();
    return openProgram(program);
  }

  /// Start → Desktop: every window down, the desktop shows (XP "Show desktop").
  Future<void> desktop() async {
    if (_device.state == null || !usable || !_can(ControlCommand.desktop)) return;
    final before = _windows;
    _windows = _windows.minimizeAll();
    _pendingChannel = 'Home';
    await _run(
      ControlCommand.desktop,
      () => _control.open('Home', c: ControlCommand.desktop),
      undo: () => _windows = before,
    );
  }

  /// Start → Khởi động lại (the screen asks first).
  Future<void> restart() async {
    if (sending) return;
    await _control.restart();
  }

  /// Chế độ đêm: `nightMode` 0 ↔ the last mode used (default 2, clock face).
  Future<void> toggleNight() async {
    if (!_can(ControlCommand.night)) return;
    final mode = nightOn ? 0 : _lastNight;
    _pendingNight = mode;
    await _run(ControlCommand.night, () async {
      final r = await _control.nightMode(mode);
      if (r is Ok<ControlOutcome>) {
        _settings = {...?_settings, 'nightMode': mode};
        _pendingNight = null;
      }
      return r;
    });
  }

  /// Brightness thumb moved (only the app changes, R-DK-5).
  void dragBrightness(double pct) {
    _drag = pct.clamp(5, 100).toDouble();
    notifyListeners();
  }

  /// Thumb released: send once (R-DK-5); a refusal puts the old value back.
  Future<void> releaseBrightness() async {
    final v = _drag?.round();
    _drag = null;
    if (v == null || sending) {
      notifyListeners();
      return;
    }
    _brightness = v;
    await _run(ControlCommand.brightness, () async {
      final r = await _control.brightness(v);
      if (r is Ok<ControlOutcome>) _settings = {...?_settings, 'brightness': v};
      return r;
    });
    _brightness = null;
  }

  /// "Bỏ thẻ khỏi màn" (R-DK-2): removes the holding card from the device screen only.
  Future<void> dismissCard() async {
    final card = holding;
    if (card == null || !_can(ControlCommand.dismissCard)) return;
    await _run(ControlCommand.dismissCard, () => _control.dismissCard(card.id));
  }

  /// Header refresh: the device fetches its sources now.
  Future<void> refreshData() async {
    if (sending) return;
    await _run(ControlCommand.refresh, _control.refreshData);
  }

  @override
  void dispose() {
    _control.session = _windows;
    _device.removeListener(_onDevice);
    _failureTimer?.cancel();
    _cursorTimer?.cancel();
    super.dispose();
  }
}
