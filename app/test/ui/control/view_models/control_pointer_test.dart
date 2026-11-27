import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/domain/models/cursor.dart';
import 'package:glimmer_app/domain/use_cases/control_device_use_case.dart';
import 'package:glimmer_app/ui/control/view_models/control_view_model.dart';

import '../../../../testing/fakes/fake_repositories.dart';

const _url = 'http://192.168.1.50';

Map<String, dynamic> _state({String channel = 'Home', bool mouse = true, String power = 'on'}) => {
  'fw': '0.31.0',
  'wifi': 'connected',
  'ip': '192.168.1.50',
  'time': 1795500000,
  'active_channel': channel,
  'skills_on': ['agent', 'weather', 'clock'],
  'paused': false,
  'screen_on': true,
  'slide_ms': 0,
  'slide_left_ms': 0,
  'windows': <String, Object?>{},
  'clock': <String, Object?>{},
  if (mouse) ...{
    'cursor': {'port': 4210, 'x': 120, 'y': 120, 'shape': 1, 'shown': false},
    'power': power,
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
    final v = ControlViewModel(device: rig.repo, control: ControlDeviceUseCase(device: rig.repo), now: () => now);
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
