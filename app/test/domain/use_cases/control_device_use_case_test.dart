import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/data/services/device_api_service.dart';
import 'package:glimmer_app/domain/models/app_error.dart';
import 'package:glimmer_app/domain/models/control.dart';
import 'package:glimmer_app/domain/models/cursor.dart';
import 'package:glimmer_app/domain/models/touch.dart';
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

  test('R-DK-7 open: one POST {name}, the device answer is adopted at once', () async {
    await rig.connect(_url, _state());
    rig.api.on(_url, 'POST', '/api/channel', {'ok': true, 'active': 'Weather', 'paused': false});
    final r = await control.open('Weather');
    expect((r as Ok<ControlOutcome>).value.matched, isTrue);
    expect(rig.posts('/api/channel').single.body, {'name': 'Weather'});
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
    final e = await control.open('Weather');
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

  test('R-DK-3 R-DK-10 old firmware: touches / screen / dismiss refused, nothing sent', () async {
    await rig.connect(_url, _state(current: false));
    final results = [
      await control.open('Home', c: ControlCommand.minimize),
      await control.open('Claude', c: ControlCommand.close),
      await control.screen(false),
      await control.dismissCard('c1'),
    ];
    for (final r in results) {
      expect(((r as Error).error as AppError).kind, AppErrorKind.controlUnsupported);
    }
    expect(rig.posts(), isEmpty);
  });

  test('R-DK-10 old firmware: opening from Start still goes out', () async {
    await rig.connect(_url, _state(current: false));
    rig.api.on(_url, 'POST', '/api/channel', {'ok': true, 'active': 'Weather'});
    final r = await control.open('Weather');
    expect((r as Ok<ControlOutcome>).value.matched, isTrue);
    expect(rig.posts('/api/channel').single.body, {'name': 'Weather'});
  });

  test('R-DK-7 stop rotation: autoRotate false only when it is still on', () async {
    await rig.connect(_url, _state());
    rig.api.on(_url, 'POST', '/api/settings', {'ok': true});
    await control.stopRotation({'autoRotate': false});
    expect(rig.posts('/api/settings'), isEmpty);
    await control.stopRotation({'autoRotate': true});
    expect(rig.posts('/api/settings').single.body, {'autoRotate': false});
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

  group('mouse firmware', () {
    Map<String, dynamic> mouse() => {
      ..._state(),
      'windows': {'open': <String>[]},
      'cursor': {'port': 4210, 'x': 120, 'y': 120, 'shape': 1, 'shown': false},
      'power': 'on',
    };

    test('R-DK-17 the pointer goes out as a datagram to the reported port, sequence counting up', () async {
      await rig.connect(_url, mouse());
      expect(control.caps.mouse, isTrue);
      expect(await control.cursor(const Cursor(x: 10, y: 20, shape: CursorShape.hand)), isTrue);
      await control.cursor(const Cursor(x: 11, y: 20));
      final sent = rig.cursor.sent;
      expect(sent.map((p) => (p.host, p.port)), [('192.168.1.50', 4210), ('192.168.1.50', 4210)]);
      expect(sent[0].datagram, [0x47, 0x43, 1, 2, 0, 1, 10, 20]);
      expect(sent[1].datagram.sublist(4), [0, 2, 11, 20]);
    });

    test('R-DK-18 the lit menu item goes as hover (index without separators)', () async {
      await rig.connect(_url, mouse());
      rig.api.on(_url, 'POST', '/api/menu', {'ok': true});
      const m = MenuView(MenuKind.window, 71, 100, program: 'Claude');
      await control.menu(m, hover: MenuItem.close);
      expect((rig.posts('/api/menu').single.body as Map)['hover'], 5);
    });

    test('R-DK-20 the power button: POST {on}, the answer goes into the state', () async {
      await rig.connect(_url, mouse());
      rig.api.on(_url, 'POST', '/api/power', {'ok': true, 'power': 'shutting'});
      final r = await control.power(false);
      expect((r as Ok<PowerState>).value, PowerState.shutting);
      expect(rig.posts('/api/power').single.body, {'on': false});
      expect(rig.repo.state!.power, PowerState.shutting);
    });

    test('R-DK-21 firmware without the mouse: no datagram, power refused, no hover', () async {
      await rig.connect(_url, {..._state(), 'windows': {'open': <String>[]}});
      expect(control.caps.mouse, isFalse);
      expect(await control.cursor(Cursor.home), isFalse);
      expect(rig.cursor.sent, isEmpty);
      expect(await control.power(false), isA<Error<PowerState>>());
      expect(rig.posts('/api/power'), isEmpty);
      rig.api.on(_url, 'POST', '/api/menu', {'ok': true});
      await control.menu(const MenuView(MenuKind.desktop, 10, 10), hover: MenuItem.refresh);
      expect((rig.posts('/api/menu').single.body as Map).containsKey('hover'), isFalse);
    });
  });

  group('R-DK-24…29 XP programs', () {
    test('a view goes to POST /api/<program> only when the firmware draws it', () async {
      await rig.connect(_url, {..._state(), 'calc': {'display': '0.'}});
      rig.api.on(_url, 'POST', '/api/calc', {'ok': true});
      await control.programView('calc', {'display': '5.'});
      await control.programView('taskmgr', {'tab': 1});
      expect(rig.posts('/api/calc').single.body, {'display': '5.'});
      expect(rig.posts('/api/taskmgr'), isEmpty);
    });

    test('R-DK-25 Alt+Tab box: {kind: alttab, sel}, null closes; nothing on firmware without it', () async {
      await rig.connect(_url, _state());
      await control.altTab(1);
      expect(rig.posts('/api/menu'), isEmpty);
      await rig.connect(_url, {..._state(), 'taskmgr': {'tab': 0}});
      rig.api.on(_url, 'POST', '/api/menu', {'ok': true});
      await control.altTab(1);
      await control.altTab(null);
      expect(rig.posts('/api/menu').map((c) => c.body), [
        {'kind': 'alttab', 'sel': 1},
        {'kind': 'none'},
      ]);
    });
  });
}
