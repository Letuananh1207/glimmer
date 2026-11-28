import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/domain/models/cursor.dart';
import 'package:glimmer_app/domain/models/windows.dart';
import 'package:glimmer_app/domain/rules/cursor_rules.dart';
import 'package:glimmer_app/domain/use_cases/control_device_use_case.dart';
import 'package:glimmer_app/ui/control/view_models/control_view_model.dart';

import '../../../../testing/fakes/fake_repositories.dart';

const _url = 'http://192.168.1.50';

Map<String, dynamic> _state({
  String channel = 'Home',
  int stage = 1,
  Map<String, Object?> windows = const {'open': <String>[], 'min': <String>[], 'top': null, 'sel': null},
  String menu = 'none',
}) => {
  'fw': '0.33.0',
  'wifi': 'connected',
  'ip': '192.168.1.50',
  'time': 1795500000,
  'active_channel': channel,
  'skills_on': ['agent', 'weather', 'clock', 'fun'],
  'paused': false,
  'screen_on': true,
  'slide_ms': 0,
  'slide_left_ms': 0,
  'windows': windows,
  'menu': menu,
  'clock': <String, Object?>{},
  'cursor': {'port': 4210, 'x': 120, 'y': 120, 'shape': 1, 'shown': false},
  'power': 'on',
  'calc': {'display': '0.'},
  if (stage > 0) 'input': {'mouse': 2, 'stage': stage},
};

void main() {
  late DeviceRig rig;
  late ControlViewModel vm;
  var created = false;

  Future<ControlViewModel> make(Map<String, dynamic> state) async {
    await rig.connect(_url, state);
    rig.api.on(_url, 'GET', '/api/settings', {'brightness': 50, 'nightMode': 0, 'weatherPlace': 'Hà Nội'});
    for (final p in ['menu', 'windows', 'calc']) {
      rig.api.on(_url, 'POST', '/api/$p', {'ok': true});
    }
    rig.api.on(_url, 'POST', '/api/channel', {'ok': true, 'active': 'Home', 'paused': false});
    final v = ControlViewModel(
      device: rig.repo,
      control: ControlDeviceUseCase(device: rig.repo),
      now: () => DateTime(2026, 11, 28, 10),
      random: math.Random(7),
    );
    await v.reload();
    created = true;
    return v;
  }

  void to(int x, int y) =>
      vm.movePointer((x - vm.cursor.px) * 2.0, (y - vm.cursor.py) * 2.0, const Duration(seconds: 100));

  setUp(() async {
    rig = await DeviceRig.create();
  });
  tearDown(() {
    if (created) vm.dispose();
    created = false;
    rig.repo.dispose();
  });

  test('R-DK-30 mouse v2: a move goes as v2 with no button; a click = 3 presses + 3 releases, no POST', () async {
    vm = await make(_state());
    final posts = rig.api.calls.where((c) => c.method == 'POST').length;
    to(20, 225); // the start button
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final move = rig.cursor.sent.last.datagram;
    expect((move[2], move[3]), (2, 0), reason: 'v2, no button');
    final before = rig.cursor.sent.length;
    await vm.clickLeft();
    final click = rig.cursor.sent.skip(before).map((p) => p.datagram).toList();
    expect(click.map((d) => d[3]), [1, 1, 1, 0, 0, 0]);
    expect({for (final d in click.take(3)) (d[4] << 8) | d[5]}, hasLength(1), reason: 'one seq for the 3 copies');
    expect((click.first[6], click.first[7]), (vm.cursor.px, vm.cursor.py));
    expect(rig.api.calls.where((c) => c.method == 'POST').length, posts, reason: 'the device acts, not the app');
  });

  test('R-DK-30 the app takes the device windows, Start and the selection from /api/state', () async {
    vm = await make(_state(
      channel: 'Claude',
      windows: {'open': ['Claude', 'Weather'], 'min': ['Weather'], 'top': 'Claude', 'sel': null},
      menu: 'start',
    ));
    expect(vm.windows, WindowStack.fromDevice({'open': ['Claude', 'Weather'], 'min': ['Weather'], 'top': 'Claude'}));
    expect(vm.startOpen, isTrue);
    rig.api.device(_url, _state(windows: {'open': <String>[], 'min': <String>[], 'top': null, 'sel': 'Codex'}));
    await rig.repo.refresh();
    expect(vm.windows.open, isEmpty);
    expect((vm.windows.sel, vm.startOpen), ('Codex', false));
  });

  test('R-DK-30 inside a window the app still drives (Máy tính bỏ túi), the app acts too', () async {
    vm = await make(_state(channel: 'Calc', windows: {'open': ['Calc'], 'min': <String>[], 'top': 'Calc'}));
    to(8 + 38 * 2 + 10, 86 + 30 * 2 + 10); // 2
    await vm.clickLeft();
    await Future<void>.delayed(Duration.zero);
    expect(rig.posts('/api/calc').last.body, containsPair('display', '2.'));
  });

  test('R-DK-30 firmware without input: mouse v1, the app works the click out (R-DK-17…29)', () async {
    vm = await make(_state(stage: 0));
    to(20, 225);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(rig.cursor.sent.last.datagram[2], 1);
    await vm.clickLeft();
    expect(rig.posts('/api/menu').last.body, {'kind': 'start', 'all': false});
  });

  test('mousePacket encodes v2', () {
    expect(mousePacket(0x0102, const Cursor(x: 10, y: 20), 3), [0x47, 0x43, 2, 3, 1, 2, 10, 20]);
  });

  test('R-DK-31 stage 3: a right click goes to the device (button 2), no /api/menu; keys go as G K datagrams', () async {
    vm = await make(_state(stage: 3));
    final menus = rig.posts('/api/menu').length;
    final before = rig.cursor.sent.length;
    await vm.clickRight();
    final right = rig.cursor.sent.skip(before).map((p) => p.datagram).toList();
    expect(right.map((d) => d[3]), [2, 2, 2, 0, 0, 0]);
    expect(rig.posts('/api/menu').length, menus);
    final k0 = rig.cursor.sent.length;
    await vm.pressKey(ControlKey.altTab);
    final keys = rig.cursor.sent.skip(k0).map((p) => p.datagram).toList();
    expect(keys, hasLength(3));
    expect((keys.first[0], keys.first[1], keys.first[2], keys.first[5], keys.first[6]), (0x47, 0x4B, 1, 2, 1));
    expect(rig.posts('/api/menu').length, menus, reason: 'the device draws the Alt+Tab box itself');
  });

  test('R-DK-31 keys inside a window the app drives still act (Máy tính bỏ túi: Enter = "=")', () async {
    vm = await make(_state(stage: 3, channel: 'Calc', windows: {'open': ['Calc'], 'min': <String>[], 'top': 'Calc'}));
    await vm.pressKey(ControlKey.enter);
    await Future<void>.delayed(Duration.zero);
    expect(rig.posts('/api/calc').last.body, containsPair('display', '0.'));
  });

  test('keyPacket encodes the firmware key codes', () {
    expect(keyPacket(5, ControlKey.altF4), [0x47, 0x4B, 1, 0, 5, 2, 8]);
    expect(keyPacket(6, ControlKey.windows), [0x47, 0x4B, 1, 0, 6, 0, 11]);
  });
}
