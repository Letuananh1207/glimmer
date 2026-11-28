import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/data/repositories/photo/photo_library_repository_local.dart';
import 'package:glimmer_app/data/repositories/photo/photo_repository_local.dart';
import 'package:glimmer_app/data/repositories/photo/photo_server_repository_local.dart';
import 'package:glimmer_app/data/services/photo_library_service.dart';
import 'package:glimmer_app/data/services/photo_server_service.dart';
import 'package:glimmer_app/domain/models/device_photo.dart';
import 'package:glimmer_app/domain/models/library_photo.dart';
import 'package:glimmer_app/domain/use_cases/delete_photo_use_case.dart';
import 'package:glimmer_app/domain/use_cases/photo_source_use_case.dart';
import 'package:glimmer_app/domain/use_cases/send_photo_use_case.dart';
import 'package:glimmer_app/utils/result.dart';

import '../../../testing/fakes/fake_repositories.dart';
import '../../../testing/fakes/fake_services.dart';

const _url = 'http://192.168.1.50';
const _key = 'Ab3dEfGh9kLm2nPq';

Map<String, dynamic> _state({bool source = true}) => {
  'fw': '0.25.0',
  'skills': ['agent', 'photo'],
  'skills_on': ['agent', 'photo'],
  'photos': 0,
  if (source) 'photo_source': {'state': 'none', 'remote': false, 'index': 0, 'count': 0},
};

Map<String, dynamic> _list(List<String> names) => {
  'photos': [
    for (final n in names) {'name': n, 'size': 1000},
  ],
  'free': 300000,
};

Uint8List _jpeg(int n) => Uint8List.fromList(List.filled(500 + n, n));

void main() {
  late DeviceRig rig;
  late Directory dir;
  late PhotoLibraryRepositoryLocal library;
  late PhotoServerRepositoryLocal server;
  late PhotoSourceUseCase source;
  late int uploads;
  var clock = DateTime(2026, 11, 27, 9);

  setUp(() async {
    rig = await DeviceRig.create();
    dir = await Directory.systemTemp.createTemp('lib');
    library = PhotoLibraryRepositoryLocal(
      files: PhotoLibraryService(root: dir),
      now: () => clock = clock.add(const Duration(minutes: 1)),
    );
    server = PhotoServerRepositoryLocal(server: PhotoServerService());
    source = PhotoSourceUseCase(
      device: rig.repo,
      library: library,
      server: server,
      phoneIps: () async => ['10.0.0.4', '192.168.1.20'],
      key: _key,
    );
    uploads = 0;
    rig.api.uploadFileAnswerFor = (_) => {'ok': true, 'name': 'p${++uploads + 10}.jpg', 'count': 1};
    rig.api.on(_url, 'POST', '/api/photos/source', {'ok': true, 'state': 'online'});
  });
  tearDown(() async {
    await server.stop();
    rig.repo.dispose();
    await dir.delete(recursive: true);
  });

  test('R-AK-4 sync: serves the library, tells the device {host on its network, port, key}', () async {
    await rig.connect(_url, _state());
    rig.api.on(_url, 'GET', '/api/photos', _list([]));
    expect(source.supported, isTrue);
    expect(await source.sync(), isA<Ok<void>>());
    expect(server.running, isTrue);
    expect(rig.posts('/api/photos/source').single.body, {'host': '192.168.1.20', 'port': server.port, 'key': _key});
  });

  test('R-AK-2 the device asks the photo after X: the library in order, wrapping', () async {
    await rig.connect(_url, _state());
    for (var i = 1; i <= 3; i++) {
      await library.add(_jpeg(i));
    }
    final a = (await source.next(0))!;
    expect((a.id, a.index, a.count), (1, 1, 3));
    expect(a.jpeg, _jpeg(1));
    expect((await source.next(3))!.id, 1);
  });

  test('R-AK-3 the cache = the 8 newest: the oldest cached one leaves, the new one is uploaded', () async {
    await rig.connect(_url, _state());
    for (var i = 1; i <= 8; i++) {
      await library.add(_jpeg(i), cachedAs: 'p$i.jpg');
    }
    await library.add(_jpeg(9));
    rig.api.on(_url, 'GET', '/api/photos', _list([for (var i = 1; i <= 8; i++) 'p$i.jpg']));
    rig.api.on(_url, 'DELETE', '/api/photos?name=p1.jpg', {'ok': true, 'count': 7});
    final r = await source.syncCache();
    expect(r, isA<Ok<SentPhoto?>>());
    expect(rig.api.calls.where((c) => c.method == 'DELETE').map((c) => c.path), ['/api/photos?name=p1.jpg']);
    expect(rig.api.uploadedFile, _jpeg(9));
    final cached = {for (final p in await library.list()) p.id: p.cachedAs};
    expect(cached[1], isNull);
    expect(cached[9], 'p11.jpg');
  });

  test('R-AK-1 R-AK-3 sending a photo: into the library, then onto the device as the newest', () async {
    await rig.connect(_url, _state());
    rig.api.on(_url, 'GET', '/api/photos', _list([]));
    final copies = FakePhotoStoreService();
    final send = SendPhotoUseCase(
      device: rig.repo,
      photos: PhotoRepositoryLocal(store: copies, picker: FakePhotoPickerService()),
      encode: (p, side, max) async => _jpeg(1),
      library: library,
      source: source,
    );
    final r = await send(PhotoPixels(Uint8List(16), 2, 2));
    expect((r as Ok<SentPhoto>).value.name, 'p11.jpg');
    final lib = await library.list();
    expect(lib.map((p) => (p.id, p.cachedAs)), [(1, 'p11.jpg')]);
    expect(copies.files['p11.jpg'], _jpeg(1));
  });

  test('R-AK-1 deleting on the Ảnh tab removes it from the library; the next newest refills the cache', () async {
    await rig.connect(_url, _state());
    for (var i = 1; i <= 9; i++) {
      await library.add(_jpeg(i), cachedAs: i >= 2 ? 'p$i.jpg' : null);
    }
    rig.api.on(_url, 'DELETE', '/api/photos?name=p9.jpg', {'ok': true, 'count': 7});
    rig.api.on(_url, 'GET', '/api/photos', _list([for (var i = 2; i <= 8; i++) 'p$i.jpg']));
    final del = DeletePhotoUseCase(
      device: rig.repo,
      photos: PhotoRepositoryLocal(store: FakePhotoStoreService(), picker: FakePhotoPickerService()),
      library: library,
      source: source,
    );
    expect(await del('p9.jpg'), isA<Ok<int>>());
    final lib = await library.list();
    expect(lib.map((p) => p.id), [1, 2, 3, 4, 5, 6, 7, 8]);
    expect(rig.api.uploadedFile, _jpeg(1), reason: 'photo 1 is among the 8 newest again');
  });

  test(
    'R-AK-5 firmware without photo_source: no source, a photo goes straight to the device and into the library',
    () async {
      await rig.connect(_url, _state(source: false));
      expect(source.supported, isFalse);
      expect(await source.sync(), isA<Ok<void>>());
      expect(rig.posts('/api/photos/source'), isEmpty);
      expect(server.running, isFalse);
      final send = SendPhotoUseCase(
        device: rig.repo,
        photos: PhotoRepositoryLocal(store: FakePhotoStoreService(), picker: FakePhotoPickerService()),
        encode: (p, side, max) async => _jpeg(2),
        library: library,
        source: source,
      );
      rig.api.uploadFileAnswerFor = null;
      rig.api.uploadFileAnswer = {'ok': true, 'name': 'p4.jpg', 'count': 4};
      final r = await send(PhotoPixels(Uint8List(16), 2, 2));
      expect((r as Ok<SentPhoto>).value.name, 'p4.jpg');
      expect((await library.list()).map((p) => p.cachedAs), ['p4.jpg']);
    },
  );

  test('R-AK-1 the library survives a restart of the app (library.json)', () async {
    await library.add(_jpeg(1));
    await library.add(_jpeg(2), cachedAs: 'p3.jpg');
    final again = PhotoLibraryRepositoryLocal(files: PhotoLibraryService(root: dir));
    final lib = await again.list();
    expect(lib.map((p) => (p.id, p.cachedAs)), [(1, null), (2, 'p3.jpg')]);
    expect(await again.bytes(2), _jpeg(2));
    await again.remove(1);
    expect((await again.list()).map((p) => p.id), [2]);
    expect(await again.bytes(1), isNull);
    expect(lib.first, isA<LibraryPhoto>());
  });
}
