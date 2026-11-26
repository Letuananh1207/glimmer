import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import '../../../data/repositories/device/device_repository.dart';
import '../../../domain/models/app_error.dart';
import '../../../domain/models/attention_card.dart';
import '../../../domain/models/control.dart';
import '../../../domain/models/device_photo.dart';
import '../../../domain/models/device_state.dart';
import '../../../domain/models/mirror_frame.dart';
import '../../../domain/models/touch.dart';
import '../../../domain/models/windows.dart';
import '../../../domain/rules/board_rules.dart';
import '../../../domain/rules/control_rules.dart' as rules;
import '../../../domain/rules/mirror_rules.dart';
import '../../../domain/rules/touch_rules.dart';
import '../../../domain/use_cases/control_device_use_case.dart';
import '../../../domain/use_cases/load_photos_use_case.dart';
import '../../../utils/result.dart';
import '../../../utils/safe_notifier.dart';

/// Whole-screen situation of the remote (screen_specs §8 `setup` / `offline`).
enum ControlMode { normal, setup, offline }

/// What the chip on the mirror's shell says while a command is on its way (`StatusChip`).
enum ChipKind { sending, minimizing, closing, opening, openingApp }

/// Note after the program name under the mirror.
enum LineNote { openOnDevice, justOpened, minimized, tapIcon }

/// Điều khiển (tab 1, screen_specs §8, design 2026-11-26.6): the device screen, touched like a mouse — the app is the
/// computer (open windows, installed programs), the device its screen (R-DK-7…10).
/// R-DK-1 optimistic: a touch changes the mirror at once, the command goes out once; a different answer or none →
/// the mirror and the windows follow the device and [failed] is set (the snackbar's Thử lại is the user's).
/// R-DK-6: the state is re-read when the screen opens and on [reload] (back from Số liệu).
class ControlViewModel extends ChangeNotifier with SafeNotifier {
  ControlViewModel({
    required DeviceRepository device,
    required ControlDeviceUseCase control,
    LoadPhotosUseCase? loadPhotos,
    DateTime Function() now = DateTime.now,
    this.failureFor = const Duration(seconds: 6),
  }) : _device = device,
       _control = control,
       _loadPhotos = loadPhotos,
       _now = now {
    _device.addListener(_onDevice);
    _onDevice();
    unawaited(reload());
  }

  final DeviceRepository _device;
  final ControlDeviceUseCase _control;

  /// The device's photos + the app's copies (Photo channel of the mirror); null = not wired (tests).
  final LoadPhotosUseCase? _loadPhotos;
  PhotoGallery? _gallery;
  ui.Image? _photoImage;
  Uint8List? _photoJpeg;
  final DateTime Function() _now;

  /// How long the "not done" snackbar stays.
  final Duration failureFor;

  Map<String, dynamic>? _settings;
  String? _pendingChannel;
  bool? _pendingScreen;
  int? _pendingNight;
  int? _brightness;
  double? _drag;
  ControlCommand? _sending;
  ChipKind _chip = ChipKind.sending;
  String _chipApp = '';
  ControlCommand? _failed;
  String _failedApp = '';
  Future<void> Function()? _retry;
  Timer? _failureTimer;
  DateTime? _lastOk;
  int _lastNight = 2;
  bool _rotationStopped = false;

  /// R-DK-7: the windows the app keeps for the device screen.
  WindowStack _windows = WindowStack.empty;
  LineNote _note = LineNote.openOnDevice;
  String _minimizedApp = '';

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

  /// Note under the mirror; for [LineNote.minimized] the program that went down is [minimizedApp].
  LineNote get note => channel == 'Home' ? (_note == LineNote.minimized ? _note : LineNote.tapIcon) : _note;
  String get minimizedApp => _minimizedApp;

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

  /// A command is on its way (`StatusChip`).
  bool get sending => _sending != null;
  ChipKind get chip => _chip;

  /// Program named by the chip ("Đang tắt Claude…").
  String get chipApp => _chipApp;

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
      gallery: _gallery,
    );
  }

  // ── device updates ──

  void _onDevice() {
    final s = _device.state;
    if (s != null && _device.error == null) _lastOk = _now();
    if (s != null && _sending == null) _follow(s.activeChannel);
    notifyListeners();
  }

  /// R-DK-7: the device shows a program the app did not open → it is on top now; the desktop → the top one went down.
  /// Cards, the night face and setup leave the windows alone. R-DK-9: windows of programs no longer installed go.
  void _follow(String active) {
    final installed = rules.programSet(_device.state?.skillsOn ?? const [], _settings);
    var w = _windows.only(installed.contains);
    if (rules.isProgram(active) && installed.contains(active) && w.top != active) {
      w = w.opened(active);
      _note = LineNote.openOnDevice;
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
    if (s != null && _sending == null) _follow(s.activeChannel);
    await _reloadPhotos();
    notifyListeners();
  }

  /// R-DK-7: the device never rotates on its own; `autoRotate` still on → off, once per screen.
  Future<void> _stopRotation() async {
    if (_rotationStopped || mode != ControlMode.normal || !rules.rotationOn(_settings)) return;
    _rotationStopped = true;
    final r = await _control.stopRotation(_settings);
    if (r is Ok<ControlOutcome>) _settings = {...?_settings, 'autoRotate': false};
  }

  /// The app's copy of the photo the mirror's Photo channel draws, decoded; null = none.
  ui.Image? get photoImage => _photoImage;

  /// Photo skill on: the device's photo list and the app's copies (the device cannot send its photos back).
  Future<void> _reloadPhotos() async {
    final load = _loadPhotos;
    if (load == null || !(_device.state?.skillsOn.contains('photo') ?? false)) return;
    final r = await load();
    if (r is! Ok<PhotoGallery>) return;
    _gallery = r.value;
    final jpeg = frame?.agents.photo.jpeg;
    if (identical(jpeg, _photoJpeg)) return;
    _photoJpeg = jpeg;
    ui.Image? img;
    if (jpeg != null) {
      try {
        final codec = await ui.instantiateImageCodec(jpeg);
        img = (await codec.getNextFrame()).image;
        codec.dispose();
      } on Exception {
        img = null;
      }
    }
    _photoImage?.dispose();
    _photoImage = img;
  }

  // ── commands ──

  /// Runs [send] with the optimistic values already set; clears them after and reports a miss (R-DK-1). [undo] puts
  /// the app's own state back on a miss, before the windows follow the device again.
  Future<void> _run(
    ControlCommand c,
    Future<Result<ControlOutcome>> Function() send, {
    String app = '',
    ChipKind chip = ChipKind.sending,
    void Function()? undo,
  }) async {
    _sending = c;
    _chip = chip;
    _chipApp = app;
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
      _fail(c, app, () => _run(c, send, app: app, chip: chip, undo: undo));
    }
    final s = _device.state;
    if (s != null) _follow(s.activeChannel);
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
    final t = touchTargetAt(x, y, f);
    if (!touchable) return t.kind == TouchKind.start ? t : TouchTarget.none;
    switch (t.kind) {
      case TouchKind.minimize:
        unawaited(minimizeTop());
      case TouchKind.close:
        unawaited(closeTop());
      case TouchKind.taskbar:
        unawaited(taskbar(t.skill!));
      case TouchKind.icon:
        unawaited(openProgram(t.program!));
      case TouchKind.none || TouchKind.maximize || TouchKind.start:
        break; // □: windows on the device are always full screen
    }
    return t;
  }

  /// The window on the device screen: the program shown, if it is one.
  String? get _shownWindow => rules.isProgram(channel) ? channel : null;

  /// Open [program] (desktop icon, Start, Tất cả chương trình): it comes to the top.
  Future<void> openProgram(String program, {LineNote note = LineNote.openOnDevice}) async {
    if (_device.state == null || !usable || !_can(ControlCommand.open)) return;
    final before = _windows;
    _windows = _windows.opened(program);
    _note = note;
    _pendingChannel = program;
    await _run(
      ControlCommand.open,
      () => _control.open(program),
      app: program,
      chip: ChipKind.openingApp,
      undo: () => _windows = before,
    );
  }

  /// `_`: the desktop shows, the window keeps its taskbar button.
  Future<void> minimizeTop() async {
    final w = _shownWindow;
    if (w == null || !usable || !_can(ControlCommand.minimize)) return;
    final before = _windows;
    _windows = _windows.opened(w).minimize(w);
    _note = LineNote.minimized;
    _minimizedApp = w;
    _pendingChannel = 'Home';
    await _run(
      ControlCommand.minimize,
      () => _control.open('Home', c: ControlCommand.minimize),
      app: w,
      chip: ChipKind.minimizing,
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
    _note = LineNote.openOnDevice;
    _pendingChannel = next;
    await _run(
      ControlCommand.close,
      () => _control.open(next, c: ControlCommand.close),
      app: w,
      chip: ChipKind.closing,
      undo: () => _windows = before,
    );
  }

  /// A taskbar button: the shown window of that skill goes down (as XP); else its latest window, else its first
  /// program.
  Future<void> taskbar(String skill) async {
    final top = _shownWindow;
    if (top != null && rules.channelSkill(top) == skill) return minimizeTop();
    final w = rules.latestWindowOf(_windows.open, skill);
    if (w != null) return openProgram(w, note: LineNote.justOpened);
    if (_device.state == null || !usable || sending) return;
    final first = rules.jumpCandidates(skill, _settings).first;
    final before = _windows;
    _windows = _windows.opened(first);
    _note = LineNote.justOpened;
    _pendingChannel = first;
    await _run(
      ControlCommand.open,
      () => _control.jump(skill, settings: _settings),
      app: first,
      chip: ChipKind.opening,
      undo: () => _windows = before,
    );
  }

  /// Start → Desktop: every window down, the desktop shows (XP "Show desktop").
  Future<void> desktop() async {
    if (_device.state == null || !usable || !_can(ControlCommand.desktop)) return;
    final before = _windows;
    _windows = _windows.minimizeAll();
    _note = LineNote.tapIcon;
    _pendingChannel = 'Home';
    await _run(
      ControlCommand.desktop,
      () => _control.open('Home', c: ControlCommand.desktop),
      chip: ChipKind.opening,
      undo: () => _windows = before,
    );
  }

  /// Start → Khởi động lại (the screen asks first).
  Future<void> restart() async {
    if (sending) return;
    await _control.restart();
  }

  /// Tắt / bật màn now.
  Future<void> toggleScreen() async {
    final on = screenOff;
    final c = on ? ControlCommand.screenOn : ControlCommand.screenOff;
    if (!_can(c)) return;
    _pendingScreen = on;
    await _run(c, () => _control.screen(on));
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
    _device.removeListener(_onDevice);
    _failureTimer?.cancel();
    _photoImage?.dispose();
    super.dispose();
  }
}
