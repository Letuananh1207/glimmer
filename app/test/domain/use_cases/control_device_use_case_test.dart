import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/data/services/device_api_service.dart';
import 'package:glimmer_app/domain/models/app_error.dart';
import 'package:glimmer_app/domain/models/control.dart';
import 'package:glimmer_app/domain/use_cases/control_device_use_case.dart';
import 'package:glimmer_app/utils/result.dart';

import '../../../testing/fakes/fake_repositories.dart';

const _url = 'http://192.168.1.50';

Map<String, dynamic> _state({bool current = true, String channel = 'Claude'}) => {
  'fw': current ? '0.25.0' : '0.24.0',
  'wifi': 'connected',
  'active_channel': channel,
  'skills_on': ['agent', 'weather', 'clock'],
  if (current) ...{'paused': false, 'screen_on': true, 'slide_ms': 8000, 'slide_left_ms': 5000},
};

void main() {
  late DeviceRig rig;
  late ControlDeviceUseCase control;
  setUp(() async {
    rig = await DeviceRig.create();
    control = ControlDeviceUseCase(device: rig.repo);
  });
  tearDown(() => rig.repo.dispose());

  test('R-DK-1 next: one POST, the device answer is adopted at once', () async {
    await rig.connect(_url, _state());
    rig.api.on(_url, 'POST', '/api/channel', {'ok': true, 'active': 'Weather', 'paused': false});
    final r = await control.step(ControlCommand.next, from: 'Claude');
    expect((r as Ok<ControlOutcome>).value.matched, isTrue);
    expect(rig.posts('/api/channel').single.body, {'action': 'next'});
    expect(rig.repo.state!.activeChannel, 'Weather');
  });

  test('R-DK-1 jump answered with another channel → not matched; no answer → error, sent once', () async {
    await rig.connect(_url, _state());
    rig.api.on(_url, 'POST', '/api/channel', {'ok': true, 'active': 'Claude', 'paused': false});
    final r = await control.jump('weather');
    expect((r as Ok<ControlOutcome>).value.matched, isFalse);
    expect(rig.repo.state!.activeChannel, 'Claude');
    rig.api.answers.remove('$_url POST /api/channel');
    final before = rig.posts('/api/channel').length;
    final e = await control.step(ControlCommand.next, from: 'Claude');
    expect(e, isA<Error<ControlOutcome>>());
    expect(rig.posts('/api/channel').length, before + 1);
  });

  test("jump: a 404 (channel off) moves on to the skill's next channel", () async {
    await rig.connect(_url, _state());
    rig.api.on(_url, 'POST', '/api/channel', const DeviceHttpException(404));
    rig.api.onCall = (c) {
      if (c.path == '/api/channel' && (c.body as Map)['name'] == 'Forecast') {
        rig.api.on(_url, 'POST', '/api/channel', {'ok': true, 'active': 'Forecast', 'paused': false});
      }
    };
    final r = await control.jump('weather');
    expect((r as Ok<ControlOutcome>).value.matched, isTrue);
    expect([for (final c in rig.posts('/api/channel')) (c.body as Map)['name']], ['Weather', 'Forecast']);
  });

  test('R-DK-3 old firmware: prev / pause / screen / dismiss refused, nothing sent', () async {
    await rig.connect(_url, _state(current: false));
    final results = [
      await control.step(ControlCommand.prev, from: 'Claude'),
      await control.pause(true),
      await control.screen(false),
      await control.dismissCard('c1'),
    ];
    for (final r in results) {
      expect(((r as Error).error as AppError).kind, AppErrorKind.controlUnsupported);
    }
    expect(rig.posts(), isEmpty);
  });

  test('R-DK-4 pause is the channel action, never autoRotate', () async {
    await rig.connect(_url, _state());
    rig.api.on(_url, 'POST', '/api/channel', {'ok': true, 'active': 'Claude', 'paused': true});
    final r = await control.pause(true);
    expect((r as Ok<ControlOutcome>).value.matched, isTrue);
    expect(rig.posts('/api/channel').single.body, {'action': 'pause'});
    expect(rig.posts('/api/settings'), isEmpty);
    expect(rig.repo.state!.paused, isTrue);
  });

  test('R-DK-2 dismiss card: /push/clear with that id only', () async {
    await rig.connect(_url, _state());
    rig.api.on(_url, 'POST', '/push/clear', {'cleared': 1});
    await control.dismissCard('c7');
    expect(rig.posts().map((c) => c.path), ['/push/clear']);
    expect(rig.posts('/push/clear').single.body, {'id': 'c7'});
  });

  test('R-DK-5 brightness goes through /api/settings; screen off through /api/screen', () async {
    await rig.connect(_url, _state());
    rig.api.on(_url, 'POST', '/api/settings', {'ok': true});
    rig.api.on(_url, 'POST', '/api/screen', {'ok': true, 'screen_on': false});
    await control.brightness(80);
    final r = await control.screen(false);
    expect(rig.posts('/api/settings').single.body, {'brightness': 80});
    expect((r as Ok<ControlOutcome>).value.matched, isTrue);
    expect(rig.repo.state!.screenOn, isFalse);
  });
}
