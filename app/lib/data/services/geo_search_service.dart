import 'dart:convert';
import 'dart:io';

/// Open-Meteo geocoding answered [status] (0 = network error).
class GeoSearchException implements Exception {
  const GeoSearchException(this.status);
  final int status;

  @override
  String toString() => 'GeoSearchException($status)';
}

/// Open-Meteo geocoding search (the same service the device's web page uses): city names → coordinates.
class GeoSearchService {
  /// `GET /v1/search?name=…&count=10&language=vi` → the raw `results` (empty when nothing matched).
  Future<List<Map<String, dynamic>>> search(String name) async {
    final c = HttpClient()..userAgent = 'glimmer-app';
    try {
      final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
        'name': name,
        'count': '10',
        'language': 'vi',
        'format': 'json',
      });
      final res = await (await c.getUrl(uri)).close().timeout(const Duration(seconds: 10));
      final text = await res.transform(utf8.decoder).join();
      if (res.statusCode != 200) throw GeoSearchException(res.statusCode);
      final j = jsonDecode(text);
      final r = j is Map<String, dynamic> ? j['results'] : null;
      return r is List ? r.whereType<Map<String, dynamic>>().toList() : const [];
    } on SocketException {
      throw const GeoSearchException(0);
    } finally {
      c.close(force: true);
    }
  }
}
