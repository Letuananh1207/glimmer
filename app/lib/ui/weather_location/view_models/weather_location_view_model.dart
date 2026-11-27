import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/repositories/device/device_repository.dart';
import '../../../data/repositories/location/location_repository.dart';
import '../../../domain/models/weather_location.dart';
import '../../../domain/rules/weather_location_rules.dart' as rules;
import '../../../utils/result.dart';
import '../../../utils/safe_notifier.dart';

/// The GPS button's situation (screen_specs §9 `gpsLoading`, `gpsDenied`, `gpsOff`, `gpsFail`).
enum GpsState { idle, loading, denied, deniedForever, off, failed }

/// The city search under the field (`searching`, `results`, `noResults`, `searchError`).
enum SearchState { idle, searching, results, none, error }

/// Vị trí thời tiết (screen_specs §9, design 2026-11-26.9): the device's weather location, set from the phone.
/// R-VT-1 GPS only when pressed; R-VT-2 search 400 ms after the last key, from 2 characters; R-VT-3 name ≤ 16;
/// R-VT-4 old firmware takes coordinates only; R-VT-5 clear = 0, 0, ""; a refused send keeps the device's location.
class WeatherLocationViewModel extends ChangeNotifier with SafeNotifier {
  WeatherLocationViewModel({
    required DeviceRepository device,
    required LocationRepository location,
    this.doneFor = const Duration(seconds: 3),
  }) : _device = device,
       _location = location {
    unawaited(load());
  }

  final DeviceRepository _device;
  final LocationRepository _location;

  /// How long the "Đã đặt …" note stays.
  final Duration doneFor;

  Map<String, dynamic>? _settings;
  bool _loading = true;
  GpsState _gps = GpsState.idle;
  String _query = '';
  SearchState _search = SearchState.idle;
  List<PlaceResult> _results = const [];
  Timer? _debounce, _doneTimer;
  int _searchSeq = 0;
  bool _sending = false, _sendFailed = false;
  String? _done;

  bool get loading => _loading;

  /// What the device uses now.
  WeatherLocation get current => rules.locationOf(_settings);

  /// R-VT-4: the firmware shows a place name.
  bool get placeSupported => rules.placeSupported(_settings);

  GpsState get gps => _gps;
  String get query => _query;
  SearchState get search => _search;
  List<PlaceResult> get results => _results;
  bool get sending => _sending;
  bool get sendFailed => _sendFailed;

  /// The place just set ("Đã đặt Đà Nẵng cho thiết bị."), null = no note.
  String? get done => _done;

  /// The device's weather now and its time zone (the confirm sheet's preview).
  String get weatherDesc => _device.state?.weather?.desc ?? '';
  int get tzMinutes => (_settings?['tzMinutes'] as num?)?.toInt() ?? 0;

  /// Read the device's settings (location + whether it shows a name).
  Future<void> load() async {
    final r = await _device.settings();
    if (r is Ok<Map<String, dynamic>>) _settings = r.value;
    _loading = false;
    notifyListeners();
  }

  // ── GPS (R-VT-1) ──

  /// "Dùng vị trí hiện tại": asks the permission (system dialog) and the position now; the place for the confirm sheet,
  /// or null with [gps] saying why not.
  Future<PlaceResult?> useGps() async {
    if (_gps == GpsState.loading) return null;
    _gps = GpsState.loading;
    notifyListeners();
    final o = await _location.currentPlace();
    _gps = switch (o.failure) {
      null => GpsState.idle,
      GpsFailure.denied => GpsState.denied,
      GpsFailure.deniedForever => GpsState.deniedForever,
      GpsFailure.off => GpsState.off,
      GpsFailure.failed => GpsState.failed,
    };
    notifyListeners();
    return o.fix;
  }

  Future<void> openAppSettings() => _location.openAppSettings();
  Future<void> openLocationSettings() => _location.openLocationSettings();

  // ── Search (R-VT-2) ──

  /// The field changed: search [searchDelay] after the last key, from 2 characters.
  void setQuery(String q) {
    _query = q;
    _debounce?.cancel();
    if (!rules.shouldSearch(q)) {
      _searchSeq++;
      _search = SearchState.idle;
      _results = const [];
      notifyListeners();
      return;
    }
    _search = SearchState.searching;
    notifyListeners();
    _debounce = Timer(rules.searchDelay, () => unawaited(_runSearch()));
  }

  /// "Thử lại" after a failed search.
  Future<void> retrySearch() => _runSearch();

  Future<void> _runSearch() async {
    if (!rules.shouldSearch(_query)) return;
    final seq = ++_searchSeq;
    _search = SearchState.searching;
    notifyListeners();
    final r = await _location.search(_query.trim());
    if (seq != _searchSeq) return; // a newer search went out
    switch (r) {
      case Ok(:final value):
        _results = value;
        _search = value.isEmpty ? SearchState.none : SearchState.results;
      case Error():
        _results = const [];
        _search = SearchState.error;
    }
    notifyListeners();
  }

  // ── Sending (R-VT-3…5) ──

  /// Set [p] named [name] on the device (old firmware: coordinates only). True when the device took it; false keeps
  /// the device's location and shows the sheet's "Thiết bị không nhận".
  Future<bool> apply(PlaceResult p, String name) => _send(
    rules.applyBody(p, name, place: placeSupported),
    placeSupported ? rules.deviceName(name) : rules.coord(p.lat),
  );

  /// "Sửa tên": only the name.
  Future<bool> rename(String name) => _send(rules.renameBody(name), rules.deviceName(name));

  /// R-VT-5: "Xoá vị trí" (asked first by the screen).
  Future<bool> clear() => _send(rules.clearBody(place: placeSupported), null);

  Future<bool> _send(Map<String, Object> body, String? place) async {
    if (_sending) return false;
    _sending = true;
    _sendFailed = false;
    notifyListeners();
    final r = await _device.saveSettings(body);
    _sending = false;
    final ok = r is Ok<void>;
    if (ok) {
      _settings = {...?_settings, ...body};
      if (place != null) _showDone(place);
    } else {
      _sendFailed = true;
    }
    notifyListeners();
    return ok;
  }

  /// The sheet closed: forget its failure.
  void sheetClosed() {
    _sendFailed = false;
    notifyListeners();
  }

  void _showDone(String place) {
    _done = place;
    _doneTimer?.cancel();
    _doneTimer = Timer(doneFor, () {
      _done = null;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _doneTimer?.cancel();
    super.dispose();
  }
}
