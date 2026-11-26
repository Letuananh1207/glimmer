import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/data/repositories/photo/photo_repository_local.dart';
import 'package:glimmer_app/data/services/device_api_service.dart';
import 'package:glimmer_app/domain/models/app_error.dart';
import 'package:glimmer_app/domain/models/device_photo.dart';
import 'package:glimmer_app/domain/use_cases/send_photo_use_case.dart';
import 'package:glimmer_app/ui/photo_crop/view_models/photo_crop_view_model.dart';
import 'package:glimmer_app/utils/result.dart';

import '../../../../testing/fakes/fake_crop_image.dart';
import '../../../../testing/fakes/fake_repositories.dart';
import '../../../../testing/fakes/fake_services.dart';

const _url = 'http://192.168.1.50';

void main() {
  late DeviceRig rig;
  late FakePhotoPickerService picker;
  late PhotoRepositoryLocal photos;
  late List<FakeCropImage> decoded;

  setUp(() async {
    rig = await DeviceRig.create();
    await rig.connect(_url, {'fw': '0.24.0', 'skills_on': ['agent', 'photo'], 'photos': 5});
    picker = FakePhotoPickerService();
    photos = PhotoRepositoryLocal(store: FakePhotoStoreService(), picker: picker);
    decoded = [];
  });
  tearDown(() => rig.repo.dispose());

  /// Image [w] × [h] (bytes ignored); a decoder that throws when [broken].
  Future<PhotoCropViewModel> vmFor({int w = 400, int h = 300, bool broken = false, int count = 5}) async {
    final vm = PhotoCropViewModel(
      image: Uint8List(1),
      info: PhotoInfo(photos: [for (var i = 0; i < count; i++) DevicePhoto('p$i.jpg', 1)]),
      send: SendPhotoUseCase(device: rig.repo, photos: photos, encode: (p, s, m) async => Uint8List(900)),
      photos: photos,
      decode: (_) async {
        if (broken) throw Exception('not an image');
        final img = FakeCropImage(w, h);
        decoded.add(img);
        return img;
      },
    );
    await pumpEventQueue();
    return vm;
  }

  group('crop transform', () {
    test('opens on the centre square of the short side', () async {
      final vm = await vmFor();
      expect(vm.status, CropStatus.crop);
      expect(vm.crop, const Rect.fromLTWH(50, 0, 300, 300));
      vm.dispose();
    });

    test('unreadable file → unreadable', () async {
      final vm = await vmFor(broken: true);
      expect(vm.status, CropStatus.unreadable);
      vm.dispose();
    });

    test('pan follows the finger and stops at the edges (frame always covered)', () async {
      final vm = await vmFor();
      vm.pan(const Offset(26, 0), 260); // image right by 26 pt = 30 px at this zoom
      expect(vm.crop.left, closeTo(20, 1e-9));
      vm.pan(const Offset(1000, 1000), 260);
      expect((vm.crop.left, vm.crop.top), (0.0, 0.0));
      vm.pan(const Offset(-5000, -5000), 260);
      expect((vm.crop.right, vm.crop.bottom), (400.0, 300.0));
      vm.dispose();
    });

    test('zoom: in around the focal point, out no further than the short side, in no further than ×8', () async {
      final vm = await vmFor();
      vm.zoom(2, const Offset(130, 130), 260); // centre stays centre
      expect(vm.crop, const Rect.fromLTWH(125, 75, 150, 150));
      vm.zoom(0.1, Offset.zero, 260);
      expect(vm.crop.width, 300, reason: 'smallest zoom = short side');
      expect(vm.crop.left >= 0 && vm.crop.right <= 400, true);
      vm.zoom(100, const Offset(260, 260), 260);
      expect(vm.crop.width, 300 / PhotoCropViewModel.maxZoom);
      expect(vm.crop.right <= 400 && vm.crop.bottom <= 300, true);
      vm.dispose();
    });

    test('no editing while sending or done', () async {
      final vm = await vmFor();
      rig.api.holdUpload = Completer<void>();
      unawaited(vm.send());
      await pumpEventQueue();
      final before = vm.crop;
      vm.pan(const Offset(30, 0), 260);
      expect(vm.crop, before);
      rig.api.holdUpload!.complete();
      vm.dispose();
    });
  });

  group('send', () {
    test('sending with progress → done with the device count; the crop region is what gets rendered', () async {
      final vm = await vmFor();
      rig.api.holdUpload = Completer<void>();
      rig.api.uploadFileAnswer = {'ok': true, 'name': 'p6.jpg', 'count': 6};
      final f = vm.send();
      await pumpEventQueue();
      expect(vm.status, CropStatus.sending);
      expect(vm.progress, closeTo(SendPhotoUseCase.encodeShare + 0.9 * 0.5, 1e-9));
      expect(vm.previewCount, 6);
      rig.api.holdUpload!.complete();
      await f;
      expect(vm.status, CropStatus.done);
      expect((vm.sent!.count, vm.previewCount), (6, 6));
      expect(decoded.single.rendered.single, const Rect.fromLTWH(50, 0, 300, 300));
      vm.dispose();
    });

    test('cancel while sending → back to cropping at once; the late answer is ignored', () async {
      final vm = await vmFor();
      rig.api.holdUpload = Completer<void>();
      final f = vm.send();
      await pumpEventQueue();
      vm.cancel();
      expect((vm.status, vm.progress), (CropStatus.crop, 0.0));
      rig.api.holdUpload!.complete();
      await f;
      expect(vm.status, CropStatus.crop);
      vm.dispose();
    });

    test('each device error → its screen state; the crop is kept', () async {
      final cases = {
        const DeviceHttpException(413, '{"error":"full","count":8}'): CropStatus.full,
        const DeviceHttpException(413, '{"error":"too_big","count":2}'): CropStatus.tooBig,
        const DeviceHttpException(507, '{"error":"no_space","count":2}'): CropStatus.noSpace,
        const DeviceHttpException(400, '{"error":"progressive","count":2}'): CropStatus.rejected,
        const DeviceHttpException(400, '{"error":"not_jpeg","count":2}'): CropStatus.rejected,
        const DeviceHttpException(500, '{"error":"fs","count":2}'): CropStatus.rejected,
        const DeviceHttpException(0, 'SocketException'): CropStatus.offline,
      };
      for (final e in cases.entries) {
        final vm = await vmFor();
        vm.pan(const Offset(13, 0), 260);
        final crop = vm.crop;
        rig.api.uploadFileAnswer = e.key;
        await vm.send();
        expect(vm.status, e.value, reason: '${e.key}');
        expect((vm.isError, vm.canEdit, vm.crop), (true, true, crop));
        vm.dispose();
      }
    });

    test('too big after every quality step (encoder gives up) → tooBig; "Cắt lại" back to cropping', () async {
      final vm = PhotoCropViewModel(
        image: Uint8List(1),
        info: const PhotoInfo(),
        send: SendPhotoUseCase(device: rig.repo, photos: photos, encode: (p, s, m) async => null),
        photos: photos,
        decode: (_) async => FakeCropImage(300, 300),
      );
      await pumpEventQueue();
      await vm.send();
      expect(vm.status, CropStatus.tooBig);
      vm.backToCrop();
      expect(vm.status, CropStatus.crop);
      vm.dispose();
    });

    test('statusOf: unauthorized / other → rejected, cancelled → crop', () {
      expect(PhotoCropViewModel.statusOf(const AppError(AppErrorKind.unauthorized)), CropStatus.rejected);
      expect(PhotoCropViewModel.statusOf(const AppError(AppErrorKind.cancelled)), CropStatus.crop);
    });

    test('retry after an error sends again', () async {
      final vm = await vmFor();
      rig.api.uploadFileAnswer = const DeviceHttpException(0, 'SocketException');
      await vm.send();
      expect(vm.status, CropStatus.offline);
      rig.api.uploadFileAnswer = {'ok': true, 'name': 'p6.jpg', 'count': 6};
      await vm.send();
      expect(vm.status, CropStatus.done);
      vm.dispose();
    });
  });

  group('pick other', () {
    test('backing out keeps everything; a new image resets the crop and the old one is released', () async {
      final vm = await vmFor();
      picker.next = null;
      expect((await vm.pickOther() as Ok<bool>).value, false);
      expect(decoded, hasLength(1));
      picker.next = Uint8List(2);
      expect((await vm.pickOther() as Ok<bool>).value, true);
      expect(vm.status, CropStatus.crop);
      expect(decoded.first.disposed, true);
      expect(picker.asked, [false, false], reason: 'always the gallery');
      vm.dispose();
      expect(decoded.last.disposed, true);
    });
  });
}
