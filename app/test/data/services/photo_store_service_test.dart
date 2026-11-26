import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/data/services/photo_store_service.dart';

void main() {
  test('write / read / list / delete under <root>/photos', () async {
    final root = await Directory.systemTemp.createTemp('glimmer-photos');
    addTearDown(() => root.delete(recursive: true));
    final s = PhotoStoreService(root: root);
    expect(await s.list(), isEmpty);
    await s.write('p1.jpg', Uint8List.fromList([1, 2, 3]));
    expect(await s.list(), ['p1.jpg']);
    expect(await s.read('p1.jpg'), [1, 2, 3]);
    expect(File('${root.path}/photos/p1.jpg').existsSync(), isTrue);
    await s.delete('p1.jpg');
    await s.delete('p1.jpg');
    expect(await s.read('p1.jpg'), isNull);
  });
}
