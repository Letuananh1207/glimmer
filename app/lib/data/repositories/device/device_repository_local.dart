import 'dart:async';
import 'dart:typed_data';

import '../../../domain/models/app_error.dart';
import '../../../domain/models/attention_card.dart';
import '../../../domain/models/device_state.dart';
import '../../../utils/result.dart';
import '../../services/device_api_service.dart';
import '../../services/discovery_service.dart';
import '../../services/local_store_service.dart';
import '../../services/wifi_service.dart';
import 'device_repository.dart';

typedef Delay = Future<void> Function(Duration);

Future<void> _realDelay(Duration d) => Future<void>.delayed(d);

class DeviceRepositoryLocal extends DeviceRepository {
  DeviceRepositoryLocal({
    required DeviceApiService api,
    required DiscoveryService discovery,
    required LocalStoreService store,
    required WifiService wifi,
    Delay delay = _realDelay,
    Duration pollEvery = const Duration(seconds: 5),
  })  : _api = api,
        _discovery = discovery,
        _store = store,
        _wifi = wifi,
        _delay = delay,
        _pollEvery = pollEvery;

  final DeviceApiService _api;
  final DiscoveryService _discovery;
  final LocalStoreService _store;
  final WifiService _wifi;
  final Delay _delay;
  final Duration _pollEvery;

  String _url = '';
  DeviceState? _state;
  List<AttentionCard> _cards = const [];
  AppError? _error;
  bool _cardsNeedToken = false;
  bool _searching = false;
  Timer? _poll;

  @override
  bool get connected => _url.isNotEmpty;
  @override
  String get url => _url;
  @override
  DeviceState? get state => _state;
  @override
  List<AttentionCard> get cards => _cards;
  @override
  AppError? get error => _error;
  @override
  bool get cardsNeedToken => _cardsNeedToken;
  @override
  bool get searching => _searching;
  @override
  String get savedUrl => _store.deviceUrl;
  @override
  String get token => _store.token;
  @override
  String get repo => _store.repo;

  static AppError _map(Object e) {
    if (e is AppError) return e;
    if (e is DeviceHttpException) {
      if (e.status == 401) return const AppError(AppErrorKind.unauthorized, status: 401);
      if (e.status == 0) return AppError(AppErrorKind.unreachable, detail: e.detail);
      if (e.detail.isNotEmpty) return AppError(AppErrorKind.flashFailed, status: e.status, detail: e.detail);
      return AppError(AppErrorKind.http, status: e.status);
    }
    return AppError.from(e);
  }

  Future<Result<T>> _call<T>(Future<T> Function() f) async {
    try {
      return Result.ok(await f());
    } catch (e) {
      return Result.error(_map(e));
    }
  }

  Future<Map<String, dynamic>> _json(String method, String path,
          {Object? body, String? at, Duration timeout = const Duration(seconds: 6), int tries = 2}) =>
      _api.json(at ?? _url, method, path, token: _store.token, body: body, timeout: timeout, tries: tries);

  Future<DeviceState?> _probe(String url, {Duration timeout = const Duration(seconds: 4)}) async {
    try {
      return DeviceState.fromJson(
          await _api.json(url, 'GET', '/api/state', token: _store.token, timeout: timeout, tries: 1));
    } catch (_) {
      return null;
    }
  }

  // ── connection ──
  @override
  Future<bool> discover() async {
    _searching = true;
    _error = null;
    notifyListeners();
    final tried = <String>{};
    Future<(String, DeviceState)?> tryUrl(String url) async {
      if (url.isEmpty || !tried.add(url)) return null;
      final s = await _probe(url);
      return s == null ? null : (url, s);
    }

    var hit = await tryUrl(_store.deviceUrl);
    if (hit == null) {
      for (final ip in await _discovery.nsdAddresses()) {
        hit = await tryUrl('http://$ip');
        if (hit != null) break;
      }
    }
    hit ??= await tryUrl('http://glimmer.local');
    hit ??= await tryUrl(DeviceRepository.setupApUrl);
    _searching = false;
    if (hit == null) {
      _error = const AppError(AppErrorKind.notFound);
      notifyListeners();
      return false;
    }
    _use(hit.$1, hit.$2);
    return true;
  }

  @override
  Future<bool> connectTo(String address, {String? token}) async {
    var url = address.trim();
    if (url.isEmpty) return false;
    if (!url.startsWith('http')) url = 'http://$url';
    if (token != null) _store.token = token.trim();
    _searching = true;
    _error = null;
    notifyListeners();
    final s = await _probe(url, timeout: const Duration(seconds: 6));
    _searching = false;
    if (s == null) {
      _error = AppError(AppErrorKind.noDeviceAt, detail: url);
      notifyListeners();
      return false;
    }
    _use(url, s);
    return true;
  }

  @override
  Future<bool> rediscover({
    Duration first = const Duration(seconds: 15),
    required int attempts,
    required Duration gap,
    bool keep = false,
  }) async {
    final keptUrl = _url, keptState = _state;
    if (keep) {
      stopPolling();
    } else {
      forget();
    }
    await _delay(first);
    for (var i = 0; i < attempts; i++) {
      if (i > 0) await _delay(gap);
      if (await discover()) return true;
    }
    if (keep && keptUrl.isNotEmpty) _use(keptUrl, keptState!);
    return false;
  }

  void _use(String url, DeviceState s) {
    _url = url;
    _state = s;
    if (url != DeviceRepository.setupApUrl) _store.deviceUrl = url;
    notifyListeners();
    startPolling();
    refresh();
  }

  @override
  void forget() {
    stopPolling();
    _url = '';
    _state = null;
    _cards = const [];
    _cardsNeedToken = false;
    notifyListeners();
  }

  @override
  void setToken(String token) {
    _store.token = token.trim();
    if (connected) _use(_url, _state!);
  }

  @override
  Future<void> refresh() async {
    if (!connected) return;
    final at = _url;
    try {
      final s = DeviceState.fromJson(await _json('GET', '/api/state', at: at));
      if (_url != at) return; // switched device meanwhile
      _state = s;
      _error = null;
      try {
        final j = await _json('GET', '/push', at: at);
        _cards = List.unmodifiable((j['cards'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(AttentionCard.fromJson));
        _cardsNeedToken = false;
      } on DeviceHttpException catch (e) {
        if (e.status != 401) rethrow;
        _cards = const [];
        _cardsNeedToken = true;
      }
    } catch (e) {
      if (_url != at) return;
      _error = _map(e);
    }
    notifyListeners();
  }

  @override
  void startPolling() {
    _poll?.cancel();
    if (connected) _poll = Timer.periodic(_pollEvery, (_) => refresh());
  }

  @override
  void stopPolling() {
    _poll?.cancel();
    _poll = null;
  }

  @override
  Future<bool> reachable() async => connected && await _probe(_url) != null;

  // ── calls ──
  @override
  Future<Result<Map<String, dynamic>>> settings() => _call(() => _json('GET', '/api/settings'));

  Future<Result<void>> _restarting(Future<void> Function() f) async {
    try {
      await f();
    } on DeviceHttpException catch (e) {
      if (e.status != 0) return Result.error(_map(e)); // 0: it rebooted before answering — fine
    } catch (e) {
      return Result.error(_map(e));
    }
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> saveSettings(Map<String, dynamic> changes, {bool restart = false, String? at}) {
    Future<void> send() => _json('POST', '/api/settings',
        at: at, body: {...changes, if (restart) '_restart': true}, tries: 1);
    return restart ? _restarting(send) : _call(send);
  }

  @override
  Future<Result<Map<String, dynamic>>> exportConfig() => _call(() => _json('GET', '/api/export'));

  @override
  Future<Result<void>> importConfig(Map<String, dynamic> config, {String? at}) => _restarting(
      () => _json('POST', '/api/import', at: at, body: config, tries: 1, timeout: const Duration(seconds: 10)));

  @override
  Future<Result<void>> reboot() => _restarting(() => _json('POST', '/api/reboot', tries: 1));

  @override
  Future<Result<void>> refreshNow() => _call(() => _json('POST', '/api/refresh', tries: 1));

  @override
  Future<Result<void>> showChannel(String name) =>
      _call(() => _json('POST', '/api/channel', body: {'name': name}, tries: 1));

  @override
  Future<Result<void>> clearCard(String id) =>
      _call(() => _json('POST', '/push/clear', body: {'id': id}, tries: 1));

  @override
  Future<Result<void>> clearAllCards() =>
      _call(() => _json('POST', '/push/clear', body: {'all': true}, tries: 1));

  @override
  Future<Result<void>> clearProjects() =>
      _call(() => _json('POST', '/push/clear', body: {'projects': true}, tries: 1));

  @override
  Future<Result<void>> upload(String field, Uint8List image, {void Function(double)? onProgress}) =>
      _call(() => _api.upload(_url, field, image, onProgress: onProgress));

  @override
  Future<DeviceState?> waitOnline({Duration max = const Duration(minutes: 3)}) async {
    final end = DateTime.now().add(max);
    await _delay(const Duration(seconds: 8));
    while (DateTime.now().isBefore(end)) {
      final s = await _probe(_url);
      if (s != null) return s;
      await _delay(const Duration(seconds: 3));
    }
    return null;
  }

  // ── phone Wi-Fi ──
  @override
  Future<bool> ensureWifiPermissions() => _wifi.ensurePermissions();

  @override
  Future<String?> phoneSsid() => _wifi.currentSsid();

  @override
  Future<bool> joinSetupAp({int attempts = 3}) async {
    for (var i = 0; i < attempts; i++) {
      if (await _wifi.joinOpen(DeviceRepository.setupApSsid)) {
        for (var j = 0; j < 5; j++) {
          if (await _probe(DeviceRepository.setupApUrl) != null) return true;
          await _delay(const Duration(seconds: 2));
        }
      }
      await _delay(const Duration(seconds: 5));
    }
    return false;
  }

  @override
  Future<void> leaveSetupAp() => _wifi.leave();

  bool _disposed = false;

  // A refresh started before dispose() may finish after it.
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    stopPolling();
    _api.close();
    super.dispose();
  }
}
