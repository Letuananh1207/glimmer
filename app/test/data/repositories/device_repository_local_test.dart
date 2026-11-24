import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/data/repositories/device/device_repository.dart';
import 'package:glimmer_app/data/repositories/device/device_repository_local.dart';
import 'package:glimmer_app/data/services/device_api_service.dart';
import 'package:glimmer_app/data/services/local_store_service.dart';
import 'package:glimmer_app/domain/models/app_error.dart';
import 'package:glimmer_app/utils/result.dart';

import '../../../testing/fakes/fake_services.dart';

void main() {
  late FakeDeviceApiService api;
  late FakeDiscoveryService nsd;
  late FakeWifiService wifi;
  late LocalStoreService store;
  late FakeDelay delay;
  late DeviceRepositoryLocal repo;

  Future<void> setUpRepo([Map<String, Object> saved = const {}]) async {
    api = FakeDeviceApiService();
    nsd = FakeDiscoveryService();
    wifi = FakeWifiService();
    delay = FakeDelay();
    store = await fakeStore(saved);
    repo = DeviceRepositoryLocal(
        api: api, discovery: nsd, store: store, wifi: wifi, delay: delay.call, pollEvery: const Duration(hours: 1));
  }

  tearDown(() => repo.dispose());

  group('R-KN-1 discovery order', () {
    test('saved address first, then NSD, glimmer.local, setup AP', () async {
      await setUpRepo({'device_url': 'http://10.0.0.9'});
      nsd.addresses = ['10.0.0.5'];
      api.device('http://glimmer.local');
      expect(await repo.discover(), isTrue);
      final probed = api.calls.where((c) => c.path == '/api/state').map((c) => c.url).toList();
      expect(probed.take(3), ['http://10.0.0.9', 'http://10.0.0.5', 'http://glimmer.local']);
      expect(repo.url, 'http://glimmer.local');
      expect(store.deviceUrl, 'http://glimmer.local');
    });

    test('the setup AP is used but never saved as the address', () async {
      await setUpRepo({'device_url': 'http://10.0.0.9'});
      api.device(DeviceRepository.setupApUrl, {'wifi': 'ap'});
      expect(await repo.discover(), isTrue);
      expect(repo.state!.inSetupMode, isTrue);
      expect(store.deviceUrl, 'http://10.0.0.9');
    });

    test('nothing answers → notFound, not connected', () async {
      await setUpRepo();
      expect(await repo.discover(), isFalse);
      expect(repo.connected, isFalse);
      expect(repo.error!.kind, AppErrorKind.notFound);
    });
  });

  test('connectTo adds http:// and stores the token; a dead address → noDeviceAt', () async {
    await setUpRepo();
    api.device('http://192.168.1.50');
    expect(await repo.connectTo(' 192.168.1.50 ', token: ' abc '), isTrue);
    expect(store.token, 'abc');
    expect(await repo.connectTo('192.168.1.51'), isFalse);
    expect(repo.error!.kind, AppErrorKind.noDeviceAt);
    expect(repo.error!.detail, 'http://192.168.1.51');
  });

  test('R-KN-4 cards behind a token → empty cards + cardsNeedToken, state still read', () async {
    await setUpRepo();
    api.device('http://d', {'fw': '2.0'});
    api.on('http://d', 'GET', '/push', const DeviceHttpException(401));
    await repo.connectTo('http://d');
    await repo.refresh();
    expect(repo.state!.fw, '2.0');
    expect(repo.cards, isEmpty);
    expect(repo.cardsNeedToken, isTrue);
    expect(repo.error, isNull);
  });

  test('refresh failure keeps the last state and reports unreachable', () async {
    await setUpRepo();
    api.device('http://d');
    await repo.connectTo('http://d');
    api.gone('http://d');
    await repo.refresh();
    expect(repo.state, isNotNull);
    expect(repo.error!.kind, AppErrorKind.unreachable);
    expect(repo.error!.detail, 'TimeoutException');
  });

  test('R-KN-3 forget drops the device', () async {
    await setUpRepo();
    api.device('http://d');
    await repo.connectTo('http://d');
    repo.forget();
    expect(repo.connected, isFalse);
    expect(repo.state, isNull);
  });

  group('R-WF-2 a restart that cuts the answer counts as success', () {
    test('saveSettings(restart) with no answer → ok; without restart → error', () async {
      await setUpRepo();
      api.device('http://d');
      await repo.connectTo('http://d');
      expect(await repo.saveSettings({'a': 1}, restart: true), isA<Ok<void>>());
      expect(api.calls.lastWhere((c) => c.method == 'POST').body, {'a': 1, '_restart': true});
      final r = await repo.saveSettings({'a': 1});
      expect((r as Error).error, isA<AppError>().having((e) => e.kind, 'kind', AppErrorKind.unreachable));
    });

    test('an HTTP error on a restart is still an error', () async {
      await setUpRepo();
      api.device('http://d');
      api.on('http://d', 'POST', '/api/import', const DeviceHttpException(500));
      await repo.connectTo('http://d');
      final r = await repo.importConfig({'wifi_ssid': 'x'});
      expect(((r as Error).error as AppError).kind, AppErrorKind.http);
    });

    test('saveSettings(at:) goes to the given address', () async {
      await setUpRepo();
      await repo.saveSettings({'wifiSSID': 'n'}, restart: true, at: DeviceRepository.setupApUrl);
      expect(api.calls.last.url, DeviceRepository.setupApUrl);
    });
  });

  test('401 → unauthorized, upload rejection → flashFailed', () async {
    await setUpRepo();
    api.device('http://d');
    api.on('http://d', 'GET', '/api/settings', const DeviceHttpException(401));
    await repo.connectTo('http://d');
    expect(((await repo.settings() as Error).error as AppError).kind, AppErrorKind.unauthorized);
    api.uploadAnswer = const DeviceHttpException(500, 'Update error');
    final up = await repo.upload('firmware', Uint8List(0));
    expect(((up as Error).error as AppError).kind, AppErrorKind.flashFailed);
  });

  group('rediscover', () {
    test('without keep: forgets, then finds it again', () async {
      await setUpRepo();
      api.device('http://d');
      await repo.connectTo('http://d');
      var sawDisconnected = false;
      repo.addListener(() => sawDisconnected |= !repo.connected);
      expect(await repo.rediscover(attempts: 3, gap: const Duration(seconds: 8)), isTrue);
      expect(sawDisconnected, isTrue);
      expect(delay.asked.first, const Duration(seconds: 15));
    });

    test('keep: stays connected meanwhile and restores the old device when not found', () async {
      await setUpRepo();
      api.device('http://d');
      await repo.connectTo('http://d');
      api.gone('http://d');
      var sawDisconnected = false;
      repo.addListener(() => sawDisconnected |= !repo.connected);
      expect(await repo.rediscover(attempts: 3, gap: const Duration(seconds: 6), keep: true), isFalse);
      expect(sawDisconnected, isFalse);
      expect(repo.url, 'http://d');
      expect(delay.asked.where((d) => d == const Duration(seconds: 6)).length, 2);
    });
  });

  test('joinSetupAp joins glimmer-setup and checks the device answers there', () async {
    await setUpRepo();
    api.device(DeviceRepository.setupApUrl, {'wifi': 'ap'});
    expect(await repo.joinSetupAp(), isTrue);
    expect(wifi.joined, [DeviceRepository.setupApSsid]);
    wifi.joins = false;
    expect(await repo.joinSetupAp(attempts: 2), isFalse);
  });
}
