// Talks to a real display. Skipped unless GLIMMER_LIVE is set:
//
//   GLIMMER_LIVE=http://192.168.100.40 flutter test test/device_live_test.dart
//
// Read-only, except the OTA test, which also needs GLIMMER_LIVE_FLASH=<path
// to a firmware.bin> — flash the build the device already runs to check the
// app's upload path without changing anything.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/data/repositories/device/device_repository_local.dart';
import 'package:glimmer_app/data/services/device_api_service.dart';
import 'package:glimmer_app/utils/result.dart';

import '../testing/fakes/fake_services.dart';

Future<DeviceRepositoryLocal> _repo(String url) async {
  final repo = DeviceRepositoryLocal(
    api: DeviceApiService(),
    discovery: FakeDiscoveryService(),
    store: await fakeStore(),
    wifi: FakeWifiService(),
    pollEvery: const Duration(hours: 1),
  );
  expect(await repo.connectTo(url), isTrue, reason: 'device must answer at $url');
  return repo;
}

void main() {
  final url = Platform.environment['GLIMMER_LIVE'] ?? '';
  final flash = Platform.environment['GLIMMER_LIVE_FLASH'] ?? '';
  final skip = url.isEmpty ? 'set GLIMMER_LIVE=http://<device>' : null;

  test('state, settings and cards read through the device repository', () async {
    final repo = await _repo(url);
    await repo.refresh();
    final s = repo.state!;
    expect(s.fw, isNotEmpty);
    expect(s.ip, isNotEmpty);
    expect(s.usage.cred, isNotEmpty, reason: 'firmware must expose claude_usage');
    expect(s.skillsOn, isNotEmpty, reason: 'firmware 2026-11-25.3 reports skills_on');
    if (s.weatherConfigured) expect(s.weather?.days.length, 4, reason: 'today + 3 days');
    final settings = (await repo.settings() as Ok<Map<String, dynamic>>).value;
    expect(settings['brightness'], isA<int>());
    expect(settings['wifiPass'], anyOf('***', ''), reason: 'secrets stay masked');
    expect(repo.cards, isA<List>());
    repo.dispose();
  }, skip: skip, timeout: const Timeout(Duration(seconds: 60)));

  test('OTA upload of the running firmware, then the device comes back', () async {
    final repo = await _repo(url);
    final before = repo.state!;
    var last = 0.0;
    final r = await repo.upload('firmware', await File(flash).readAsBytes(), onProgress: (p) => last = p);
    expect(r, isA<Ok<void>>());
    expect(last, closeTo(1.0, 0.001));
    final after = await repo.waitOnline();
    expect(after, isNotNull);
    expect(after!.fw, before.fw);
    expect(after.uptimeS, lessThan(before.uptimeS + 60));
    repo.dispose();
  }, skip: skip ?? (flash.isEmpty ? 'set GLIMMER_LIVE_FLASH=<firmware.bin>' : null),
      timeout: const Timeout(Duration(minutes: 4)));
}
