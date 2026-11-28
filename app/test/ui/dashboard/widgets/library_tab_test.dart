import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/data/repositories/device/device_repository.dart';
import 'package:glimmer_app/data/repositories/photo/photo_repository.dart';
import 'package:glimmer_app/data/repositories/photo/photo_repository_local.dart';
import 'package:glimmer_app/data/repositories/skill/skill_repository_local.dart';
import 'package:glimmer_app/data/services/device_api_service.dart';
import 'package:glimmer_app/domain/models/device_photo.dart';
import 'package:glimmer_app/domain/use_cases/delete_photo_use_case.dart';
import 'package:glimmer_app/domain/use_cases/load_photos_use_case.dart';
import 'package:glimmer_app/domain/use_cases/photo_library_use_case.dart';
import 'package:glimmer_app/domain/use_cases/photo_source_use_case.dart';
import 'package:glimmer_app/domain/use_cases/send_photo_use_case.dart';
import 'package:glimmer_app/domain/use_cases/toggle_skill_use_case.dart';
import 'package:glimmer_app/l10n/app_localizations.dart';
import 'package:glimmer_app/routing/routes.dart';
import 'package:glimmer_app/routing/screens.dart';
import 'package:glimmer_app/ui/core/themes/app_theme.dart';
import 'package:glimmer_app/ui/dashboard/widgets/library_grid.dart';
import 'package:glimmer_app/ui/dashboard/widgets/photo_dialogs.dart';
import 'package:glimmer_app/ui/dashboard/widgets/photo_grid.dart';
import 'package:provider/provider.dart';

import '../../../../testing/fakes/fake_repositories.dart';
import '../../../../testing/fakes/fake_services.dart';

const _url = 'http://192.168.1.50';
final _vi = lookupAppLocalizations(const Locale('vi'));

/// Kho ảnh over [rig]: the library in memory (pass [library] to fill it), the server faked.
List<Provider<Object>> libraryProviders(DeviceRig rig, PhotoRepository photos,
    {FakePhotoLibraryRepository? library, PhotoEncoder? encode}) {
  final lib = library ?? FakePhotoLibraryRepository();
  final source = PhotoSourceUseCase(
    device: rig.repo,
    library: lib,
    server: FakePhotoServerRepository(),
    phoneIps: () async => ['192.168.1.20'],
    key: 'k',
  );
  return [
    Provider<PhotoLibraryUseCase>.value(
      value: PhotoLibraryUseCase(device: rig.repo, library: lib, photos: photos, source: source),
    ),
    Provider<SendPhotoUseCase>.value(
      value: SendPhotoUseCase(device: rig.repo, photos: photos, library: lib, source: source, encode: encode),
    ),
  ];
}

Uint8List _jpeg(int n) => Uint8List.fromList(List.filled(10 + n, n));

void main() {
  late DeviceRig rig;
  late FakePhotoLibraryRepository library;
  late FakePhotoPickerService picker;
  late Completer<PhotoPixels?> crop;
  late List<PhotoCropArgs> cropped;

  setUp(() async {
    rig = await DeviceRig.create();
    library = FakePhotoLibraryRepository();
    picker = FakePhotoPickerService();
    cropped = [];
  });
  tearDown(() => rig.repo.dispose());

  Future<void> frames(WidgetTester t) async {
    for (var i = 0; i < 5; i++) {
      await t.pump(const Duration(milliseconds: 50));
    }
  }

  /// Số liệu › Ảnh with a library of [n] photos (the [cached] newest on the device) and `photo_source` [source].
  Future<void> open(WidgetTester t, {int n = 10, int cached = 8, Map<String, Object> source = const {}}) async {
    for (var i = 1; i <= n; i++) {
      await t.runAsync(() => library.add(_jpeg(i), cachedAs: i > n - cached ? 'p$i.jpg' : null));
    }
    rig.api.device(_url, {
      'fw': '0.25.0',
      'wifi': 'connected',
      'time': 1795500000,
      'skills': ['agent', 'photo'],
      'skills_on': ['agent', 'photo'],
      'photos': cached,
      'photo_source': {'state': 'online', 'remote': true, 'index': 2, 'count': n, ...source},
    });
    rig.api.on(_url, 'GET', '/api/photos', {
      'photos': [
        for (var i = n - cached + 1; i <= n; i++) {'name': 'p$i.jpg', 'size': 20},
      ],
      'free': 300000,
    });
    rig.api.on(_url, 'POST', '/api/photos/source', {'ok': true});
    rig.api.on(_url, 'POST', '/api/channel', <String, dynamic>{});
    final skills = SkillRepositoryLocal(store: (await t.runAsync(fakeStore))!);
    await t.runAsync(() async {
      await rig.repo.connectTo(_url);
      await rig.repo.refresh();
    });
    final photos = PhotoRepositoryLocal(store: FakePhotoStoreService(), picker: picker);
    crop = Completer<PhotoPixels?>();
    await t.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<DeviceRepository>.value(value: rig.repo),
        Provider<ToggleSkillUseCase>.value(value: ToggleSkillUseCase(skills: skills, device: rig.repo)),
        Provider<PhotoRepository>.value(value: photos),
        Provider<LoadPhotosUseCase>.value(value: LoadPhotosUseCase(device: rig.repo, photos: photos)),
        Provider<DeletePhotoUseCase>.value(value: DeletePhotoUseCase(device: rig.repo, photos: photos)),
        ...libraryProviders(rig, photos, library: library, encode: (p, s, m) async => _jpeg(99)),
      ],
      child: MaterialApp(
        theme: AppTheme.dark(),
        locale: const Locale('vi'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: dashboardScreen(
            initialTab: 'photo',
            onBack: () {},
            onOpenSettings: () {},
            onCropPhoto: (a) {
              cropped.add(a);
              return crop.future;
            },
          ),
        ),
      ),
    ));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await frames(t);
  }

  testWidgets('photo_source → Kho ảnh: meta, online line, add tile first, newest first, 8 marked, showing tag',
      (t) async {
    await open(t);
    expect(find.text(_vi.photoLibraryTitle), findsOneWidget);
    expect(find.text(_vi.photoOnDevice), findsNothing);
    expect(find.text(_vi.photoLibraryCount('10', '8')), findsOneWidget);
    expect(find.text(_vi.photoSourceOnline), findsOneWidget);
    expect(find.text(_vi.photoSourceShowing('2', '10')), findsOneWidget);
    final tiles = t.widgetList<LibraryTile>(find.byType(LibraryTile)).toList();
    expect(tiles.map((e) => e.item.id), [10, 9, 8, 7, 6, 5, 4, 3, 2, 1], reason: 'newest first');
    expect(tiles.where((e) => e.onDevice).map((e) => e.item.id), [10, 9, 8, 7, 6, 5, 4, 3], reason: 'R-AK-3');
    expect(tiles.singleWhere((e) => e.showing).item.id, 2, reason: 'photo_source.index 2 = the 2nd added');
    expect(find.text(_vi.photoLibraryShowingTag), findsOneWidget);
    final add = t.getRect(find.byType(AddPhotoTile));
    final first = t.getRect(find.byType(LibraryTile).first);
    expect((add.top, add.left < first.left), (first.top, true), reason: 'add tile first, same row');
    expect(find.text(_vi.photoLibraryNote), findsOneWidget);
  });

  testWidgets('offline: grey line with the reason, no showing tag', (t) async {
    await open(t, n: 5, cached: 5, source: {'state': 'offline'});
    expect(find.text(_vi.photoLibraryCountAll('5')), findsOneWidget);
    expect(find.text(_vi.photoSourceOffline), findsOneWidget);
    expect(find.text(_vi.photoSourceOfflineBody), findsOneWidget);
    expect(find.text(_vi.photoLibraryShowingTag), findsNothing);
  });

  testWidgets('empty: title, body, add button, no note, no show button', (t) async {
    await open(t, n: 0, cached: 0);
    expect(find.text(_vi.photoLibraryCountEmpty), findsOneWidget);
    expect(find.text(_vi.photoLibraryEmptyTitle), findsOneWidget);
    expect(find.text(_vi.photoLibraryNote), findsNothing);
    expect(find.text(_vi.homeShowOnDevice(_vi.skillPhotoName)), findsNothing);
    expect(find.text(_vi.photoSourceOnline), findsNothing);
  });

  testWidgets('add: PhotoCrop in library mode → "Đang thêm…" tile, meta counts it → into the library', (t) async {
    await open(t, n: 2, cached: 2);
    rig.api.uploadFileAnswer = {'ok': true, 'name': 'p3.jpg', 'count': 3};
    await t.tap(find.text(_vi.photoAdd));
    await frames(t);
    picker.next = Uint8List(3);
    await t.tap(find.text(_vi.photoFromGallery));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await frames(t);
    expect(cropped.single.library, isTrue);
    final upload = Completer<void>();
    rig.api.holdUploads = upload;
    crop.complete(PhotoPixels(Uint8List(16), 2, 2));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await frames(t);
    expect(find.text(_vi.photoLibraryAdding), findsOneWidget);
    expect(find.text(_vi.photoLibraryCountAll('3')), findsOneWidget);
    upload.complete();
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await frames(t);
    expect(find.text(_vi.photoLibraryAdding), findsNothing);
    expect(library.photos.map((p) => (p.id, p.cachedAs)).last, (3, 'p3.jpg'));
    expect(find.byType(LibraryTile), findsNWidgets(3));
  });

  testWidgets('add refused by the device → not in the library, banner + retry sends the kept crop', (t) async {
    await open(t, n: 1, cached: 1);
    rig.api.uploadFileAnswer = const DeviceHttpException(507, '{"error":"no_space","count":1}');
    await t.tap(find.text(_vi.photoAdd));
    await frames(t);
    picker.next = Uint8List(3);
    await t.tap(find.text(_vi.photoFromGallery));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    crop.complete(PhotoPixels(Uint8List(16), 2, 2));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await frames(t);
    expect(find.text(_vi.photoLibraryAddErrorTitle), findsOneWidget);
    expect(library.photos, hasLength(1));
    rig.api.uploadFileAnswer = {'ok': true, 'name': 'p2.jpg', 'count': 2};
    await t.tap(find.text(_vi.commonRetry));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await frames(t);
    expect(find.text(_vi.photoLibraryAddErrorTitle), findsNothing);
    expect(library.photos, hasLength(2));
  });

  testWidgets('delete: "Xoá ảnh khỏi kho?" → device copy + library; refused → banner, photo stays', (t) async {
    await open(t, n: 3, cached: 3);
    rig.api.on(_url, 'DELETE', '/api/photos?name=p3.jpg', const DeviceHttpException(500, '{"error":"fs"}'));
    await t.tap(find.byType(LibraryTile).first);
    await frames(t);
    expect(find.text(_vi.photoLibraryDeleteTitle), findsOneWidget);
    await t.tap(find.text(_vi.photoDelete));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await frames(t);
    expect(find.text(_vi.photoLibraryDeleteErrorBody), findsOneWidget);
    expect(library.photos, hasLength(3));
    rig.api.on(_url, 'DELETE', '/api/photos?name=p3.jpg', {'ok': true, 'count': 2});
    await t.tap(find.text(_vi.commonRetry));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await frames(t);
    expect(find.text(_vi.photoLibraryDeleteErrorBody), findsNothing);
    expect(library.photos.map((p) => p.id), [1, 2]);
    expect(find.byType(DeletePhotoDialog), findsNothing);
  });
}
