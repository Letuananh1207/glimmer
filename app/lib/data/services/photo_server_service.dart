import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

/// One photo to serve: its id, place in the library (headers X-Photo-Id / -Index / -Count) and JPEG.
typedef ServedJpeg = ({int id, int index, int count, Uint8List jpeg});

/// The photo library on the home network (R-AK-4; firmware src/data/photo_source_core.h): plain HTTP, only
/// `GET /p/<key>/next?after=<id>` → 200 JPEG + headers, 204 when the library is empty; anything else 404.
class PhotoServerService {
  HttpServer? _server;
  String _key = '';
  Future<ServedJpeg?> Function(int after)? _next;

  bool get running => _server != null;

  /// The port served on (0 = not running).
  int get port => _server?.port ?? 0;

  /// Serve on [port] (any free port when it is taken). [next] answers "the photo after id".
  Future<int> start({
    required int port,
    required String key,
    required Future<ServedJpeg?> Function(int after) next,
  }) async {
    _key = key;
    _next = next;
    if (_server != null) return _server!.port;
    HttpServer s;
    try {
      s = await HttpServer.bind(InternetAddress.anyIPv4, port);
    } on SocketException {
      s = await HttpServer.bind(InternetAddress.anyIPv4, 0);
    }
    _server = s;
    s.listen(_handle, onError: (_) {});
    return s.port;
  }

  Future<void> stop() async {
    final s = _server;
    _server = null;
    await s?.close(force: true);
  }

  Future<void> _handle(HttpRequest req) async {
    final res = req.response;
    try {
      final seg = req.uri.pathSegments;
      final next = _next;
      if (req.method != 'GET' ||
          seg.length != 3 ||
          seg[0] != 'p' ||
          seg[1] != _key ||
          seg[2] != 'next' ||
          next == null) {
        res.statusCode = HttpStatus.notFound;
        return;
      }
      final after = int.tryParse(req.uri.queryParameters['after'] ?? '0') ?? 0;
      final p = await next(after);
      if (p == null) {
        res.statusCode = HttpStatus.noContent;
        return;
      }
      res.statusCode = HttpStatus.ok;
      res.headers
        ..contentType = ContentType('image', 'jpeg')
        ..contentLength = p.jpeg.length
        ..set('X-Photo-Id', '${p.id}')
        ..set('X-Photo-Index', '${p.index}')
        ..set('X-Photo-Count', '${p.count}');
      res.add(p.jpeg);
    } on Exception {
      res.statusCode = HttpStatus.internalServerError;
    } finally {
      await res.close();
    }
  }
}
