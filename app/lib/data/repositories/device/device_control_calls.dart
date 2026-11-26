part of 'device_repository_local.dart';

/// The remote's calls (tab Điều khiển, design 2026-11-26.5): one try each, no automatic retry (R-DK-1); a good
/// answer patches [DeviceRepository.state] at once so the screen mirror follows the device before the next poll.
mixin _ControlCalls on DeviceRepository {
  abstract DeviceState? _state;

  Future<Result<T>> _call<T>(Future<T> Function() f);

  Future<Map<String, dynamic>> _json(String method, String path, {Object? body, int tries});

  @override
  Future<Result<ChannelAnswer>> channel({String? name, String? action}) => _call(() async {
    final a = ChannelAnswer.fromJson(
      await _json(
        'POST',
        '/api/channel',
        body: {if (action != null) 'action': action else 'name': name ?? ''},
        tries: 1,
      ),
    );
    final s = _state;
    if (s != null && a.active.isNotEmpty) {
      _state = s.withControl(activeChannel: a.active, paused: a.paused);
      notifyListeners();
    }
    return a;
  });

  @override
  Future<Result<void>> setWindows(Map<String, Object?> body) =>
      _call(() async => _json('POST', '/api/windows', body: body, tries: 1));

  @override
  Future<Result<void>> setMenu(Map<String, Object?> body) =>
      _call(() async => _json('POST', '/api/menu', body: body, tries: 1));

  @override
  Future<Result<bool>> setScreen(bool on) => _call(() async {
    final j = await _json('POST', '/api/screen', body: {'on': on}, tries: 1);
    final shown = j['screen_on'] is bool ? j['screen_on'] as bool : on;
    final s = _state;
    if (s != null) {
      _state = s.withControl(screenOn: shown);
      notifyListeners();
    }
    return shown;
  });

  @override
  Future<Result<bool>> setBalloon(bool show) => _call(() async {
    final j = await _json('POST', '/api/balloon', body: {'show': show}, tries: 1);
    final up = j['balloon'] is bool ? j['balloon'] as bool : show;
    final s = _state;
    if (s != null) {
      _state = s.withControl(balloon: up);
      notifyListeners();
    }
    return up;
  });
}
