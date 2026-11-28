import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/data/repositories/photo/photo_library_repository_local.dart';
import 'package:glimmer_app/data/repositories/photo/photo_repository_local.dart';
import 'package:glimmer_app/data/repositories/photo/photo_server_repository_local.dart';
import 'package:glimmer_app/data/services/device_api_service.dart';
import 'package:glimmer_app/data/services/photo_library_service.dart';
import 'package:glimmer_app/data/services/photo_server_service.dart';
import 'package:glimmer_app/domain/models/device_state.dart';
import 'package:glimmer_app/domain/use_cases/photo_library_use_case.dart';
import 'package:glimmer_app/domain/use_cases/photo_source_use_case.dart';
import 'package:glimmer_app/utils/result.dart';

import '../../../testing/fakes/fake_repositories.dart';
import '../../../testing/fakes/fake_services.dart';

const _url = 'http://192.168.1.50';

Map<String, dynamic> _state = {
  'fw': '0.25.0',
  'skills': ['agent', 'photo'],
  'skills_on': ['agent', 'photo'],
  'photos': 0,
  'photo_source': {'state': 'online', 'remote': true, 'index': 2, 'count': 3},
};

Uint8List _jpeg(int n) => Uint8List.fromList(List.filled(500 + n, n));

void main() {
  late DeviceRig rig;
  late Directory dir;
  late PhotoLibraryRepositoryLocal library;
  late PhotoServerRepositoryLocal server;
  late FakePhotoStoreService copies;
  late PhotoLibraryUseCase uc;
  var clock = DateTime(2026, 11, 28, 9);

  setUp(() async {
    rig = await DeviceRig.create();
    dir = await Directory.systemTemp.createTemp('lib');
    library = PhotoLibraryRepositoryLocal(
      files: PhotoLibraryService(root: dir),
      now: () => clock = clock.add(const Duration(minutes: 1)),
    );
    server = PhotoServerRepositoryLocal(server: PhotoServerService());
    copies = FakePhotoStoreService();
    final source = PhotoSourceUseCase(
      device: rig.repo,
      library: library,
      server: server,
      phoneIps: () async => ['192.168.1.20'],
      key: 'k',
    );
    uc = PhotoLibraryUseCase(
      device: rig.repo,
      library: library,
      photos: PhotoRepositoryLocal(store: copies, picker: FakePhotoPickerService()),
      source: source,
    );
    rig.api.on(_url, 'GET', '/api/photos', {'photos': <Object>[], 'free': 300000});
    await rig.connect(_url, _state);
  });
  tearDown(() async {
    await server.stop();
    rig.repo.dispose();
    await dir.delete(recursive: true);
  });

  test('photo_source is read from /api/state (state, index, count)', () {
    expect(rig.repo.state!.photoSource, const PhotoSourceInfo(state: PhotoSourceState.online, index: 2, count: 3));
  });

  test('load: newest first, each with its JPEG and its place in the slideshow (oldest = 1)', () async {
    for (var i = 1; i <= 3; i++) {
      await library.add(_jpeg(i));
    }
    final items = await uc.load();
    expect(items.map((e) => (e.id, e.order)), [(3, 3), (2, 2), (1, 1)]);
    expect(items.first.preview, _jpeg(3));
  });

  test('R-AK-1 delete a photo not on the device: only the library', () async {
    await library.add(_jpeg(1));
    expect(await uc.delete(1), isA<Ok<void>>());
    expect(await library.list(), isEmpty);
    expect(rig.api.calls.where((c) => c.method == 'DELETE'), isEmpty);
  });

  test('R-AK-1 delete a cached photo: the device copy first, then the library', () async {
    await library.add(_jpeg(1), cachedAs: 'p1.jpg');
    rig.api.on(_url, 'DELETE', '/api/photos?name=p1.jpg', {'ok': true, 'count': 0});
    expect(await uc.delete(1), isA<Ok<void>>());
    expect(await library.list(), isEmpty);
  });

  test('the device refuses to delete its copy → error, the photo stays in the library', () async {
    await library.add(_jpeg(1), cachedAs: 'p1.jpg');
    rig.api.on(_url, 'DELETE', '/api/photos?name=p1.jpg', const DeviceHttpException(500, '{"error":"fs"}'));
    expect(await uc.delete(1), isA<Error<void>>());
    expect((await library.list()).single.id, 1);
  });
}
