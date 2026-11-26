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
import '../../../domain/rules/board_rules.dart';
import '../../../domain/rules/control_rules.dart' as rules;
import '../../../domain/rules/mirror_rules.dart';
import '../../../domain/use_cases/control_device_use_case.dart';
import '../../../domain/use_cases/load_photos_use_case.dart';
import '../../../domain/use_cases/toggle_skill_use_case.dart';
import '../../../utils/result.dart';
import '../../../utils/safe_notifier.dart';

/// Whole-screen situation of the remote (screen_specs §8 `setup` / `offline`).
enum ControlMode { normal, setup, offline }

/// Điều khiển (tab 1, screen_specs §8, design 2026-11-26.5): the device mirror + remote buttons.
/// R-DK-1 optimistic: a button changes the mirror at once, the command goes out once; a different answer or none →
/// the mirror follows the device and [failed] is set (the snackbar's Thử lại is the user's, never automatic).
/// R-DK-6: the state is re-read when the screen opens and on [reload] (back from Số liệu).
class ControlViewModel extends ChangeNotifier with SafeNotifier {
  ControlViewModel({
    required DeviceRepository device,
    required ControlDeviceUseCase control,
    required ToggleSkillUseCase toggleSkill,
    LoadPhotosUseCase? loadPhotos,
    DateTime Function() now = DateTime.now,
    this.failureFor = const Duration(seconds: 6),
    this.tickEvery = const Duration(milliseconds: 250),
  }) : _device = device,
       _control = control,
       _toggle = toggleSkill,
       _loadPhotos = loadPhotos,
       _now = now {
    _device.addListener(_onDevice);
    _onDevice();
    unawaited(reload());
  }

  final DeviceRepository _device;
  final ControlDeviceUseCase _control;
  final ToggleSkillUseCase _toggle;

  /// The device's photos + the app's copies (Photo channel of the mirror); null = not wired (tests).
  final LoadPhotosUseCase? _loadPhotos;
  PhotoGallery? _gallery;
  ui.Image? _photoImage;
  Uint8List? _photoJpeg;
  final DateTime Function() _now;

  /// How long the "not done" snackbar stays.
  final Duration failureFor;

  /// Countdown refresh of the channel line while rotating.
  final Duration tickEvery;

  Map<String, dynamic>? _settings;
  String? _pendingChannel;
  bool? _pendingPaused, _pendingScreen;
  int? _pendingNight;
  int? _brightness;
  double? _drag;
  ControlCommand? _sending;
  ControlCommand? _failed;
  String _failedSkill = '';
  Future<void> Function()? _retry;
  Timer? _failureTimer, _ticker;
  DateTime? _slideEnd, _lastOk;
  int _lastNight = 2;

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

  /// Skill of [channel] (lit jump tab, accent of the channel line); null = system channel.
  String? get channelSkill => channel.isEmpty ? null : rules.channelSkill(channel);

  bool get paused => _pendingPaused ?? _device.state?.paused ?? false;
  bool get screenOff => !(_pendingScreen ?? _device.state?.screenOn ?? true);
  bool get nightFace => _device.state?.nightFace ?? false;

  /// `nightMode` of Cài đặt ≠ 0 (the Chế độ đêm toggle).
  bool get nightOn => (_pendingNight ?? (_settings?['nightMode'] as num?)?.toInt() ?? 0) != 0;

  /// Night window end "07:00" (night channel note).
  String get nightEnd {
    final m = (_settings?['nightEndMin'] as num?)?.toInt() ?? 0;
    return '${(m ~/ 60 % 24).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
  }

  /// The agent card holding the device screen (HoldCardPanel), or null.
  AttentionCard? get holding => rules.holdingCard(_device.state, _device.cards);

  /// Enabled skills in dock order (JumpTabBar; one skill → the single-skill note instead).
  List<String> get skills => _toggle.enabled;
  String? get badge => badgeText(agentsWaiting(_device.cards));

  /// A command is on its way (chip "Đang gửi…").
  bool get sending => _sending != null;

  /// A channel command is on its way (channel line "· vừa chuyển").
  bool get switching =>
      _sending == ControlCommand.next || _sending == ControlCommand.prev || _sending == ControlCommand.jump;

  /// The last command the device did not take (snackbar), or null.
  ControlCommand? get failed => _failed;

  /// Skill id of a failed jump (snackbar names its tab).
  String get failedSkill => _failedSkill;

  /// Rotation countdown: whole seconds left, null when not rotating / unknown (no `slide_left_ms`).
  int? get secondsLeft {
    final end = _slideEnd;
    if (end == null || paused) return null;
    return rules.secondsLeft(end.difference(_now()).inMilliseconds);
  }

  /// Share of the slide already shown, 0…1 (channel line bar; held where it stopped while paused).
  double get progress {
    final s = _device.state;
    final end = _slideEnd;
    if (s == null || end == null || s.slideMs <= 0) return paused ? _heldProgress : 0;
    return rules.slideProgress(s.slideMs, end.difference(_now()).inMilliseconds);
  }

  double _heldProgress = 0;

  /// Brightness shown (5…100): the dragged value while dragging, else the device's.
  int get brightness =>
      (_drag ?? (_brightness ?? (_settings?['brightness'] as num?)?.toInt() ?? 50).toDouble()).round();
  bool get dragging => _drag != null;

  /// Mirror veil while dragging (illustration): darker as brightness goes down.
  double get dim => _drag == null ? 0 : (1 - _drag! / 100) * 0.6;

  /// Old firmware (R-DK-3): buttons this device lacks, and its version.
  List<ControlCommand> get missing => caps.missing;
  String get firmware => _device.state?.fw ?? '';

  /// The picture of the device screen.
  MirrorFrame? get frame {
    final s = _device.state;
    if (s == null) return null;
    return mirrorFrameOf(
      _pendingScreen == null ? s : s.withControl(screenOn: _pendingScreen),
      channel: _pendingChannel,
      cards: _device.cards,
      settings: _settings,
      now: _now(),
      slideProgress: progress,
      gallery: _gallery,
    );
  }

  // ── device updates ──

  void _onDevice() {
    final s = _device.state;
    if (s != null && _device.error == null) _lastOk = _now();
    if (s != null && s.slideLeftMs != null && s.slideMs > 0 && s.paused != true) {
      _slideEnd = _now().add(Duration(milliseconds: s.slideLeftMs!));
    } else {
      if (s?.paused == true && _slideEnd != null && s!.slideMs > 0) {
        _heldProgress = rules.slideProgress(s.slideMs, _slideEnd!.difference(_now()).inMilliseconds);
      }
      _slideEnd = null;
    }
    _syncTicker();
    notifyListeners();
  }

  void _syncTicker() {
    final run = _slideEnd != null && !paused;
    if (run && _ticker == null) {
      _ticker = Timer.periodic(tickEvery, (_) => notifyListeners());
    } else if (!run) {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  /// R-DK-6: read the device state and its settings now.
  Future<void> reload() async {
    await _device.refresh();
    final r = await _device.settings();
    if (r is Ok<Map<String, dynamic>>) {
      _settings = r.value;
      final n = (r.value['nightMode'] as num?)?.toInt() ?? 0;
      if (n != 0) _lastNight = n;
    }
    await _reloadPhotos();
    notifyListeners();
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

  /// Runs [send] with the optimistic values already set; clears them after and reports a miss (R-DK-1).
  Future<void> _run(ControlCommand c, Future<Result<ControlOutcome>> Function() send, {String skill = ''}) async {
    _sending = c;
    _clearFailure();
    notifyListeners();
    final r = await send();
    _sending = null;
    _pendingChannel = null;
    _pendingPaused = null;
    _pendingScreen = null;
    final miss = switch (r) {
      Ok(:final value) => !value.matched,
      Error() => true,
    };
    if (miss) {
      _pendingNight = null;
      _brightness = null;
      _fail(c, skill, () => _run(c, send, skill: skill));
    }
    _syncTicker();
    notifyListeners();
  }

  void _fail(ControlCommand c, String skill, Future<void> Function() retry) {
    _failed = c;
    _failedSkill = skill;
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

  /// Kênh sau / trước (d-pad, swipe): the guessed neighbour shows at once.
  Future<void> step(ControlCommand c) async {
    final s = _device.state;
    if (s == null || !_can(c)) return;
    final from = s.activeChannel;
    _pendingChannel = rules.stepChannel(rules.rotationGuess(s, _settings), from, c == ControlCommand.next ? 1 : -1);
    await _run(c, () => _control.step(c, from: from));
  }

  /// Jump tab: the skill's first channel shows at once.
  Future<void> jump(String skill) async {
    if (_device.state == null || !_can(ControlCommand.jump)) return;
    _pendingChannel = rules.jumpCandidates(skill, _settings).first;
    await _run(ControlCommand.jump, () => _control.jump(skill, settings: _settings), skill: skill);
  }

  /// Dừng / tiếp tục xoay (R-DK-4, temporary).
  Future<void> togglePause() async {
    final hold = !paused;
    final c = hold ? ControlCommand.pause : ControlCommand.resume;
    if (!_can(c)) return;
    if (hold) _heldProgress = progress;
    _pendingPaused = hold;
    await _run(c, () => _control.pause(hold));
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
    _ticker?.cancel();
    _photoImage?.dispose();
    super.dispose();
  }
}
