import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/data/repositories/backup/backup_repository.dart';
import 'package:glimmer_app/data/repositories/device/device_repository.dart';
import 'package:glimmer_app/data/repositories/photo/photo_repository.dart';
import 'package:glimmer_app/data/repositories/photo/photo_repository_local.dart';
import 'package:glimmer_app/data/repositories/release/release_repository.dart';
import 'package:glimmer_app/data/repositories/skill/skill_repository.dart';
import 'package:glimmer_app/data/repositories/skill/skill_repository_local.dart';
import 'package:glimmer_app/domain/use_cases/control_device_use_case.dart';
import 'package:glimmer_app/domain/use_cases/delete_photo_use_case.dart';
import 'package:glimmer_app/domain/use_cases/load_photos_use_case.dart';
import 'package:glimmer_app/domain/use_cases/send_photo_use_case.dart';
import 'package:glimmer_app/domain/use_cases/toggle_skill_use_case.dart';
import 'package:glimmer_app/l10n/app_localizations.dart';
import 'package:glimmer_app/routing/polling_lifecycle.dart';
import 'package:glimmer_app/routing/router.dart';
import 'package:glimmer_app/routing/routes.dart';
import 'package:glimmer_app/routing/screens.dart';
import 'package:glimmer_app/ui/core/labels.dart';
import 'package:glimmer_app/ui/core/themes/app_theme.dart';
import 'package:glimmer_app/ui/core/widgets/dock_tab_bar.dart';
import 'package:glimmer_app/ui/device/view_models/device_view_model.dart';
import 'package:glimmer_app/ui/device/widgets/device_screen.dart';
import 'package:glimmer_app/ui/wifi_setup/view_models/wifi_setup_view_model.dart';
import 'package:glimmer_app/ui/wifi_setup/widgets/wifi_setup_screen.dart';
import 'package:provider/provider.dart';

import '../../testing/fakes/fake_repositories.dart';
import '../../testing/fakes/fake_services.dart';

const _url = 'http://192.168.1.50';
final _vi = lookupAppLocalizations(const Locale('vi'));

Map<String, dynamic> _state({bool key = true, bool stale = false, String wifi = 'connected', List<Object> projects = const []}) => {
      'fw': '1.0',
      'wifi': wifi,
      'ip': wifi == 'ap' ? '192.168.4.1' : '192.168.1.50',
      'ssid': 'Nha-2G',
      'rssi': -58,
      'time': 1795500000,
      'claude_configured': key,
      'claude_usage': {'weekly_used': 66, 'session_used': 12, 'last_ok': 1795500000 - 1500, 'stale': stale, 'cred': 'ok'},
      'projects': projects,
    };

/// Set in setUp: skills of the app, over [rig].
late ToggleSkillUseCase _toggle;

Widget _app(DeviceRig rig, Widget home, {FakeReleaseRepository? releases, FakeBackupRepository? backups}) =>
    MultiProvider(
      providers: [
        ChangeNotifierProvider<DeviceRepository>.value(value: rig.repo),
        Provider<ToggleSkillUseCase>.value(value: _toggle),
        Provider<ReleaseRepository>.value(value: releases ?? FakeReleaseRepository()),
        Provider<BackupRepository>.value(value: backups ?? FakeBackupRepository()),
        ...photoProviders(rig),
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
        home: Scaffold(body: home),
      ),
    );

/// Skill Ảnh over [rig] with in-memory copies and picker.
List<Provider<Object>> photoProviders(DeviceRig rig) {
  final photos = PhotoRepositoryLocal(store: FakePhotoStoreService(), picker: FakePhotoPickerService());
  return [
    Provider<PhotoRepository>.value(value: photos),
    Provider<LoadPhotosUseCase>.value(value: LoadPhotosUseCase(device: rig.repo, photos: photos)),
    Provider<DeletePhotoUseCase>.value(value: DeletePhotoUseCase(device: rig.repo, photos: photos)),
    Provider<SendPhotoUseCase>.value(value: SendPhotoUseCase(device: rig.repo, photos: photos)),
  ];
}

/// Clawd and progress indicators animate forever — pump a few frames instead of settling.
Future<void> _frames(WidgetTester t) async {
  for (var i = 0; i < 5; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  late DeviceRig rig;
  setUp(() async {
    rig = await DeviceRig.create();
    _toggle = ToggleSkillUseCase(skills: SkillRepositoryLocal(store: await fakeStore()), device: rig.repo);
  });
  tearDown(() => rig.repo.dispose());

  group('Kết nối', () {
    testWidgets('not found: sleeping title, error body, buttons enabled; manual dialog', (t) async {
      await t.runAsync(() => rig.repo.discover());
      await t.pumpWidget(_app(rig, connectScreen(onNewDevice: () {})));
      await _frames(t);
      expect(find.text(_vi.connectIdleTitle), findsOneWidget);
      expect(find.text(_vi.connectNotFound), findsOneWidget);
      await t.tap(find.text(_vi.connectManual));
      await _frames(t);
      expect(find.text(_vi.connectManualTitle), findsOneWidget);
      expect(find.text(_vi.connectManualIp), findsOneWidget);
    });
  });

  group('Tổng quan', () {
    testWidgets('loading while there is no state yet', (t) async {
      await t.pumpWidget(_app(rig, dashboardScreen(onBack: () {}, onOpenSettings: () {}, onCropPhoto: (_) async {})));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('normal: usage title, week %, board rows', (t) async {
      await t.runAsync(() => rig.connect(_url, _state(projects: [
            {'project': 'glimmer', 'agent': 'claude', 'state': 'approval', 'detail': 'Bash', 'shown': true},
          ])));
      await t.pumpWidget(_app(rig, dashboardScreen(onBack: () {}, onOpenSettings: () {}, onCropPhoto: (_) async {})));
      await _frames(t);
      expect(find.text(_vi.dashboardUsageTitle), findsOneWidget);
      expect(find.text('66'), findsOneWidget);
      expect(find.text('glimmer'), findsWidgets);
      expect(find.text('${_vi.stateApproval} · Bash'), findsOneWidget);
    });

    testWidgets('empty: no key, empty board text', (t) async {
      await t.runAsync(() => rig.connect(_url, _state(key: false)));
      await t.pumpWidget(_app(rig, dashboardScreen(onBack: () {}, onOpenSettings: () {}, onCropPhoto: (_) async {})));
      await _frames(t);
      expect(find.text(_vi.dashboardUsageNoKey), findsOneWidget);
      expect(find.text(_vi.dashboardProjectsEmpty), findsOneWidget);
    });

    testWidgets('R-DUNG-2 stale: "số liệu cũ (25m trước)"', (t) async {
      await t.runAsync(() => rig.connect(_url, _state(stale: true)));
      await t.pumpWidget(_app(rig, dashboardScreen(onBack: () {}, onOpenSettings: () {}, onCropPhoto: (_) async {})));
      await _frames(t);
      expect(find.text(_vi.dashboardUsageStale('25m')), findsOneWidget);
    });

    testWidgets('setup mode: amber note (the header line went with the Số liệu top bar)', (t) async {
      await t.runAsync(() => rig.connect(DeviceRepository.setupApUrl, _state(wifi: 'ap')));
      await t.pumpWidget(_app(rig, dashboardScreen(onBack: () {}, onOpenSettings: () {}, onCropPhoto: (_) async {})));
      await _frames(t);
      expect(find.text(_vi.dashboardSetupNote), findsOneWidget);
      expect(find.text(_vi.detailsTitle), findsOneWidget);
    });
  });

  group('Màn hình theo tab dock', () {
    Map<String, dynamic> dock({List<String> on = const ['agent', 'weather', 'clock'], bool located = true}) => {
          ..._state(),
          'skills': ['agent', 'weather', 'clock'],
          'skills_on': on,
          'weather_configured': located,
          if (located)
            'weather': {
              'valid': true,
              'temp_c': 29.2,
              'feels_c': 33,
              'desc': 'Ít mây',
              'last_ok': 1795500000 - 600,
              'days': [
                {'tmin': 24, 'tmax': 31, 'desc': 'Ít mây'},
                {'tmin': 25, 'tmax': 30, 'desc': 'Mưa rào'},
                {'tmin': 25, 'tmax': 32, 'desc': 'Nắng'},
                {'tmin': 24, 'tmax': 31, 'desc': 'Nhiều mây'},
              ],
            },
        };

    Future<void> open(WidgetTester t, Map<String, dynamic> state, {VoidCallback? onOpenSettings}) async {
      rig.api.device(_url, state);
      rig.api.on(_url, 'GET', '/push', {
        'cards': [
          {'id': 'a', 'kind': 'approval', 'title': 'APPROVAL NEEDED'},
          {'id': 'b', 'kind': 'input', 'title': 'YOUR TURN'},
          {'id': 'c', 'kind': 'input', 'title': 'YOUR TURN', 'shows_in_s': 40},
        ],
      });
      rig.api.on(_url, 'GET', '/api/settings',
          {'tzMinutes': 420, 'clock24h': true, 'nightMode': 1, 'nightStartMin': 1380, 'nightEndMin': 420});
      rig.api.on(_url, 'POST', '/api/channel', <String, dynamic>{});
      await t.runAsync(() async {
        await rig.repo.connectTo(_url);
        await rig.repo.refresh();
      });
      await t.pumpWidget(_app(rig, dashboardScreen(onBack: () {}, onOpenSettings: onOpenSettings ?? () {}, onCropPhoto: (_) async {})));
      await _frames(t);
    }

    testWidgets('agent: tab bar with the waiting badge, one show-on-device button → Claude', (t) async {
      await open(t, dock());
      expect(find.byType(DockTabBar), findsOneWidget);
      expect(find.text(_vi.skillWeatherName), findsOneWidget);
      expect(find.text('2'), findsOneWidget, reason: 'approval + input showing; the hidden one is not counted');
      expect(find.text(_vi.dashboardUsageTitle), findsOneWidget);
      expect(find.text(_vi.dashboardRefreshNow), findsNothing);
      expect(find.byTooltip(_vi.dashboardRefreshNow), findsOneWidget);
      await t.scrollUntilVisible(find.text(_vi.homeShowOnDevice(_vi.skillAgentName)), 200);
      await t.tap(find.text(_vi.homeShowOnDevice(_vi.skillAgentName)));
      await _frames(t);
      expect(rig.posts('/api/channel').last.body, {'name': 'Claude'});
    });

    testWidgets('weather: now, hi/lo, MAI / KIA / weekday rows, button → Weather', (t) async {
      await open(t, dock());
      await t.tap(find.text(_vi.skillWeatherName));
      await _frames(t);
      expect(find.text(_vi.weatherTitle), findsOneWidget);
      expect(find.text('29°'), findsOneWidget);
      expect(find.text(_vi.weatherHiLo('31', '24')), findsOneWidget);
      expect(find.text(_vi.weatherFeels('33')), findsOneWidget);
      expect(find.text(_vi.ago(600)), findsOneWidget);
      for (final day in [_vi.weatherDayTomorrow, _vi.weatherDayAfter, _vi.devWeekdayShort('5')]) {
        expect(find.text(day), findsOneWidget, reason: day);
      }
      expect(find.text(_vi.dashboardUsageTitle), findsNothing);
      await t.tap(find.text(_vi.homeShowOnDevice(_vi.skillWeatherName)));
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      expect(rig.posts('/api/channel').last.body, {'name': 'Weather'});
    });

    testWidgets('weatherNoLoc: amber meta, set-location button opens Cài đặt, no show button', (t) async {
      var opened = 0;
      await open(t, dock(located: false), onOpenSettings: () => opened++);
      await t.tap(find.text(_vi.skillWeatherName));
      await _frames(t);
      expect(find.text(_vi.weatherNoLocationMeta), findsOneWidget);
      expect(find.text(_vi.weatherNoLocationTitle), findsOneWidget);
      expect(find.text(_vi.homeShowOnDevice(_vi.skillWeatherName)), findsNothing);
      await t.tap(find.text(_vi.weatherSetLocation));
      expect(opened, 1);
    });

    testWidgets('clock: device time in its zone, format and night rows', (t) async {
      await open(t, dock());
      await t.tap(find.text(_vi.skillClockName));
      await _frames(t);
      expect(find.text(_vi.clockTitle), findsOneWidget);
      expect(find.text('13:00', findRichText: true), findsOneWidget);
      expect(find.text(_vi.clockDate(_vi.devWeekdayLong('2'), '24/11', '48')), findsOneWidget);
      expect(find.text('UTC+7'), findsOneWidget);
      expect(find.text(_vi.clockFormat24), findsOneWidget);
      expect(find.text(_vi.clockNightValue('23:00', '07:00', _vi.devClockNightDim)), findsOneWidget);
      await t.pumpWidget(const SizedBox()); // stop the clock ticker
    });

    testWidgets('single: one skill on → no tab bar, its body only', (t) async {
      await open(t, dock(on: ['clock']));
      expect(find.byType(DockTabBar), findsNothing);
      expect(find.text(_vi.clockTitle), findsOneWidget);
      expect(find.text(_vi.homeShowOnDevice(_vi.skillClockName)), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    });
  });

  group('Cài đặt', () {
    testWidgets('error: message + retry', (t) async {
      await t.runAsync(() => rig.connect(_url, _state()));
      await t.pumpWidget(_app(rig, settingsScreen(onOpenWeatherLocation: () async {})));
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await _frames(t);
      expect(find.text(_vi.devErrUnreachable('TimeoutException')), findsOneWidget);
      expect(find.text(_vi.commonRetry), findsOneWidget);
    });

    testWidgets('R-CD-1 R-CD-3 a change shows the save bar; night rows follow the mode', (t) async {
      await t.runAsync(() => rig.connect(_url, _state()));
      rig.api.on(_url, 'GET', '/api/settings', {'brightness': 60, 'nightMode': 2, 'idleDim': false});
      await t.pumpWidget(_app(rig, settingsScreen(onOpenWeatherLocation: () async {})));
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await _frames(t);
      expect(find.text(_vi.devSliderValue(_vi.settingsBrightness, 60)), findsOneWidget);
      expect(find.text(_vi.settingsNightFrom), findsOneWidget);
      expect(find.text(_vi.settingsNightBright), findsNothing, reason: 'only for Giảm sáng');
      expect(find.text(_vi.settingsDiscard), findsNothing);
      await t.tap(find.text(_vi.settingsIdleDim));
      await _frames(t);
      expect(find.text(_vi.settingsSaveCount('1')), findsOneWidget);
      expect(find.text(_vi.settingsDiscard), findsOneWidget);
    });
  });

  group('Thiết bị', () {
    testWidgets('normal: info rows with the Wi-Fi line', (t) async {
      await t.runAsync(() => rig.connect(_url, _state()));
      await t.pumpWidget(_app(rig, deviceScreen(onChangeWifi: () {})));
      await _frames(t);
      expect(find.text(_vi.deviceInfo), findsOneWidget);
      expect(find.text(_vi.devWifiRssi('Nha-2G', -58)), findsOneWidget);
    });

    testWidgets('R-TB-4 busy: progress card, every action row disabled', (t) async {
      await t.runAsync(() => rig.connect(_url, _state()));
      final vm = _BusyDeviceViewModel(rig);
      await t.pumpWidget(_app(rig, DeviceScreen(viewModel: vm, onChangeWifi: () {})));
      await _frames(t);
      expect(find.text(_vi.deviceStepFlashFw), findsOneWidget);
      expect(find.text(_vi.deviceBusyNote), findsOneWidget);
      final tiles = t.widgetList<ListTile>(find.byType(ListTile));
      expect(tiles, isNotEmpty);
      expect(tiles.every((x) => x.enabled == false), isTrue);
    });
  });

  group('Cài Wi-Fi', () {
    Future<WifiSetupViewModel> pump(WidgetTester t) async {
      final vm = WifiSetupViewModel(device: rig.repo, findAttempts: 1);
      await t.pumpWidget(_app(rig, WifiSetupScreen(viewModel: vm)));
      await _frames(t);
      return vm;
    }

    testWidgets('form: note, fields, send', (t) async {
      await pump(t);
      expect(find.text(_vi.wifiNote), findsOneWidget);
      expect(find.text(_vi.wifiSsid), findsOneWidget);
      expect(find.text(_vi.wifiSend), findsOneWidget);
    });

    testWidgets('failed: "Chưa xong", the reason, retry back to the form', (t) async {
      rig.wifi.permissions = false;
      final vm = await pump(t);
      await t.runAsync(() => vm.send('Nha', ''));
      await _frames(t);
      expect(find.text(_vi.wifiFailed), findsOneWidget);
      expect(find.text(_vi.devErrWifiPermission), findsOneWidget);
      await t.tap(find.text(_vi.commonRetry));
      await _frames(t);
      expect(find.text(_vi.wifiSend), findsOneWidget);
    });

    testWidgets('done: "Xong! …" and the IP', (t) async {
      await t.runAsync(() => rig.connect(_url, _state()));
      final vm = await pump(t);
      await t.runAsync(() => vm.send('Nha', 'pw'));
      await _frames(t);
      expect(find.text(_vi.wifiDone('Nha')), findsOneWidget);
      expect(find.text(_vi.wifiDoneDetail('192.168.1.50')), findsOneWidget);
    });
  });

  group('Điều hướng', () {
    test('R-KN-3 redirect: Kết nối until connected, then the tabs; Cài Wi-Fi always allowed', () {
      expect(redirectFor(false, Routes.dashboard), Routes.connect);
      expect(redirectFor(false, Routes.connect), isNull);
      expect(redirectFor(true, Routes.connect), Routes.control);
      expect(redirectFor(true, Routes.settings), isNull);
      expect(redirectFor(false, Routes.deviceWifi), isNull);
      expect(redirectFor(true, Routes.connectWifi), isNull);
    });

    testWidgets('R-KN-3 connecting shows the tabs; forgetting goes back to Kết nối', (t) async {
      final router = buildRouter(rig.repo);
      final skills = SkillRepositoryLocal(store: (await t.runAsync(fakeStore))!);
      await t.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<DeviceRepository>.value(value: rig.repo),
          Provider<ReleaseRepository>.value(value: FakeReleaseRepository()),
          Provider<BackupRepository>.value(value: FakeBackupRepository()),
          ChangeNotifierProvider<SkillRepository>.value(value: skills),
          Provider<ToggleSkillUseCase>.value(value: ToggleSkillUseCase(skills: skills, device: rig.repo)),
          Provider<ControlDeviceUseCase>.value(value: ControlDeviceUseCase(device: rig.repo)),
          ...photoProviders(rig),
        ],
        child: MaterialApp.router(
          locale: const Locale('vi'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: router,
        ),
      ));
      await _frames(t);
      expect(find.text(_vi.connectRetry), findsOneWidget);
      await t.runAsync(() => rig.connect(_url, _state()));
      await _frames(t);
      // 4 tabs, opened on tab 1 = Điều khiển.
      expect(find.text(_vi.navControl), findsOneWidget);
      expect(find.text(_vi.navSkills), findsOneWidget);
      expect(find.byTooltip(_vi.controlRefreshA11y), findsOneWidget);
      rig.repo.forget();
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.text(_vi.connectRetry), findsOneWidget);
      router.dispose();
    });

    testWidgets('R-KN-2 polling stops in the background and resumes with a refresh', (t) async {
      await t.runAsync(() => rig.connect(_url, _state()));
      await t.pumpWidget(PollingLifecycle(device: rig.repo, child: const SizedBox()));
      final before = rig.api.calls.length;
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      expect(rig.api.calls.skip(before).where((c) => c.path == '/api/state'), isNotEmpty);
      rig.repo.stopPolling();
    });
  });
}

/// A Device ViewModel frozen mid-flash.
class _BusyDeviceViewModel extends DeviceViewModel {
  _BusyDeviceViewModel(DeviceRig rig)
      : super(device: rig.repo, releases: FakeReleaseRepository(), backups: FakeBackupRepository());

  @override
  DeviceStep? get step => DeviceStep.flashFw;

  @override
  bool get busy => true;

  @override
  double? get progress => 0.4;
}
