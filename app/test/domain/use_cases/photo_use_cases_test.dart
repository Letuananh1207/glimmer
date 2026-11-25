import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/data/repositories/photo/photo_repository.dart';
import 'package:glimmer_app/data/repositories/photo/photo_repository_local.dart';
import 'package:glimmer_app/data/services/device_api_service.dart';
import 'package:glimmer_app/domain/models/app_error.dart';
import 'package:glimmer_app/domain/models/device_photo.dart';
import 'package:glimmer_app/domain/use_cases/delete_photo_use_case.dart';
import 'package:glimmer_app/domain/use_cases/load_photos_use_case.dart';
import 'package:glimmer_app/domain/use_cases/send_photo_use_case.dart';
import 'package:glimmer_app/utils/cancel_token.dart';
import 'package:glimmer_app/utils/result.dart';

import '../../../testing/fakes/fake_repositories.dart';
import '../../../testing/fakes/fake_services.dart';

const _url = 'http://192.168.1.50';
final _jpeg = Uint8List.fromList(List.filled(1200, 7));
const _pixels = PhotoPixels.new;

AppErrorKind _kind(Result<Object?> r) => ((r as Error).error as AppError).kind;

void main() {
  late DeviceRig rig;
  late FakePhotoStoreService files;
  late FakePhotoPickerService picker;
  late PhotoRepository photos;

  setUp(() async {
    rig = await DeviceRig.create();
    await rig.connect(_url, {'fw': '0.24.0', 'skills': ['agent', 'photo'], 'skills_on': ['agent'], 'photos': 0});
    files = FakePhotoStoreService();
    picker = FakePhotoPickerService();
    photos = PhotoRepositoryLocal(store: files, picker: picker);
  });
  tearDown(() => rig.repo.dispose());

  group('SendPhotoUseCase', () {
    SendPhotoUseCase send({Uint8List? out}) => SendPhotoUseCase(
        device: rig.repo, photos: photos, encode: (p, side, max) async => out ?? _jpeg);
    final px = _pixels(Uint8List(16), 2, 2);

    test('encode → multipart `photo` → copy kept under the device name; progress 0…1', () async {
      rig.api.uploadFileAnswer = {'ok': true, 'name': 'p3.jpg', 'count': 3};
      final progress = <double>[];
      final r = await send()(px, onProgress: progress.add);
      final sent = (r as Ok<SentPhoto>).value;
      expect((sent.name, sent.count, sent.bytes), ('p3.jpg', 3, _jpeg.length));
      final call = rig.api.calls.lastWhere((c) => c.method == 'UPLOAD');
      expect((call.path, call.body), ('/api/photos', 'photo'));
      expect(rig.api.uploadedFile, _jpeg);
      expect(files.files['p3.jpg'], _jpeg);
      expect(progress.first, 0);
      expect(progress, contains(SendPhotoUseCase.encodeShare));
      expect(progress.last, 1);
    });

    test('nothing fits 40 KB → photoTooBig, nothing sent', () async {
      final r = await SendPhotoUseCase(device: rig.repo, photos: photos, encode: (p, s, m) async => null)(px);
      expect(_kind(r), AppErrorKind.photoTooBig);
      expect(rig.api.calls.where((c) => c.method == 'UPLOAD'), isEmpty);
    });

    test('unreadable pixels → photoRejected', () async {
      final r = await SendPhotoUseCase(device: rig.repo, photos: photos)(_pixels(Uint8List(3), 188, 188));
      expect(_kind(r), AppErrorKind.photoRejected);
    });

    test('device errors → kinds; no copy kept', () async {
      final cases = {
        const DeviceHttpException(413, '{"error":"full","count":8}'): AppErrorKind.photoFull,
        const DeviceHttpException(413, '{"error":"too_big","count":2}'): AppErrorKind.photoTooBig,
        const DeviceHttpException(507, '{"error":"no_space","count":2}'): AppErrorKind.photoNoSpace,
        const DeviceHttpException(400, '{"error":"progressive","count":2}'): AppErrorKind.photoRejected,
        const DeviceHttpException(400, '{"error":"bad_size","count":2}'): AppErrorKind.photoRejected,
        const DeviceHttpException(0, 'SocketException'): AppErrorKind.unreachable,
        const DeviceHttpException(401): AppErrorKind.unauthorized,
        const DeviceHttpException(500, '{"error":"fs","count":2}'): AppErrorKind.http,
      };
      for (final e in cases.entries) {
        rig.api.uploadFileAnswer = e.key;
        expect(_kind(await send()(px)), e.value, reason: '${e.key}');
      }
      expect(files.files, isEmpty);
    });

    test('cancelled before upload → cancelled, nothing sent', () async {
      final cancel = CancelToken()..cancel();
      expect(_kind(await send()(px, cancel: cancel)), AppErrorKind.cancelled);
      expect(rig.api.calls.where((c) => c.method == 'UPLOAD'), isEmpty);
    });
  });

  group('LoadPhotosUseCase', () {
    test('device order, copy as preview only when name and size match; stale copies dropped', () async {
      files.files['p1.jpg'] = Uint8List(100);
      files.files['p2.jpg'] = Uint8List(50); // device has p2 with another size (sent from elsewhere)
      files.files['p9.jpg'] = Uint8List(10); // deleted on the device web page
      rig.api.on(_url, 'GET', '/api/photos', {
        'photos': [
          {'name': 'p2.jpg', 'size': 900},
          {'name': 'p1.jpg', 'size': 100},
        ],
        'free': 200000,
        'max_count': 8,
        'max_bytes': 40960,
        'side': 188,
      });
      final r = await LoadPhotosUseCase(device: rig.repo, photos: photos)();
      final g = (r as Ok<PhotoGallery>).value;
      expect(g.items.map((i) => (i.name, i.preview?.length)), [('p2.jpg', null), ('p1.jpg', 100)]);
      expect((g.info.count, g.info.left), (2, 6));
      expect(files.files.keys, unorderedEquals(['p1.jpg', 'p2.jpg']));
    });

    test('device offline → unreachable, copies untouched', () async {
      files.files['p1.jpg'] = Uint8List(100);
      expect(_kind(await LoadPhotosUseCase(device: rig.repo, photos: photos)()), AppErrorKind.unreachable);
      expect(files.files.keys, ['p1.jpg']);
    });
  });

  group('DeletePhotoUseCase', () {
    test('DELETE /api/photos?name= and drop the copy', () async {
      files.files['p3.jpg'] = Uint8List(10);
      rig.api.on(_url, 'DELETE', '/api/photos?name=p3.jpg', {'ok': true, 'count': 4});
      final r = await DeletePhotoUseCase(device: rig.repo, photos: photos)('p3.jpg');
      expect((r as Ok<int>).value, 4);
      expect(files.files, isEmpty);
    });

    test('already gone (404) counts as deleted', () async {
      files.files['p3.jpg'] = Uint8List(10);
      rig.api.on(_url, 'DELETE', '/api/photos?name=p3.jpg', const DeviceHttpException(404));
      final r = await DeletePhotoUseCase(device: rig.repo, photos: photos)('p3.jpg');
      expect((r as Ok<int>).value, -1);
      expect(files.files, isEmpty);
    });

    test('offline → error, copy kept', () async {
      files.files['p3.jpg'] = Uint8List(10);
      final r = await DeletePhotoUseCase(device: rig.repo, photos: photos)('p3.jpg');
      expect(_kind(r), AppErrorKind.unreachable);
      expect(files.files.keys, ['p3.jpg']);
    });
  });

  group('PhotoRepositoryLocal', () {
    test('pick: camera / gallery, backing out = Ok(null)', () async {
      picker.next = Uint8List(3);
      expect((await photos.pick(PhotoSource.camera) as Ok<Uint8List?>).value, hasLength(3));
      picker.next = null;
      expect((await photos.pick(PhotoSource.gallery) as Ok<Uint8List?>).value, isNull);
      expect(picker.asked, [true, false]);
    });

    test('a device name never leaves the photos folder', () async {
      await photos.saveCopy('../x.jpg', Uint8List(2));
      expect(files.files.keys, ['.._x.jpg']);
    });
  });

  test('DeviceState.photos: count, null on firmware without photos', () async {
    expect(rig.repo.state!.photos, 0);
    rig.api.on(_url, 'GET', '/api/state', {'fw': '0.23.0'});
    await rig.repo.refresh();
    expect(rig.repo.state!.photos, isNull);
  });
}
