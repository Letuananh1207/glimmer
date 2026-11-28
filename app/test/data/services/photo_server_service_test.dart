import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/data/services/photo_server_service.dart';

void main() {
  late PhotoServerService server;
  late HttpClient client;
  final jpeg = Uint8List.fromList([0xFF, 0xD8, 1, 2, 3, 0xFF, 0xD9]);

  setUp(() {
    server = PhotoServerService();
    client = HttpClient();
  });
  tearDown(() async {
    client.close(force: true);
    await server.stop();
  });

  Future<HttpClientResponse> get(String path) async =>
      (await client.getUrl(Uri.parse('http://127.0.0.1:${server.port}$path'))).close();

  test('R-AK-2 R-AK-4 next?after= → the JPEG + X-Photo-Id / -Index / -Count; empty → 204; wrong key → 404', () async {
    var empty = false;
    final asked = <int>[];
    await server.start(
      port: 0,
      key: 'Ab3dEfGh9kLm2nPq',
      next: (after) async {
        asked.add(after);
        return empty ? null : (id: 5, index: 2, count: 3, jpeg: jpeg);
      },
    );
    expect(server.running, isTrue);
    final r = await get('/p/Ab3dEfGh9kLm2nPq/next?after=3');
    expect(r.statusCode, 200);
    expect(r.headers.contentType?.mimeType, 'image/jpeg');
    expect(
      (r.headers.value('X-Photo-Id'), r.headers.value('X-Photo-Index'), r.headers.value('X-Photo-Count')),
      ('5', '2', '3'),
    );
    expect(await r.fold<List<int>>([], (a, b) => a..addAll(b)), jpeg);
    expect(asked, [3]);

    empty = true;
    expect((await get('/p/Ab3dEfGh9kLm2nPq/next?after=0')).statusCode, 204);
    expect((await get('/p/wrongwrongwrong1/next?after=0')).statusCode, 404);
    expect((await get('/p/Ab3dEfGh9kLm2nPq/5.jpg')).statusCode, 404);
    expect(asked, [3, 0]);
  });

  test('R-AK-4 the port is taken → another one; stop frees it', () async {
    final busy = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
    final port = await server.start(port: busy.port, key: 'Ab3dEfGh9kLm2nPq', next: (_) async => null);
    expect(port, isNot(busy.port));
    await busy.close();
    await server.stop();
    expect(server.running, isFalse);
    expect(server.port, 0);
  });
}
