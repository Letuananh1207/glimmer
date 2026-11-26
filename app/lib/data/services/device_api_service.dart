import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../../utils/cancel_token.dart';

/// HTTP error from the display; [status] 0 = no answer (timeout / unreachable).
class DeviceHttpException implements Exception {
  const DeviceHttpException(this.status, [this.detail = '']);
  final int status;
  final String detail;

  @override
  String toString() => 'DeviceHttpException($status, $detail)';
}

/// HTTP to a glimmer display (any address — the service keeps no state but its socket pool).
///
/// The ESP8266 is single-threaded: while it runs a TLS fetch (a few seconds) its web server doesn't
/// answer, so reads retry once with a 6 s timeout.
class DeviceApiService {
  DeviceApiService() : _client = HttpClient()..connectionTimeout = const Duration(seconds: 6);

  final HttpClient _client;

  void close() => _client.close(force: true);

  /// JSON request; returns the decoded object (a non-object answer is wrapped as `{'value': …}`).
  Future<Map<String, dynamic>> json(
    String baseUrl,
    String method,
    String path, {
    String token = '',
    Object? body,
    Duration timeout = const Duration(seconds: 6),
    int tries = 2,
  }) async {
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
        if (res.statusCode >= 400) throw DeviceHttpException(res.statusCode);
        if (text.trim().isEmpty) return {};
        final decoded = jsonDecode(text);
        return decoded is Map<String, dynamic> ? decoded : {'value': decoded};
      } on DeviceHttpException {
        rethrow;
      } catch (e) {
        last = e;
      }
    }
    throw DeviceHttpException(0, '${last.runtimeType}');
  }

  /// Multipart upload of one file to [path] (e.g. POST /api/photos, field "photo"); returns the JSON answer.
  /// An HTTP error throws [DeviceHttpException] with the answer body as `detail` (the device's `{"error": …}`);
  /// [cancel] aborts the request (status -1). [onProgress] gets the share of bytes written, 0…1.
  Future<Map<String, dynamic>> uploadFile(
    String baseUrl,
    String path, {
    required String field,
    required String filename,
    required String contentType,
    required Uint8List bytes,
    String token = '',
    void Function(double)? onProgress,
    CancelToken? cancel,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    const boundary = '----glimmer-app-boundary';
    final head = utf8.encode('--$boundary\r\n'
        'Content-Disposition: form-data; name="$field"; filename="$filename"\r\n'
        'Content-Type: $contentType\r\n\r\n');
    final tail = utf8.encode('\r\n--$boundary--\r\n');
    HttpClientRequest? req;
    cancel?.onCancel = () => req?.abort(const DeviceHttpException(-1, 'cancelled'));
    try {
      if (cancel?.cancelled ?? false) throw const DeviceHttpException(-1, 'cancelled');
      req = await _client.postUrl(Uri.parse('$baseUrl$path')).timeout(timeout);
      if (token.isNotEmpty) req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      req.headers.set(HttpHeaders.contentTypeHeader, 'multipart/form-data; boundary=$boundary');
      req.contentLength = head.length + bytes.length + tail.length;
      req.add(head);
      const chunk = 2048;
      for (var o = 0; o < bytes.length; o += chunk) {
        if (cancel?.cancelled ?? false) throw const DeviceHttpException(-1, 'cancelled');
        final end = o + chunk > bytes.length ? bytes.length : o + chunk;
        req.add(bytes.sublist(o, end));
        await req.flush().timeout(timeout);
        onProgress?.call(end / bytes.length);
      }
      req.add(tail);
      final res = await req.close().timeout(timeout);
      final text = await res.transform(utf8.decoder).join().timeout(timeout);
      if (res.statusCode >= 400) throw DeviceHttpException(res.statusCode, text.trim());
      if (text.trim().isEmpty) return {};
      final decoded = jsonDecode(text);
      return decoded is Map<String, dynamic> ? decoded : {'value': decoded};
    } on DeviceHttpException {
      rethrow;
    } catch (e) {
      if (cancel?.cancelled ?? false) throw const DeviceHttpException(-1, 'cancelled');
      throw DeviceHttpException(0, '${e.runtimeType}');
    } finally {
      cancel?.onCancel = null;
    }
  }

  /// OTA upload to POST /update. [field] is "firmware" or "filesystem" (ESP8266HTTPUpdateServer).
  /// The device reboots when it is done.
  Future<void> upload(String baseUrl, String field, Uint8List image, {void Function(double)? onProgress}) async {
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
      throw DeviceHttpException(res.statusCode, text.trim());
    }
  }
}
