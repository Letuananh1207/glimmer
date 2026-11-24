// Talks to a real display. Skipped unless GLIMMER_LIVE is set:
//
//   GLIMMER_LIVE=http://192.168.100.40 flutter test test/device_live_test.dart
//
// Read-only, except the OTA test, which also needs GLIMMER_LIVE_FLASH=<path
// to a firmware.bin> — flash the build the device already runs to check the
// app's upload path without changing anything.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/api/device_api.dart';

void main() {
  final url = Platform.environment['GLIMMER_LIVE'] ?? '';
  final flash = Platform.environment['GLIMMER_LIVE_FLASH'] ?? '';
  final skip = url.isEmpty ? 'set GLIMMER_LIVE=http://<device>' : null;

  test('state, settings and cards read through DeviceApi', () async {
    final api = DeviceApi(url);
    final s = await api.state();
    expect(s.fw, isNotEmpty);
    expect(s.ip, isNotEmpty);
    expect(s.usage.cred, isNotEmpty, reason: 'firmware must expose claude_usage');
    final settings = await api.settings();
    expect(settings['brightness'], isA<int>());
    expect(settings['wifiPass'], anyOf('***', ''), reason: 'secrets stay masked');
    expect(await api.cards(), isA<List>());
    api.close();
  }, skip: skip, timeout: const Timeout(Duration(seconds: 60)));

  test('OTA upload of the running firmware, then the device comes back', () async {
    final api = DeviceApi(url);
    final before = await api.state();
    var last = 0.0;
    await api.upload('firmware', await File(flash).readAsBytes(), onProgress: (p) => last = p);
    expect(last, closeTo(1.0, 0.001));
    final after = await api.waitOnline();
    expect(after, isNotNull);
    expect(after!.fw, before.fw);
    expect(after.uptimeS, lessThan(before.uptimeS + 60));
    api.close();
  }, skip: skip ?? (flash.isEmpty ? 'set GLIMMER_LIVE_FLASH=<firmware.bin>' : null),
      timeout: const Timeout(Duration(minutes: 4)));
}
