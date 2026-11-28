import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/domain/models/library_photo.dart';
import 'package:glimmer_app/domain/rules/library_rules.dart';

LibraryPhoto _p(int id, {String? cached}) => LibraryPhoto(
  id: id,
  added: DateTime(2026, 11, 27).add(Duration(minutes: id)),
  size: 1000,
  cachedAs: cached,
);

void main() {
  test('R-AK-2 the photo after X: in order, wraps, a deleted X goes on from the next bigger id', () {
    final lib = libraryOrder([_p(9), _p(3), _p(5)]);
    expect(lib.map((p) => p.id), [3, 5, 9]);
    final a = nextAfter(lib, 0)!;
    expect((a.photo.id, a.index, a.count), (3, 1, 3));
    final b = nextAfter(lib, 5)!;
    expect((b.photo.id, b.index, b.count), (9, 3, 3));
    expect(nextAfter(lib, 9)!.photo.id, 3);
    expect(nextAfter(lib, 4)!.photo.id, 5, reason: '4 was deleted: the next bigger');
    expect(nextAfter(lib, 99)!.photo.id, 3);
    expect(nextAfter(const [], 0), isNull);
  });

  test('R-AK-3 the cache = the 8 newest; library photos that left are deleted, the newest missing uploaded', () {
    final lib = [for (var i = 1; i <= 10; i++) _p(i, cached: i <= 8 ? 'p$i.jpg' : null)];
    expect(cacheIds(lib), {3, 4, 5, 6, 7, 8, 9, 10});
    final plan = cachePlan(lib, [for (var i = 1; i <= 8; i++) 'p$i.jpg']);
    expect(plan.delete, ['p1.jpg', 'p2.jpg']);
    expect(plan.upload.map((p) => p.id), [10, 9], reason: 'newest first');
  });

  test('R-AK-3 a device photo the library did not send is never deleted; a lost copy is uploaded again', () {
    final lib = [_p(1, cached: 'p1.jpg'), _p(2, cached: 'p2.jpg')];
    final plan = cachePlan(lib, ['p2.jpg', 'p7.jpg']);
    expect(plan.delete, isEmpty, reason: 'p7 is not from the library');
    expect(plan.upload.map((p) => p.id), [1], reason: 'p1 is gone from the device');
    expect(cachePlan(lib, ['p1.jpg', 'p2.jpg']).isEmpty, isTrue);
  });

  test('R-AK-4 the phone address on the device network; a key of letters / digits', () {
    expect(phoneHostFor('192.168.1.50', ['10.0.0.4', '192.168.1.20']), '192.168.1.20');
    expect(phoneHostFor('192.168.1.50', ['100.64.0.2', '10.0.0.4']), '10.0.0.4', reason: 'a private one otherwise');
    expect(phoneHostFor('192.168.1.50', ['fe80::1', '100.64.0.2']), isNull);
    final k = newServeKey(Random(1));
    expect(k, matches(RegExp(r'^[A-Za-z0-9]{16}$')));
    expect(newServeKey(Random(2)), isNot(k));
    expect(sourceBody('192.168.1.20', 8787, k), {'host': '192.168.1.20', 'port': 8787, 'key': k});
  });
}
