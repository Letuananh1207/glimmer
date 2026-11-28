import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/data/repositories/device/device_repository.dart';
import 'package:glimmer_app/data/services/device_api_service.dart';
import 'package:glimmer_app/domain/models/app_error.dart';
import 'package:glimmer_app/domain/models/clawd_mood.dart';
import 'package:glimmer_app/domain/models/config_backup.dart';
import 'package:glimmer_app/domain/models/usage_meta.dart';
import 'package:glimmer_app/ui/connect/view_models/connect_view_model.dart';
import 'package:glimmer_app/ui/dashboard/view_models/dashboard_view_model.dart';
import 'package:glimmer_app/ui/device/view_models/device_view_model.dart';
import 'package:glimmer_app/ui/settings/view_models/settings_view_model.dart';
import 'package:glimmer_app/ui/wifi_setup/view_models/wifi_setup_view_model.dart';
import 'package:glimmer_app/utils/result.dart';

import 'package:glimmer_app/data/repositories/skill/skill_repository_local.dart';
import 'package:glimmer_app/data/repositories/wifi/wifi_password_repository_local.dart';
import 'package:glimmer_app/domain/use_cases/toggle_skill_use_case.dart';

import '../../testing/fakes/fake_repositories.dart';
import '../../testing/fakes/fake_services.dart';

const _url = 'http://192.168.1.50';
const _now = 1795500000;

Map<String, dynamic> _state({bool stale = false, String wifi = 'connected', String build = 'Nov 25 2026 10:00:00'}) => {
      'fw': '1.0',
      'wifi': wifi,
      'ip': '192.168.1.50',
      'ssid': 'Nha',
      'build': build,
      'time': _now,
      'claude_configured': true,
      'claude_usage': {
        'weekly_used': 66,
        'session_used': 12,
        'weekly_reset': _now + 3 * 86400,
        'session_reset': 0,
        'last_ok': _now - 60,
        'stale': stale,
        'cred': 'ok',
      },
      'projects': [
        {'project': 'a', 'state': 'done', 'shown': true},
        {'project': 'b', 'state': 'working', 'shown': true},
      ],
    };

Future<DashboardViewModel> _dashboard(DeviceRig rig) async => DashboardViewModel(
      device: rig.repo,
      toggleSkill: ToggleSkillUseCase(skills: SkillRepositoryLocal(store: await fakeStore()), device: rig.repo),
    );

WifiPasswordRepositoryLocal _pw([Map<String, String> saved = const {}]) =>
    WifiPasswordRepositoryLocal(FakeWifiSecretsService(saved), saved);

void main() {
  late DeviceRig rig;
  setUp(() async => rig = await DeviceRig.create());
  tearDown(() => rig.repo.dispose());

  group('Connect', () {
    test('prefills the last address without http:// and connects with the typed token', () async {
      rig = await DeviceRig.create(saved: {'device_url': _url, 'token': 't0'});
      final vm = ConnectViewModel(device: rig.repo);
      expect((vm.savedAddress, vm.savedToken), ('192.168.1.50', 't0'));
      rig.api.device(_url);
      await vm.connect('192.168.1.50', 'tok');
      expect(rig.repo.connected, isTrue);
      expect(rig.api.calls.last.token, 'tok');
      vm.dispose();
    });

    test('a failed search leaves the error for the screen', () async {
      final vm = ConnectViewModel(device: rig.repo);
      await vm.retry();
      expect(vm.error!.kind, AppErrorKind.notFound);
      expect(vm.searching, isFalse);
      vm.dispose();
    });
  });

  group('Dashboard', () {
    test('rows, mood and usage rows come from the device state', () async {
      await rig.connect(_url, _state());
      final vm = await _dashboard(rig);
      expect(vm.rows.map((p) => p.project), ['b', 'a']);
      expect((vm.mood, vm.walking), (ClawdMood.open, true));
      expect((vm.week.used, vm.week.level, vm.week.resetInS), (66, UsageLevel.low, 3 * 86400));
      expect(vm.session.resetInS, isNull);
      expect((vm.meta.kind, vm.meta.ageS), (UsageMetaKind.fresh, 60));
      vm.dispose();
    });

    test('R-DUNG-4 stale data dims both rows', () async {
      await rig.connect(_url, _state(stale: true));
      final vm = await _dashboard(rig);
      expect((vm.week.level, vm.session.level), (UsageLevel.unknown, UsageLevel.unknown));
      expect(vm.meta.kind, UsageMetaKind.stale);
      vm.dispose();
    });

    test('actions post to the device and refresh on success', () async {
      await rig.connect(_url, _state());
      rig.api.on(_url, 'POST', '/push/clear', <String, dynamic>{});
      final vm = await _dashboard(rig);
      final before = rig.api.calls.length;
      expect(await vm.clearCard('k1'), isA<Ok<void>>());
      expect(rig.posts('/push/clear').last.body, {'id': 'k1'});
      expect(rig.api.calls.skip(before).any((c) => c.path == '/api/state'), isTrue);
      expect(await vm.refreshNow(), isA<Error<void>>(), reason: '/api/refresh does not answer');
      vm.dispose();
    });
  });

  group('Settings', () {
    Future<SettingsViewModel> loaded() async {
      await rig.connect(_url);
      rig.api.on(_url, 'GET', '/api/settings', {'brightness': 60, 'nightMode': 0, 'claudeKey': '***', 'apiToken': ''});
      rig.api.on(_url, 'POST', '/api/settings', <String, dynamic>{});
      final vm = SettingsViewModel(device: rig.repo);
      await vm.load();
      return vm;
    }

    test('R-CD-1 only changed keys are sent; back to the old value is no change', () async {
      final vm = await loaded();
      vm.set('brightness', 80);
      vm.set('nightMode', 2);
      expect(vm.changeCount, 2);
      vm.set('brightness', 60);
      expect(vm.changeCount, 1);
      expect(await vm.save(), isA<Ok<void>>());
      expect(rig.posts('/api/settings').single.body, {'nightMode': 2});
      vm.dispose();
    });

    test('R-CD-2 secrets: set / unset / pending, sent only when typed', () async {
      final vm = await loaded();
      expect((vm.secret('claudeKey'), vm.secret('apiToken')), (SecretState.set, SecretState.unset));
      vm.set('claudeKey', 'sk-ant-new');
      expect(vm.secret('claudeKey'), SecretState.pending);
      await vm.save();
      expect(rig.posts('/api/settings').single.body, {'claudeKey': 'sk-ant-new'});
      vm.dispose();
    });

    test('R-CD-3 night mode drives which night rows exist', () async {
      final vm = await loaded();
      expect(vm.nightMode, 0);
      vm.set('nightMode', 1);
      expect(vm.nightMode, 1);
      vm.dispose();
    });

    test('a load failure is kept for the retry screen', () async {
      await rig.connect(_url);
      final vm = SettingsViewModel(device: rig.repo);
      await vm.load();
      expect((vm.loaded, vm.loadError!.kind), (false, AppErrorKind.unreachable));
      vm.dispose();
    });
  });

  group('Wi-Fi setup', () {
    test('R-WF-1 reachable device → sent directly, no setup AP', () async {
      await rig.connect(_url);
      final vm = WifiSetupViewModel(device: rig.repo, passwords: _pw(), findAttempts: 2);
      await vm.send(' Nha ', 'pw');
      expect(rig.wifi.joined, isEmpty);
      expect(rig.posts('/api/settings').single.url, _url);
      expect(rig.posts('/api/settings').single.body, {'wifiSSID': 'Nha', 'wifiPass': 'pw', '_restart': true});
      expect((vm.step, vm.status), (WifiStep.done, WifiStatus.done));
      vm.dispose();
    });

    test('R-WF-1 device in setup mode → through glimmer-setup, then leaves it', () async {
      await rig.connect(DeviceRepository.setupApUrl, _state(wifi: 'ap'));
      final vm = WifiSetupViewModel(device: rig.repo, passwords: _pw(), findAttempts: 2);
      await vm.send('Nha', '');
      expect(rig.wifi.joined, [DeviceRepository.setupApSsid]);
      expect(rig.posts('/api/settings').single.url, DeviceRepository.setupApUrl);
      expect(rig.wifi.left, 1);
      vm.dispose();
    });

    test('R-WF-1 no permission → failed with wifiPermission', () async {
      rig.wifi.permissions = false;
      final vm = WifiSetupViewModel(device: rig.repo, passwords: _pw());
      await vm.send('Nha', '');
      expect((vm.step, vm.error!.kind), (WifiStep.failed, AppErrorKind.wifiPermission));
      vm.dispose();
    });

    test('R-WF-1 not answering now → through glimmer-setup; no AP there → setupAp', () async {
      await rig.connect(_url);
      final vm = WifiSetupViewModel(device: rig.repo, passwords: _pw(), findAttempts: 2);
      rig.api.on(_url, 'POST', '/api/settings', <String, dynamic>{});
      // After the save the device leaves this network.
      rig.api.answers.remove('$_url GET /api/state');
      rig.api.answers['$_url GET /api/state'] = const DeviceHttpException(0);
      await vm.send('Nha-5G', '');
      expect(vm.step, WifiStep.failed);
      expect((vm.error!.kind, vm.error!.detail), (AppErrorKind.setupAp, ''),
          reason: 'not answering now → goes through glimmer-setup, which is not there either');
      vm.dispose();
    });

    test('R-WF-3 sent, but the display never shows up → notOnNetwork', () async {
      await rig.connect(_url);
      rig.api.on(_url, 'POST', '/api/settings', <String, dynamic>{});
      final vm = WifiSetupViewModel(device: rig.repo, passwords: _pw(), findAttempts: 2);
      rig.api.onCall = (c) {
        if (c.path == '/api/settings') rig.api.gone(_url);
      };
      await vm.send('Nha-5G', '');
      expect((vm.error!.kind, vm.error!.detail), (AppErrorKind.notOnNetwork, 'Nha-5G'));
      vm.dispose();
    });

    test('R-WF-3 prefills the phone SSID, but not glimmer-setup', () async {
      rig.wifi.ssid = 'Nha';
      final vm = WifiSetupViewModel(device: rig.repo, passwords: _pw());
      await vm.prefill();
      expect(vm.suggestedSsid, 'Nha');
      rig.wifi.ssid = DeviceRepository.setupApSsid;
      final vm2 = WifiSetupViewModel(device: rig.repo, passwords: _pw());
      await vm2.prefill();
      expect(vm2.suggestedSsid, isNull);
      vm.dispose();
      vm2.dispose();
    });

    test("R-WF-4 a QR that is not glimmer's → notGlimmerQr, nothing joined or sent", () async {
      await rig.connect(_url);
      final vm = WifiSetupViewModel(device: rig.repo, passwords: _pw({'Nha': 'pw'}));
      rig.wifi.ssid = 'Nha';
      await vm.scanned('WIFI:T:WPA;S:CafeABC;P:123;;');
      expect((vm.step, vm.error!.kind), (WifiStep.failed, AppErrorKind.notGlimmerQr));
      expect(rig.wifi.joined, isEmpty);
      expect(rig.posts('/api/settings'), isEmpty);
      vm.dispose();
    });

    test('R-WF-4 scanned, no password remembered → asks only the password, then joins the AP from the QR', () async {
      await rig.connect(DeviceRepository.setupApUrl, _state(wifi: 'ap'));
      rig.wifi.ssid = 'Nha';
      final vm = WifiSetupViewModel(device: rig.repo, passwords: _pw(), findAttempts: 1);
      await vm.scanned('WIFI:T:nopass;S:glimmer-setup-2;;');
      expect((vm.step, vm.ssid), (WifiStep.password, 'Nha'));
      expect(rig.wifi.joined, isEmpty);
      await vm.send(vm.ssid, 'pw');
      expect(rig.wifi.joined, ['glimmer-setup-2']);
      expect(rig.posts('/api/settings').single.body, {'wifiSSID': 'Nha', 'wifiPass': 'pw', '_restart': true});
      vm.dispose();
    });

    test("R-WF-4 scanned while the phone's Wi-Fi is unknown → the full form", () async {
      rig.wifi.ssid = null;
      final vm = WifiSetupViewModel(device: rig.repo, passwords: _pw({'Nha': 'pw'}));
      await vm.scanned('WIFI:T:nopass;S:glimmer-setup;;');
      expect((vm.step, vm.error), (WifiStep.form, null));
      vm.dispose();
    });

    test('R-WF-5 scanned, password remembered → sent at once without asking', () async {
      await rig.connect(_url);
      rig.wifi.ssid = 'Nha';
      final vm = WifiSetupViewModel(device: rig.repo, passwords: _pw({'Nha': 'pw'}), findAttempts: 2);
      await vm.scanned('WIFI:T:nopass;S:glimmer-setup;;');
      expect(rig.posts('/api/settings').single.body, {'wifiSSID': 'Nha', 'wifiPass': 'pw', '_restart': true});
      expect(vm.step, WifiStep.done);
      vm.dispose();
    });

    test('R-WF-5 remembered only once the display shows up on the network', () async {
      await rig.connect(_url);
      final secrets = FakeWifiSecretsService();
      final pw = WifiPasswordRepositoryLocal(secrets, {});
      final vm = WifiSetupViewModel(device: rig.repo, passwords: pw, findAttempts: 2);
      await vm.send('Nha', 'pw');
      expect((vm.rememberedPassword('Nha'), secrets.stored['Nha']), ('pw', 'pw'));
      vm.dispose();
    });

    for (final remembered in [false, true]) {
      test('R-WF-5 display never shows up → ${remembered ? 'the remembered password is forgotten' : 'not remembered'}',
          () async {
        await rig.connect(_url);
        rig.api.on(_url, 'POST', '/api/settings', <String, dynamic>{});
        rig.api.onCall = (c) {
          if (c.path == '/api/settings') rig.api.gone(_url);
        };
        final vm = WifiSetupViewModel(
            device: rig.repo, passwords: _pw(remembered ? {'Nha-5G': 'old'} : {}), findAttempts: 2);
        await vm.send('Nha-5G', remembered ? 'old' : 'sai', remembered: remembered);
        expect((vm.error!.kind, vm.rememberedPassword('Nha-5G')), (AppErrorKind.notOnNetwork, null));
        vm.dispose();
      });
    }
  });

  group('Device', () {
    late FakeReleaseRepository releases;
    late FakeBackupRepository backups;
    DeviceViewModel make() => DeviceViewModel(
        device: rig.repo, releases: releases, backups: backups, restoreAttempts: 2, toSetupApWait: Duration.zero);
    setUp(() {
      releases = FakeReleaseRepository();
      backups = FakeBackupRepository();
    });

    test('release check → updateAvailable by R-TB-1', () async {
      await rig.connect(_url, _state(build: 'Nov 25 2026 10:00:00'));
      final vm = make();
      await vm.checkRelease();
      expect(vm.updateAvailable, isTrue);
      vm.dispose();
    });

    test('R-TB-2 an invalid backup file → a notice, nothing sent', () async {
      await rig.connect(_url);
      backups.pickAnswer = FakeBackupRepository.invalid();
      final vm = make();
      expect(await vm.pickBackup(), isNull);
      expect(vm.takeNotices().single.kind, DeviceNoticeKind.invalidBackup);
      expect(rig.posts(), isEmpty);
      vm.dispose();
    });

    test('restore to a reachable device: import, wait, found again → restoreDone', () async {
      await rig.connect(_url);
      final vm = make();
      await vm.restore(const ConfigBackup('b.json', {'wifi_ssid': 'Nha'}));
      expect(rig.posts('/api/import').single.body, {'wifi_ssid': 'Nha'});
      expect(vm.takeNotices().single.kind, DeviceNoticeKind.restoreDone);
      expect(rig.repo.connected, isTrue);
      expect(vm.busy, isFalse);
      vm.dispose();
    });

    test('R-TB-3 full update: backup, both downloads, firmware, wait, filesystem, restore', () async {
      await rig.connect(_url);
      rig.api.on(_url, 'GET', '/api/export', {'wifi_ssid': 'Nha'});
      final vm = make();
      await vm.checkRelease();
      final steps = <DeviceStep?>[];
      vm.addListener(() => steps.add(vm.step));
      await vm.updateFull();
      expect(backups.saved.single, {'wifi_ssid': 'Nha'});
      expect(releases.downloaded, ['firmware.bin', 'littlefs.bin']);
      expect(rig.api.calls.where((c) => c.method == 'UPLOAD').map((c) => c.path), ['firmware', 'filesystem']);
      expect(rig.posts('/api/import').single.body, {'wifi_ssid': 'Nha'});
      expect(steps.whereType<DeviceStep>().toSet(),
          containsAll([DeviceStep.backup, DeviceStep.flashFw, DeviceStep.flashFs, DeviceStep.toSetupAp]));
      expect(vm.takeNotices().map((n) => n.kind), [DeviceNoticeKind.restoreDone]);
      vm.dispose();
    });

    test('R-TB-3 no config to back up → stops before flashing', () async {
      await rig.connect(_url);
      rig.api.on(_url, 'GET', '/api/export', {'a': 1});
      final vm = make();
      await vm.checkRelease();
      await vm.updateFull();
      expect(rig.api.calls.where((c) => c.method == 'UPLOAD'), isEmpty);
      final n = vm.takeNotices().single;
      expect((n.kind, n.error!.kind), (DeviceNoticeKind.updateFailed, AppErrorKind.configUnreadable));
      vm.dispose();
    });

    test('R-TB-4 busy while a long operation runs, idle after', () async {
      await rig.connect(_url);
      final vm = make();
      await vm.checkRelease();
      var sawBusy = false;
      vm.addListener(() => sawBusy |= vm.busy);
      await vm.updateFirmware();
      expect((sawBusy, vm.busy), (true, false));
      expect(vm.takeNotices().single.kind, DeviceNoticeKind.updateDone);
      vm.dispose();
    });

    test('a flow that outlives the screen does not throw after dispose', () async {
      await rig.connect(_url);
      final vm = make();
      await vm.checkRelease();
      final run = vm.updateFirmware();
      vm.dispose();
      await run;
    });
  });
}
