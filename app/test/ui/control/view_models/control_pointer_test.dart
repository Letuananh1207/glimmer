import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/domain/models/cursor.dart';
import 'package:glimmer_app/domain/rules/start_rules.dart';
import 'package:glimmer_app/domain/use_cases/control_device_use_case.dart';
import 'package:glimmer_app/ui/control/view_models/control_view_model.dart';

import '../../../../testing/fakes/fake_repositories.dart';

const _url = 'http://192.168.1.50';

Map<String, dynamic> _state({String channel = 'Home', bool mouse = true, String power = 'on', bool fun = false}) => {
  'fw': '0.31.0',
  'wifi': 'connected',
  'ip': '192.168.1.50',
  'time': 1795500000,
  'active_channel': channel,
  'skills_on': ['agent', 'weather', 'clock', if (fun) 'fun'],
  'paused': false,
  'screen_on': true,
  'slide_ms': 0,
  'slide_left_ms': 0,
  'windows': <String, Object?>{},
  'clock': <String, Object?>{},
  if (mouse) ...{
    'cursor': {'port': 4210, 'x': 120, 'y': 120, 'shape': 1, 'shown': false},
    'power': power,
    'mines': {'face': 'smile', 'left': 10, 'secs': 0, 'run': false},
  },
};

void main() {
  late DeviceRig rig;
  late ControlViewModel vm;
  var now = DateTime(2026, 11, 27, 10);

  Future<ControlViewModel> make({Map<String, dynamic>? state}) async {
    await rig.connect(_url, state ?? _state());
    rig.api.on(_url, 'GET', '/api/settings', {'brightness': 50, 'nightMode': 0, 'weatherPlace': 'Hà Nội'});
    rig.api.on(_url, 'POST', '/api/menu', {'ok': true});
    rig.api.on(_url, 'POST', '/api/windows', {'ok': true});
    final v = ControlViewModel(
      device: rig.repo,
      control: ControlDeviceUseCase(device: rig.repo),
      now: () => now,
      random: math.Random(7),
    );
    await v.reload();
    return v;
  }

  void answer(String active) => rig.api.on(_url, 'POST', '/api/channel', {'ok': true, 'active': active, 'paused': false});

  List<Map> menus() => [for (final c in rig.posts('/api/menu')) c.body as Map];

  setUp(() async {
    now = DateTime(2026, 11, 27, 10);
    rig = await DeviceRig.create();
  });
  tearDown(() {
    vm.dispose();
    rig.repo.dispose();
  });

  test('R-DK-17 the pointer starts in the middle; a move goes out at once, a quick second one waits ~33 ms', () async {
    vm = await make();
    expect((vm.cursor.px, vm.cursor.py), (120, 120));
    vm.movePointer(10, 0, const Duration(milliseconds: 100));
    await Future<void>.delayed(Duration.zero);
    expect(rig.cursor.sent, hasLength(1));
    vm.movePointer(10, 0, const Duration(milliseconds: 100));
    vm.movePointer(10, 0, const Duration(milliseconds: 100));
    await Future<void>.delayed(Duration.zero);
    expect(rig.cursor.sent, hasLength(1), reason: 'paced');
    now = now.add(const Duration(milliseconds: 40));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(rig.cursor.sent, hasLength(2));
    expect(rig.cursor.sent.last.datagram[6], vm.cursor.px, reason: 'the latest position');
  });

  test('R-DK-17 R-DK-18 pointer on × of the window: hand; left click closes it (as the old tap)', () async {
    answer('Claude');
    vm = await make();
    await vm.openProgram('Claude');
    vm.movePointer(1000, -1000, const Duration(milliseconds: 16)); // → (239, 0)
    vm.movePointer(-22, 22, const Duration(seconds: 10)); // ≈ 11 px left, 11 down: on ×
    expect(vm.cursor.shape, CursorShape.hand);
    answer('Home');
    await vm.clickLeft();
    expect((rig.posts('/api/channel').last.body as Map)['name'], 'Home');
    expect(vm.windows.open, isEmpty);
  });

  test('R-DK-18 R-DK-19 right click on the desktop opens its menu; ↓ lights the first item; Esc closes', () async {
    vm = await make();
    await vm.clickRight();
    expect(menus().last['kind'], 'desktop');
    await vm.pressKey(ControlKey.down);
    expect(menus().last['hover'], 0); // Sắp xếp biểu tượng
    await vm.pressKey(ControlKey.escape);
    expect(menus().last, {'kind': 'none'});
  });

  test('R-DK-19 Windows opens Start on the device, again closes it; Alt+F4 closes the window on top', () async {
    answer('Weather');
    vm = await make();
    await vm.pressKey(ControlKey.windows);
    expect(menus().last, {'kind': 'start', 'all': false});
    expect(vm.startOpen, isTrue);
    await vm.pressKey(ControlKey.windows);
    expect(menus().last, {'kind': 'none'});
    await vm.openProgram('Weather');
    answer('Home');
    await vm.pressKey(ControlKey.altF4);
    expect((rig.posts('/api/channel').last.body as Map)['name'], 'Home');
  });

  test('R-DK-22 Start open: click on Claude opens it; on Cài đặt the phone screen comes back to the screen', () async {
    answer('Claude');
    vm = await make();
    await vm.pressKey(ControlKey.windows);
    vm.movePointer(-120, -140, const Duration(seconds: 10)); // (120, 120) → ≈ (58, 48): Claude row
    expect(vm.cursor.shape, CursorShape.hand);
    expect(await vm.clickLeft(), isNull);
    expect((rig.posts('/api/channel').last.body as Map)['name'], 'Claude');
    expect(vm.startOpen, isFalse);
    await vm.pressKey(ControlKey.windows);
    vm.movePointer(260, 100, const Duration(seconds: 10)); // → ≈ (190, 99): Cài đặt
    final pick = await vm.clickLeft();
    expect(pick, const StartPick(StartPickKind.appScreen, screen: AppScreen.settings));
    expect(menus().last, {'kind': 'none'});
  });

  test('R-DK-22 Tất cả chương trình opens the sub-menu (all: true), a click outside closes Start', () async {
    vm = await make();
    await vm.pressKey(ControlKey.windows);
    vm.movePointer(-120, 110, const Duration(seconds: 10)); // → ≈ (58, 176)
    await vm.clickLeft();
    expect(menus().last, {'kind': 'start', 'all': true});
    vm.movePointer(0, 200, const Duration(seconds: 10)); // → the taskbar
    await vm.clickLeft();
    expect(menus().last, {'kind': 'none'});
    expect(vm.startOpen, isFalse);
  });

  test('R-DK-23 Dò mìn: opening it sends the board; a click opens a cell, a right click flags, the face restarts',
      () async {
    answer('Mines');
    vm = await make(state: _state(fun: true));
    rig.api.on(_url, 'POST', '/api/mines', {'ok': true});
    await vm.openProgram('Mines');
    await Future<void>.delayed(Duration.zero);
    List<Map> sent() => [for (final c in rig.posts('/api/mines')) c.body as Map];
    expect(sent().single, {'board': '.' * 81, 'face': 'smile', 'left': 10, 'secs': 0, 'run': false});
    vm.movePointer(0, 32, const Duration(seconds: 10)); // (120, 120) → (120, 136): cell (4, 4)
    await vm.clickLeft();
    await Future<void>.delayed(Duration.zero);
    final first = sent().last;
    expect((first['board'] as String)[40], isNot('.'), reason: 'opened, never a mine on the first click');
    expect(first['run'], true);
    expect(vm.minesGame.mines.contains(40), isFalse);
    // A right click on a closed cell flags it.
    final closed = (first['board'] as String).indexOf('.');
    final cx = 48 + 16 * (closed % 9) + 8, cy = 64 + 16 * (closed ~/ 9) + 8;
    vm.movePointer((cx - vm.cursor.x) * 2, (cy - vm.cursor.y) * 2, const Duration(seconds: 100));
    await vm.clickRight();
    await Future<void>.delayed(Duration.zero);
    expect((sent().last['board'] as String)[closed], 'F');
    expect(sent().last['left'], 9);
    expect(rig.posts('/api/menu'), isEmpty, reason: 'not the window menu');
    // The face: a new game.
    vm.movePointer((120 - vm.cursor.x) * 2, (42 - vm.cursor.y) * 2, const Duration(seconds: 100));
    await vm.clickLeft();
    await Future<void>.delayed(Duration.zero);
    expect(sent().last['board'], '.' * 81);
  });

  test('R-DK-20 power off: POST {on: false}; then the pointer sends nothing', () async {
    vm = await make();
    rig.api.on(_url, 'POST', '/api/power', {'ok': true, 'power': 'shutting'});
    await vm.pressPower();
    expect(rig.posts('/api/power').single.body, {'on': false});
    expect(vm.power, PowerState.shutting);
    vm.movePointer(10, 10, const Duration(milliseconds: 50));
    await Future<void>.delayed(Duration.zero);
    expect(rig.cursor.sent, isEmpty);
  });

  test('R-DK-20 power on from off: {on: true}, a bare desktop and the pointer back in the middle', () async {
    vm = await make(state: _state(power: 'off'));
    rig.api.on(_url, 'POST', '/api/power', {'ok': true, 'power': 'booting'});
    await vm.pressPower();
    expect(rig.posts('/api/power').single.body, {'on': true});
    expect(vm.windows.open, isEmpty);
    expect(vm.cursor, Cursor.home);
  });

  test('R-DK-21 firmware without the mouse: no datagram, no power POST, keys do nothing', () async {
    vm = await make(state: _state(mouse: false));
    expect(vm.mouseReady, isFalse);
    vm.movePointer(10, 10, const Duration(milliseconds: 50));
    await vm.pressPower();
    await vm.pressKey(ControlKey.windows);
    await Future<void>.delayed(Duration.zero);
    expect(rig.cursor.sent, isEmpty);
    expect(rig.posts('/api/power'), isEmpty);
    expect(menus(), isEmpty);
  });
}
