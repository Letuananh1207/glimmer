import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/data/repositories/photo/photo_repository.dart';
import 'package:glimmer_app/data/repositories/photo/photo_repository_local.dart';
import 'package:glimmer_app/data/services/device_api_service.dart';
import 'package:glimmer_app/domain/models/app_error.dart';
import 'package:glimmer_app/domain/use_cases/delete_photo_use_case.dart';
import 'package:glimmer_app/domain/use_cases/load_photos_use_case.dart';
import 'package:glimmer_app/ui/dashboard/view_models/photo_tab_view_model.dart';
import 'package:glimmer_app/utils/result.dart';

import '../../../../testing/fakes/fake_repositories.dart';
import '../../../../testing/fakes/fake_services.dart';

const _url = 'http://192.168.1.50';

Map<String, dynamic> _photos(int n, {int max = 8}) => {
      'photos': [
        for (var i = 1; i <= n; i++) {'name': 'p$i.jpg', 'size': 100 + i},
      ],
      'free': 300000,
      'max_count': max,
      'max_bytes': 40960,
      'side': 188,
    };

void main() {
  late DeviceRig rig;
  late FakePhotoStoreService files;
  late FakePhotoPickerService picker;
  late PhotoTabViewModel vm;

  setUp(() async {
    rig = await DeviceRig.create();
    await rig.connect(_url, {'fw': '0.24.0', 'skills': ['agent', 'photo'], 'skills_on': ['agent', 'photo'], 'photos': 2});
    files = FakePhotoStoreService();
    picker = FakePhotoPickerService();
    final photos = PhotoRepositoryLocal(store: files, picker: picker);
    vm = PhotoTabViewModel(
      loadPhotos: LoadPhotosUseCase(device: rig.repo, photos: photos),
      deletePhoto: DeletePhotoUseCase(device: rig.repo, photos: photos),
      photos: photos,
    );
  });
  tearDown(() {
    vm.dispose();
    rig.repo.dispose();
  });

  group('gallery', () {
    test('before loading: no gallery, firmware limits', () {
      expect((vm.gallery, vm.loading, vm.loadError), (null, false, null));
      expect((vm.info.maxCount, vm.info.side), (8, 188));
    });

    test('load: device order, copy as thumbnail when it matches, "không có bản xem" otherwise', () async {
      files.files['p2.jpg'] = Uint8List(102);
      rig.api.on(_url, 'GET', '/api/photos', _photos(2));
      final f = vm.load();
      expect(vm.loading, true);
      await f;
      final g = vm.gallery!;
      expect(g.items.map((i) => (i.name, i.preview != null)), [('p1.jpg', false), ('p2.jpg', true)]);
      expect((g.info.count, g.info.left, g.info.full, vm.loading), (2, 6, false, false));
    });

    test('full: 8/8', () async {
      rig.api.on(_url, 'GET', '/api/photos', _photos(8));
      await vm.load();
      expect((vm.gallery!.info.full, vm.gallery!.info.left), (true, 0));
    });

    test('load error keeps the last gallery; loadIfNeeded does not retry by itself', () async {
      rig.api.on(_url, 'GET', '/api/photos', _photos(1));
      await vm.load();
      rig.api.gone(_url);
      await vm.load();
      expect(vm.loadError?.kind, AppErrorKind.unreachable);
      expect(vm.gallery!.items, hasLength(1));
    });

    test('a load asked while one runs runs again afterwards', () async {
      rig.api.on(_url, 'GET', '/api/photos', _photos(1));
      final first = vm.load();
      final second = vm.load(); // returns at once, queued
      await second;
      rig.api.on(_url, 'GET', '/api/photos', _photos(3));
      await first;
      expect(vm.gallery!.items, hasLength(3));
    });
  });

  group('delete', () {
    setUp(() async {
      rig.api.on(_url, 'GET', '/api/photos', _photos(3));
      await vm.load();
    });

    test('deleting spinner on that tile only, then the list reloads', () async {
      rig.api.holdDeletes = Completer<void>();
      rig.api.on(_url, 'DELETE', '/api/photos?name=p2.jpg', {'ok': true, 'count': 2});
      final f = vm.delete('p2.jpg');
      expect(vm.deleting, {'p2.jpg'});
      rig.api.on(_url, 'GET', '/api/photos', {
        ..._photos(0),
        'photos': [
          {'name': 'p1.jpg', 'size': 101},
          {'name': 'p3.jpg', 'size': 103},
        ],
      });
      rig.api.holdDeletes!.complete();
      await f;
      expect(vm.deleting, isEmpty);
      expect(vm.deleteError, isNull);
      expect(vm.gallery!.items.map((i) => i.name), ['p1.jpg', 'p3.jpg']);
    });

    test('error → banner with the name; retry deletes it again and clears the banner', () async {
      await vm.delete('p2.jpg'); // no answer → unreachable
      expect((vm.deleteError?.kind, vm.failedName, vm.deleting.isEmpty), (AppErrorKind.unreachable, 'p2.jpg', true));
      expect(vm.gallery!.items, hasLength(3), reason: 'nothing removed');
      rig.api.on(_url, 'DELETE', '/api/photos?name=p2.jpg', {'ok': true, 'count': 2});
      await vm.retryDelete();
      expect((vm.deleteError, vm.failedName), (null, null));
      expect(rig.api.calls.where((c) => c.method == 'DELETE'), hasLength(2));
    });

    test('a photo already gone counts as deleted', () async {
      rig.api.on(_url, 'DELETE', '/api/photos?name=p2.jpg', const DeviceHttpException(404));
      await vm.delete('p2.jpg');
      expect(vm.deleteError, isNull);
    });
  });

  group('pick', () {
    test('passes the source through; backing out = Ok(null)', () async {
      picker.next = Uint8List(4);
      expect((await vm.pick(PhotoSource.camera) as Ok<Uint8List?>).value, hasLength(4));
      picker.next = null;
      expect((await vm.pick(PhotoSource.gallery) as Ok<Uint8List?>).value, isNull);
      expect(picker.asked, [true, false]);
    });

    test('lost photo is asked once', () async {
      expect(await vm.lostPick(), isNull);
      expect(await vm.lostPick(), isNull);
    });
  });
}
