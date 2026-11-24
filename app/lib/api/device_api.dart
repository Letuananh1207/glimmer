import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'models.dart';

/// Thrown for HTTP errors; [status] 0 = no answer (timeout / unreachable).
class DeviceException implements Exception {
  final int status;
  final String message;
  DeviceException(this.status, this.message);
  bool get unauthorized => status == 401;
  @override
  String toString() => message;
}

/// HTTP client for one glimmer display.
///
/// The ESP8266 is single-threaded: while it runs a TLS fetch (a few seconds)
/// its web server doesn't answer, so reads retry once with a 6 s timeout.
class DeviceApi {
  DeviceApi(String baseUrl, {this.token = ''})
      : baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), '');

  final String baseUrl;
  final String token;

  static const setupApUrl = 'http://192.168.4.1';
  static const setupApSsid = 'glimmer-setup';

  final HttpClient _client = HttpClient()..connectionTimeout = const Duration(seconds: 6);

  void close() => _client.close(force: true);

  Future<Map<String, dynamic>> _json(String method, String path,
      {Object? body, Duration timeout = const Duration(seconds: 6), int tries = 2}) async {
    Object? last;
    for (var i = 0; i < tries; i++) {
      try {
        final req = await _client.openUrl(method, Uri.parse('$baseUrl$path')).timeout(timeout);
        if (token.isNotEmpty) req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
        if (body != null) {
          final bytes = utf8.encode(jsonEncode(body));
          req.headers.contentType = ContentType.json;
          req.contentLength = bytes.length;
          req.add(bytes);
        }
        final res = await req.close().timeout(timeout);
        final text = await res.transform(utf8.decoder).join().timeout(timeout);
        if (res.statusCode == 401) throw DeviceException(401, 'Thiết bị yêu cầu API token.');
        if (res.statusCode >= 400) throw DeviceException(res.statusCode, 'Lỗi HTTP ${res.statusCode}');
        if (text.trim().isEmpty) return {};
        final decoded = jsonDecode(text);
        return decoded is Map<String, dynamic> ? decoded : {'value': decoded};
      } on DeviceException {
        rethrow;
      } catch (e) {
        last = e;
      }
    }
    throw DeviceException(0, 'Không kết nối được thiết bị ($last)');
  }

  // ── reads ──
  Future<DeviceState> state() async => DeviceState.fromJson(await _json('GET', '/api/state'));
  Future<Map<String, dynamic>> settings() => _json('GET', '/api/settings');
  Future<Map<String, dynamic>> exportConfig() => _json('GET', '/api/export');

  Future<List<Card>> cards() async {
    final j = await _json('GET', '/push');
    return (j['cards'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(Card.fromJson)
        .toList();
  }

  /// Cheap reachability check (one try).
  Future<DeviceState?> probe({Duration timeout = const Duration(seconds: 4)}) async {
    try {
      return DeviceState.fromJson(await _json('GET', '/api/state', timeout: timeout, tries: 1));
    } catch (_) {
      return null;
    }
  }

  // ── writes ──
  /// Partial settings update (camelCase keys). [restart] reboots the device.
  Future<void> saveSettings(Map<String, dynamic> changes, {bool restart = false}) =>
      _json('POST', '/api/settings', body: {...changes, if (restart) '_restart': true}, tries: 1);

  /// Replace config.json (a backup from [exportConfig]); the device restarts.
  Future<void> importConfig(Map<String, dynamic> config) =>
      _json('POST', '/api/import', body: config, tries: 1, timeout: const Duration(seconds: 10));

  Future<void> reboot() => _json('POST', '/api/reboot', tries: 1).catchError((_) => <String, dynamic>{});
  Future<void> refreshNow() => _json('POST', '/api/refresh', tries: 1);
  Future<void> showChannel(String name) => _json('POST', '/api/channel', body: {'name': name}, tries: 1);
  Future<void> clearCard(String id) => _json('POST', '/push/clear', body: {'id': id}, tries: 1);
  Future<void> clearAllCards() => _json('POST', '/push/clear', body: {'all': true}, tries: 1);
  Future<void> clearProjects() => _json('POST', '/push/clear', body: {'projects': true}, tries: 1);

  /// OTA upload to POST /update. [field] is "firmware" or "filesystem"
  /// (ESP8266HTTPUpdateServer). The device reboots when it is done.
  Future<void> upload(String field, Uint8List image, {void Function(double)? onProgress}) async {
    const boundary = '----glimmer-app-boundary';
    final head = utf8.encode('--$boundary\r\n'
        'Content-Disposition: form-data; name="$field"; filename="$field.bin"\r\n'
        'Content-Type: application/octet-stream\r\n\r\n');
    final tail = utf8.encode('\r\n--$boundary--\r\n');
    final req = await _client.postUrl(Uri.parse('$baseUrl/update'));
    req.headers.set(HttpHeaders.contentTypeHeader, 'multipart/form-data; boundary=$boundary');
    req.contentLength = head.length + image.length + tail.length;
    req.add(head);
    const chunk = 4096;
    for (var o = 0; o < image.length; o += chunk) {
      req.add(image.sublist(o, o + chunk > image.length ? image.length : o + chunk));
      await req.flush();
      onProgress?.call((o + chunk).clamp(0, image.length) / image.length);
    }
    req.add(tail);
    final res = await req.close().timeout(const Duration(seconds: 120));
    final text = await res.transform(utf8.decoder).join();
    if (res.statusCode != 200 || !text.contains('Success')) {
      throw DeviceException(res.statusCode, 'Nạp thất bại: ${text.trim()}');
    }
  }

  /// Wait until the device answers again (after a reboot).
  Future<DeviceState?> waitOnline({Duration max = const Duration(minutes: 3)}) async {
    final end = DateTime.now().add(max);
    await Future<void>.delayed(const Duration(seconds: 8));
    while (DateTime.now().isBefore(end)) {
      final s = await probe();
      if (s != null) return s;
      await Future<void>.delayed(const Duration(seconds: 3));
    }
    return null;
  }
}
