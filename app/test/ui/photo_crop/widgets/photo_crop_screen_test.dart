import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/data/repositories/photo/photo_repository_local.dart';
import 'package:glimmer_app/data/services/device_api_service.dart';
import 'package:glimmer_app/domain/models/device_photo.dart';
import 'package:glimmer_app/domain/use_cases/send_photo_use_case.dart';
import 'package:glimmer_app/l10n/app_localizations.dart';
import 'package:glimmer_app/ui/core/themes/app_theme.dart';
import 'package:glimmer_app/ui/photo_crop/view_models/photo_crop_view_model.dart';
import 'package:glimmer_app/ui/photo_crop/widgets/crop_frame.dart';
import 'package:glimmer_app/ui/photo_crop/widgets/device_photo_preview.dart';
import 'package:glimmer_app/ui/photo_crop/widgets/photo_crop_screen.dart';

import '../../../../testing/fakes/fake_crop_image.dart';
import '../../../../testing/fakes/fake_repositories.dart';
import '../../../../testing/fakes/fake_services.dart';

const _url = 'http://192.168.1.50';
final _vi = lookupAppLocalizations(const Locale('vi'));

void main() {
  late DeviceRig rig;
  late FakePhotoPickerService picker;
  late int closed;

  setUp(() async {
    rig = await DeviceRig.create();
    picker = FakePhotoPickerService();
    closed = 0;
  });
  tearDown(() => rig.repo.dispose());

  Future<void> frames(WidgetTester t) async {
    for (var i = 0; i < 5; i++) {
      await t.pump(const Duration(milliseconds: 50));
    }
  }

  /// Cắt ảnh at 390 × 844 for a 400 × 300 image; the device holds [count] photos.
  Future<PhotoCropViewModel> open(WidgetTester t, {int count = 5}) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.runAsync(() => rig.connect(_url, {'fw': '0.24.0', 'skills_on': ['agent', 'photo'], 'photos': count}));
    final photos = PhotoRepositoryLocal(store: FakePhotoStoreService(), picker: picker);
    final vm = PhotoCropViewModel(
      image: Uint8List(1),
      info: PhotoInfo(photos: [for (var i = 0; i < count; i++) DevicePhoto('p$i.jpg', 1)]),
      send: SendPhotoUseCase(device: rig.repo, photos: photos, encode: (p, s, m) async => Uint8List(900)),
      photos: photos,
      decode: (_) async => FakeCropImage(400, 300),
    );
    addTearDown(vm.dispose);
    await t.pumpWidget(MaterialApp(
      theme: AppTheme.dark(),
      locale: const Locale('vi'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: PhotoCropScreen(viewModel: vm, onClose: () => closed++),
    ));
    await frames(t);
    return vm;
  }

  /// Tap "Gửi ảnh" (or [label]) and let the upload answer.
  Future<void> send(WidgetTester t, [String? label]) async {
    await t.tap(find.text(label ?? _vi.photoCropSend));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await frames(t);
  }

  testWidgets('crop: title, frame 260 in a 340 stage, hint, preview 180 with "6/6", pick other + send', (t) async {
    final vm = await open(t);
    expect(vm.status, CropStatus.crop);
    expect(find.text(_vi.photoCropTitle), findsOneWidget);
    expect(t.getSize(find.byType(CropFrame)).height, 340);
    expect(find.bySemanticsLabel(_vi.photoCropAreaA11y), findsOneWidget);
    expect(find.text(_vi.photoCropHint), findsOneWidget);
    expect(find.text(_vi.photoCropPreview), findsWidgets);
    expect(t.getSize(find.byType(DevicePhotoPreview)), const Size.square(180));
    expect(find.text('6/6'), findsOneWidget, reason: 'the new photo would be 6th of 6');
    expect(find.text(_vi.photoCropPreviewBody), findsOneWidget);
    expect(find.text(_vi.photoCropPickOther), findsOneWidget);
    expect(find.text(_vi.photoCropSend), findsOneWidget);
    expect(t.takeException(), isNull);

    await t.tap(find.byIcon(Icons.arrow_back));
    expect(closed, 1, reason: 'back → tab Ảnh');
  });

  testWidgets('sending: spinner, %, bar, keep open, Huỷ → back to cropping', (t) async {
    final vm = await open(t);
    rig.api.holdUpload = Completer<void>();
    await send(t);
    expect(vm.status, CropStatus.sending);
    expect(find.text(_vi.photoCropSending), findsOneWidget);
    expect(find.text('${(vm.progress * 100).round()}%'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text(_vi.photoCropKeepOpen), findsOneWidget);
    expect(find.text(_vi.photoCropSend), findsNothing);
    expect(t.takeException(), isNull);

    await t.tap(find.text(_vi.commonCancel));
    await frames(t);
    expect(vm.status, CropStatus.crop);
    expect(find.text(_vi.photoCropSend), findsOneWidget);
    rig.api.holdUpload!.complete();
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await frames(t);
    expect(vm.status, CropStatus.crop, reason: 'the late answer is ignored');
  });

  testWidgets('done: tick card "Ảnh 6/8", add another → picker, Xong → tab Ảnh', (t) async {
    final vm = await open(t);
    rig.api.uploadFileAnswer = {'ok': true, 'name': 'p6.jpg', 'count': 6};
    await send(t);
    expect(vm.status, CropStatus.done);
    expect(find.text(_vi.photoCropDoneTitle), findsOneWidget);
    expect(find.text(_vi.photoCropDoneBody(6, 8)), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(t.takeException(), isNull);

    await t.tap(find.text(_vi.photoCropAddAnother));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await frames(t);
    expect(picker.asked, [false], reason: 'gallery picker opened');

    await t.tap(find.text(_vi.photoCropDone));
    expect(closed, 1);
  });

  // Each error: alert title + body, its buttons (spec §7), the crop frame kept.
  final errors = <String, (Object, String Function(), String, List<String Function()>)>{
    'full': (
      const DeviceHttpException(413, '{"error":"full","count":8}'),
      () => _vi.photoCropErrorFullTitle(8),
      _vi.photoCropErrorFullBody,
      [() => _vi.photoCropBackToList],
    ),
    'tooBig': (
      const DeviceHttpException(413, '{"error":"too_big","count":5}'),
      () => _vi.photoCropErrorTooBigTitle,
      _vi.photoCropErrorTooBigBody,
      [() => _vi.photoCropPickOther, () => _vi.photoCropRecrop],
    ),
    'noSpace': (
      const DeviceHttpException(507, '{"error":"no_space","count":5}'),
      () => _vi.photoCropErrorNoSpaceTitle,
      _vi.photoCropErrorNoSpaceBody,
      [() => _vi.photoCropBackToList, () => _vi.commonRetry],
    ),
    'rejected': (
      const DeviceHttpException(400, '{"error":"progressive","count":5}'),
      () => _vi.photoCropErrorRejectedTitle,
      _vi.photoCropErrorRejectedBody,
      [() => _vi.commonCancel, () => _vi.commonRetry],
    ),
    'offline': (
      const DeviceHttpException(0, 'SocketException'),
      () => _vi.photoCropErrorOfflineTitle,
      _vi.photoCropErrorOfflineBody,
      [() => _vi.commonCancel, () => _vi.commonRetry],
    ),
  };
  for (final e in errors.entries) {
    testWidgets('error ${e.key}: alert + buttons, crop kept', (t) async {
      final (answer, title, body, buttons) = e.value;
      final vm = await open(t);
      rig.api.uploadFileAnswer = answer;
      await send(t);
      expect(vm.isError, true, reason: '${vm.status}');
      expect(find.text(title()), findsOneWidget);
      expect(find.text(body), findsOneWidget);
      for (final b in buttons) {
        expect(find.text(b()), findsOneWidget);
      }
      expect(find.text(_vi.photoCropSend), findsNothing);
      expect(find.byType(CropFrame), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('error buttons: Thử lại sends again, Huỷ / Cắt lại back to cropping, Về danh sách closes', (t) async {
    final vm = await open(t);
    rig.api.uploadFileAnswer = const DeviceHttpException(0, 'SocketException');
    await send(t);
    expect(vm.status, CropStatus.offline);
    rig.api.uploadFileAnswer = {'ok': true, 'name': 'p6.jpg', 'count': 6};
    await send(t, _vi.commonRetry);
    expect(vm.status, CropStatus.done);

    await t.tap(find.text(_vi.photoCropDone));
    expect(closed, 1);
  });

  testWidgets('error rejected: Huỷ → cropping; error full: Về danh sách ảnh → tab Ảnh', (t) async {
    final vm = await open(t);
    rig.api.uploadFileAnswer = const DeviceHttpException(400, '{"error":"not_jpeg","count":5}');
    await send(t);
    expect(vm.status, CropStatus.rejected);
    await t.tap(find.text(_vi.commonCancel));
    await frames(t);
    expect(vm.status, CropStatus.crop);

    rig.api.uploadFileAnswer = const DeviceHttpException(413, '{"error":"full","count":8}');
    await send(t);
    expect(vm.status, CropStatus.full);
    await t.tap(find.text(_vi.photoCropBackToList));
    expect(closed, 1);
  });
}
