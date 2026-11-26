import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/repositories/device/device_repository.dart';
import '../../../domain/models/app_error.dart';
import '../../../domain/models/attention_card.dart';
import '../../../domain/models/clawd_mood.dart';
import '../../../domain/models/device_state.dart';
import '../../../domain/models/project.dart';
import '../../../domain/rules/board_rules.dart';
import '../../../domain/rules/time_rules.dart';
import '../../../domain/rules/usage_rules.dart';
import '../../../domain/use_cases/toggle_skill_use_case.dart';
import '../../../utils/result.dart';
import '../../../utils/safe_notifier.dart';

part 'screen_tabs.dart';

/// One usage row (week or 5-hour session).
class UsageRowData {
  const UsageRowData(this.used, this.level, this.resetInS);

  /// % used, -1 = unknown.
  final int used;

  /// Colour (R-DUNG-1); [UsageLevel.unknown] also when the data is stale (R-DUNG-4).
  final UsageLevel level;

  /// Seconds until it resets (R-DUNG-3): null unknown, 0 now.
  final int? resetInS;
}

/// Màn hình (screen_specs §2, 2026-11-25.3 / .4): one tab per enabled dock skill — Agent (usage, project board, cards),
/// Ảnh (its own `PhotoTabViewModel`), Thời tiết, Đồng hồ — plus the agents-waiting badge.
class DashboardViewModel extends ChangeNotifier with SafeNotifier {
  DashboardViewModel({
    required DeviceRepository device,
    required ToggleSkillUseCase toggleSkill,
    DateTime Function() now = DateTime.now,
    String? initialTab,
  })  : _device = device,
        _toggle = toggleSkill,
        _now = now,
        _picked = initialTab {
    _device.addListener(_update);
    _update();
    _loadSettings();
  }

  final DeviceRepository _device;
  final ToggleSkillUseCase _toggle;
  final DateTime Function() _now;

  List<Project> _rows = const [];
  List<String> _tabs = const [];
  String? _picked;
  Map<String, dynamic>? _settings;

  /// Device epoch − phone epoch, from the last state (the clock tab ticks on the phone between polls).
  int _skew = 0;
  int _lastTime = -1;
  Timer? _ticker;
  int _shownMinute = -1;

  // ── tabs ──

  /// Enabled skills in dock order (one dock tab each); legacy firmware → Agent only.
  List<String> get tabs => _tabs;

  /// The DockTabBar shows only with two or more skills.
  bool get showTabs => _tabs.length > 1;

  /// Selected tab: the one picked while it stays enabled, else the first.
  String get selected => _picked != null && _tabs.contains(_picked) ? _picked! : _tabs.first;

  void select(String id) {
    if (!_tabs.contains(id) || id == selected) return;
    _picked = id;
    _syncTicker();
    notifyListeners();
  }

  /// Agents waiting on the user (approval + input), like the firmware's countWaiting.
  int get waiting => agentsWaiting(_device.cards);

  /// Badge on the Agent tab: null at 0, "9+" above 9.
  String? get waitingBadge => badgeText(waiting);

  /// Photos on the device (`photos` of `/api/state`): the Ảnh tab reloads when it changes.
  int? get photoCount => _device.state?.photos;

  /// Đang tải: chưa có trạng thái nào từ thiết bị.
  DeviceState? get state => _device.state;

  /// R-PRJ-1.
  List<Project> get rows => _rows;

  /// R-PRJ-2.
  ClawdMood get mood => moodFor([for (final p in _rows) p.state]);
  bool get walking => _rows.any((p) => p.state == 'working');

  List<AttentionCard> get cards => _device.cards;

  /// Line under the header: the last refresh error, else "cards need a token" (R-KN-4).
  AppError? get error => _device.error;
  bool get cardsNeedToken => _device.cardsNeedToken;

  UsageMeta get meta => usageMeta(_device.state!);

  UsageRowData get week => _row(_device.state!.usage.weeklyUsed, _device.state!.usage.weeklyReset);
  UsageRowData get session => _row(_device.state!.usage.sessionUsed, _device.state!.usage.sessionReset);

  UsageRowData _row(int used, int reset) {
    final s = _device.state!;
    return UsageRowData(used, s.usage.stale ? UsageLevel.unknown : usageLevel(used), secondsUntil(reset, s.time));
  }

  void _update() {
    final s = _device.state;
    _rows = boardRows(s?.projects ?? const []);
    _tabs = _toggle.enabled;
    if (s != null && s.time != _lastTime) {
      _lastTime = s.time;
      _skew = s.time - _phoneEpoch;
    }
    _syncTicker();
    notifyListeners();
  }

  Future<void> refresh() async {
    await _device.refresh();
    await _loadSettings();
  }

  Future<void> _loadSettings() async {
    final r = await _device.settings();
    if (r is Ok<Map<String, dynamic>>) {
      _settings = r.value;
      notifyListeners();
    }
  }

  // ── weather / clock ──

  int get _phoneEpoch => _now().millisecondsSinceEpoch ~/ 1000;

  bool get _synced => _device.state?.clockSynced ?? false;

  /// Device time now (phone time before the device clock is set).
  int get _epoch => _synced ? _phoneEpoch + _skew : _phoneEpoch;

  /// Device time zone from `/api/settings`; the phone's until those load.
  int get _tz => (_settings?['tzMinutes'] as num?)?.toInt() ?? _now().timeZoneOffset.inMinutes;

  WeatherView get weather => WeatherView.from(
        _device.state!,
        now: _epoch,
        today: deviceLocal(_epoch, _tz),
        fahrenheit: _settings?['useFahrenheit'] == true,
      );

  ClockView get clock => ClockView.from(epoch: _epoch, synced: _synced, tzMinutes: _tz, settings: _settings);

  /// Tick once a second while the Đồng hồ tab shows; rebuild only when the minute changes.
  void _syncTicker() {
    final on = _device.state != null && selected == 'clock';
    if (on && _ticker == null) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    } else if (!on) {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  void _tick() {
    final m = _epoch ~/ 60;
    if (m == _shownMinute) return;
    _shownMinute = m;
    notifyListeners();
  }

  /// Run [f]; on success refresh. The View shows the done / error message.
  Future<Result<void>> _act(Future<Result<void>> Function() f) async {
    final r = await f();
    if (r is Ok) await _device.refresh();
    return r;
  }

  Future<Result<void>> clearProjects() => _act(_device.clearProjects);
  Future<Result<void>> clearCard(String id) => _act(() => _device.clearCard(id));
  Future<Result<void>> clearAllCards() => _act(_device.clearAllCards);
  Future<Result<void>> refreshNow() => _act(_device.refreshNow);

  /// ShowOnDeviceButton: bring the selected tab's channel up on the device.
  Future<Result<void>> showOnDevice() => _act(() => _device.showChannel(showChannelOf[selected] ?? 'Claude'));

  @override
  void dispose() {
    _ticker?.cancel();
    _device.removeListener(_update);
    super.dispose();
  }
}
