import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/data/repositories/device/device_repository.dart';
import 'package:glimmer_app/data/repositories/photo/photo_repository.dart';
import 'package:glimmer_app/data/repositories/photo/photo_repository_local.dart';
import 'package:glimmer_app/data/repositories/skill/skill_repository_local.dart';
import 'package:glimmer_app/domain/use_cases/delete_photo_use_case.dart';
import 'package:glimmer_app/domain/use_cases/load_photos_use_case.dart';
import 'package:glimmer_app/domain/use_cases/toggle_skill_use_case.dart';
import 'package:glimmer_app/l10n/app_localizations.dart';
import 'package:glimmer_app/routing/routes.dart';
import 'package:glimmer_app/routing/screens.dart';
import 'package:glimmer_app/ui/core/themes/app_text.dart';
import 'package:glimmer_app/ui/core/themes/app_theme.dart';
import 'package:glimmer_app/ui/core/widgets/dock_tab_bar.dart';
import 'package:glimmer_app/ui/dashboard/widgets/photo_dialogs.dart';
import 'package:provider/provider.dart';

import '../../../../testing/fakes/fake_repositories.dart';
import '../../../../testing/fakes/fake_services.dart';
import 'library_tab_test.dart' show libraryProviders;

const _url = 'http://192.168.1.50';
final _vi = lookupAppLocalizations(const Locale('vi'));

Map<String, dynamic> _state(List<String> on, {int photos = 0}) => {
      'fw': '0.24.0',
      'wifi': 'connected',
      'time': 1795500000,
      'skills': ['agent', 'photo', 'weather', 'clock'],
      'skills_on': on,
      'photos': photos,
    };

Map<String, dynamic> _list(int n) => {
      'photos': [
        for (var i = 1; i <= n; i++) {'name': 'p$i.jpg', 'size': 10 + i},
      ],
      'free': 300000,
      'max_count': 8,
      'max_bytes': 40960,
      'side': 188,
    };

void main() {
  late DeviceRig rig;
  late FakePhotoStoreService files;
  late FakePhotoPickerService picker;
  late List<PhotoCropArgs> cropped;

  setUp(() async {
    rig = await DeviceRig.create();
    files = FakePhotoStoreService();
    picker = FakePhotoPickerService();
    cropped = [];
  });
  tearDown(() => rig.repo.dispose());

  Future<void> frames(WidgetTester t) async {
    for (var i = 0; i < 5; i++) {
      await t.pump(const Duration(milliseconds: 50));
    }
  }

  /// Màn hình with skills [on]; device has [n] photos (copies of p1 for the thumbnail); opens the Ảnh tab.
  Future<void> open(WidgetTester t, {List<String> on = const ['agent', 'photo', 'weather', 'clock'], int n = 5, bool tab = true}) async {
    files.files['p1.jpg'] = Uint8List(11);
    rig.api.device(_url, _state(on, photos: n));
    rig.api.on(_url, 'GET', '/api/photos', _list(n));
    rig.api.on(_url, 'GET', '/api/settings', <String, dynamic>{});
    rig.api.on(_url, 'POST', '/api/channel', <String, dynamic>{});
    final skills = SkillRepositoryLocal(store: (await t.runAsync(fakeStore))!);
    await t.runAsync(() async {
      await rig.repo.connectTo(_url);
      await rig.repo.refresh();
    });
    final photos = PhotoRepositoryLocal(store: files, picker: picker);
    await t.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<DeviceRepository>.value(value: rig.repo),
        Provider<ToggleSkillUseCase>.value(value: ToggleSkillUseCase(skills: skills, device: rig.repo)),
        Provider<PhotoRepository>.value(value: photos),
        Provider<LoadPhotosUseCase>.value(value: LoadPhotosUseCase(device: rig.repo, photos: photos)),
        Provider<DeletePhotoUseCase>.value(value: DeletePhotoUseCase(device: rig.repo, photos: photos)),
        ...libraryProviders(rig, photos),
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
          body: dashboardScreen(onBack: () {}, onOpenSettings: () {}, onCropPhoto: (a) async {
            cropped.add(a);
            return null;
          }),
        ),
      ),
    ));
    await frames(t);
    if (tab) {
      await t.tap(find.text(_vi.skillPhotoName));
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await frames(t);
    }
  }

  group('R-SK-6 tab Ảnh chỉ có khi skill Ảnh bật', () {
    testWidgets('R-SK-6 Ảnh tắt → không có tab Ảnh; bật → tab Ảnh thứ 2', (t) async {
      await open(t, on: ['agent', 'weather', 'clock'], tab: false);
      expect(find.byType(DockTabBar), findsOneWidget);
      expect(find.text(_vi.skillPhotoName), findsNothing);
      await t.pumpWidget(const SizedBox());

      await open(t, tab: false);
      final labels = [_vi.skillAgentName, _vi.skillPhotoName, _vi.skillWeatherName, _vi.skillClockName];
      final xs = [for (final s in labels) t.getCenter(find.text(s)).dx];
      expect(xs, [...xs]..sort(), reason: 'dock order: Agent, Ảnh, Thời tiết, Đồng hồ');
    });
  });

  testWidgets('DockTabBar 4 tab: label under the icon, tab 56 high', (t) async {
    await open(t, tab: false);
    final tab = find.ancestor(of: find.text(_vi.skillPhotoName), matching: find.byType(InkWell));
    expect(t.getSize(tab).height, AppSize.dockTabStacked);
    final label = t.getRect(find.text(_vi.skillWeatherName));
    final inTab = find.ancestor(of: find.text(_vi.skillWeatherName), matching: find.byType(InkWell));
    final icon = t.getRect(find.descendant(of: inTab, matching: find.byType(CustomPaint)).first);
    expect(label.top >= icon.bottom, true, reason: 'stacked');
  });

  for (final on in [
    ['agent', 'weather', 'clock'],
    ['agent', 'photo'],
  ]) {
    testWidgets('DockTabBar ${on.length} tab: label right of the icon, tab 48 high', (t) async {
      await open(t, on: on, tab: false);
      for (final id in on) {
        final name = switch (id) {
          'agent' => _vi.skillAgentName,
          'photo' => _vi.skillPhotoName,
          'weather' => _vi.skillWeatherName,
          _ => _vi.skillClockName,
        };
        final inTab = find.ancestor(of: find.text(name), matching: find.byType(InkWell));
        expect(t.getSize(inTab).height, AppSize.dockTab, reason: id);
        final icon = t.getRect(find.descendant(of: inTab, matching: find.byType(CustomPaint)).first);
        final label = t.getRect(find.text(name));
        expect(label.left >= icon.right, true, reason: '$id: one row');
        expect((label.center.dy - icon.center.dy).abs() < 1, true, reason: '$id: centred on one line');
      }
    });
  }

  testWidgets('grid: meta "5/8 · còn 3 chỗ", one tile without copy shows its name, add tile, note, show → Photo',
      (t) async {
    await open(t);
    expect(find.text(_vi.photoOnDevice), findsOneWidget);
    expect(find.text(_vi.photoCount(5, 8, 3)), findsOneWidget);
    expect(find.text(_vi.photoNoPreview), findsNWidgets(4), reason: 'only p1 has a copy');
    expect(find.text('p2.jpg'), findsOneWidget);
    expect(find.bySemanticsLabel(_vi.photoTileA11y(1)), findsOneWidget);
    expect(find.text(_vi.photoAdd), findsOneWidget);
    expect(find.text(_vi.photoNote), findsOneWidget);
    await t.scrollUntilVisible(find.text(_vi.homeShowOnDevice(_vi.skillPhotoName)), 200,
        scrollable: find.byType(Scrollable).first);
    await t.tap(find.text(_vi.homeShowOnDevice(_vi.skillPhotoName)));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    expect(rig.posts('/api/channel').last.body, {'name': 'Photo'});
  });

  testWidgets('empty: "0/8", title, mint add button → source sheet → picked photo goes to PhotoCrop', (t) async {
    await open(t, n: 0);
    expect(find.text(_vi.photoCountEmpty(8)), findsOneWidget);
    expect(find.text(_vi.photoEmptyTitle), findsOneWidget);
    expect(find.text(_vi.photoEmptyBody(8)), findsOneWidget);
    expect(find.text(_vi.photoNote), findsNothing);
    await t.tap(find.text(_vi.photoAdd));
    await frames(t);
    expect(find.byType(PhotoSourceSheet), findsOneWidget);
    picker.next = Uint8List(3);
    await t.tap(find.text(_vi.photoFromCamera));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await frames(t);
    expect(picker.asked, [true]);
    expect(cropped.single.image, hasLength(3));
    expect(cropped.single.info.maxCount, 8);
  });

  testWidgets('full: amber "8/8 · hết chỗ", locked add tile, explanation', (t) async {
    await open(t, n: 8);
    expect(find.text(_vi.photoCountFull(8)), findsOneWidget);
    expect(find.text(_vi.photoFullTile(8)), findsOneWidget);
    expect(find.text(_vi.photoFullBody(8)), findsOneWidget);
    expect(find.text(_vi.photoAdd), findsNothing);
    await t.tap(find.text(_vi.photoFullTile(8)), warnIfMissed: false); // locked: nothing to hit
    await frames(t);
    expect(find.byType(PhotoSourceSheet), findsNothing);
  });

  testWidgets('delete: dialog → "Đang xoá" on the tile → error banner → retry', (t) async {
    await open(t);
    await t.tap(find.bySemanticsLabel(_vi.photoUnknownA11y('p2.jpg')));
    await frames(t);
    expect(find.text(_vi.photoDeleteTitle), findsOneWidget);
    expect(find.text(_vi.photoDeleteBody), findsOneWidget);
    rig.api.holdDeletes = Completer<void>();
    await t.tap(find.text(_vi.photoDelete));
    await frames(t);
    expect(find.text(_vi.photoDeleting), findsOneWidget);
    rig.api.holdDeletes!.complete(); // no DELETE answer → offline
    rig.api.holdDeletes = null;
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await frames(t);
    expect(find.text(_vi.photoDeleting), findsNothing);
    expect(find.text(_vi.photoDeleteErrorTitle), findsOneWidget);
    expect(find.text(_vi.photoDeleteErrorBody), findsOneWidget);
    rig.api.on(_url, 'DELETE', '/api/photos?name=p2.jpg', {'ok': true, 'count': 4});
    await t.tap(find.text(_vi.commonRetry));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await frames(t);
    expect(find.text(_vi.photoDeleteErrorTitle), findsNothing);
  });

  testWidgets('cancel in the dialog deletes nothing', (t) async {
    await open(t);
    await t.tap(find.bySemanticsLabel(_vi.photoUnknownA11y('p2.jpg')));
    await frames(t);
    await t.tap(find.text(_vi.commonCancel));
    await frames(t);
    expect(rig.api.calls.where((c) => c.method == 'DELETE'), isEmpty);
  });
}
