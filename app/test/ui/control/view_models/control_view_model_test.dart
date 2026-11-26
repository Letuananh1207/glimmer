import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/domain/models/control.dart';
import 'package:glimmer_app/domain/use_cases/control_device_use_case.dart';
import 'package:glimmer_app/domain/models/touch.dart';
import 'package:glimmer_app/ui/control/view_models/control_view_model.dart';
import 'package:glimmer_app/domain/models/mirror_frame.dart';

import '../../../../testing/fakes/fake_repositories.dart';

const _url = 'http://192.168.1.50';

Map<String, dynamic> _state({String channel = 'Home', bool paused = false, bool current = true}) => {
  'fw': current ? '0.25.0' : '0.24.0',
  'wifi': 'connected',
  'ip': '192.168.1.50',
  'ssid': 'Nha',
  'time': 1795500000,
  'active_channel': channel,
  'skills_on': ['agent', 'weather', 'clock'],
  if (current) ...{
    'paused': paused,
    'screen_on': true,
    'slide_ms': 0,
    'slide_left_ms': 0,
    'windows': <String, Object?>{},
  },
};

void main() {
  late DeviceRig rig;
  late ControlViewModel vm;
  var now = DateTime(2026, 11, 26, 14, 32);

  Future<ControlViewModel> make({Map<String, dynamic>? state, Map<String, dynamic>? settings}) async {
    await rig.connect(_url, state ?? _state());
    rig.api.on(
      _url,
      'GET',
      '/api/settings',
      settings ?? {'brightness': 50, 'nightMode': 0, 'showClaude': true, 'tzMinutes': 420},
    );
    final v = ControlViewModel(
      device: rig.repo,
      control: ControlDeviceUseCase(device: rig.repo),
      now: () => now,
    );
    await v.reload();
    return v;
  }

  setUp(() async {
    now = DateTime(2026, 11, 26, 14, 32);
    rig = await DeviceRig.create();
  });
  tearDown(() {
    vm.dispose();
    rig.repo.dispose();
  });

  void answer(String active) =>
      rig.api.on(_url, 'POST', '/api/channel', {'ok': true, 'active': active, 'paused': false});

  List<Object?> sent() => [for (final c in rig.posts('/api/channel')) (c.body as Map)['name']];

  test('R-DK-6 opening reads /api/state and the settings at once', () async {
    vm = await make();
    final reads = rig.api.calls.where((c) => c.method == 'GET' && c.path == '/api/state').length;
    final settings = rig.api.calls.where((c) => c.method == 'GET' && c.path == '/api/settings').length;
    // connect() reads it once; opening the screen reads it again (constructor + reload in this test).
    expect(reads, greaterThanOrEqualTo(2));
    expect(settings, greaterThanOrEqualTo(1));
    expect(vm.brightness, 50);
    expect(vm.frame!.channel, 'Home');
  });

  test('R-DK-7 the app opens on the desktop: a program on the device → Home once, empty taskbar', () async {
    answer('Home');
    vm = await make(state: _state(channel: 'Claude'));
    expect(sent(), ['Home']);
    expect(vm.channel, 'Home');
    expect(vm.windows.open, isEmpty);
    expect(vm.frame!.taskbar.buttons, isEmpty);
    await vm.reload();
    expect(sent(), ['Home'], reason: 'only once');
  });

  test('R-DK-7 autoRotate on → off, once', () async {
    vm = await make(settings: {'brightness': 50, 'autoRotate': true});
    rig.api.on(_url, 'POST', '/api/settings', {'ok': true});
    await vm.reload();
    expect(rig.posts('/api/settings').map((c) => c.body), [
      {'autoRotate': false},
    ]);
  });

  test('R-DK-1 R-DK-7 opening shows at once, then the device answer; the taskbar gets its button', () async {
    vm = await make();
    final hold = Completer<void>();
    rig.api.holdPosts = hold;
    answer('Weather');
    final f = vm.openProgram('Weather');
    await Future<void>.delayed(Duration.zero);
    expect(vm.channel, 'Weather');
    expect(vm.sending, isTrue);
    expect(vm.frame!.taskbar.programs, ['Weather']);
    expect(vm.frame!.taskbar.active, 0);
    hold.complete();
    rig.api.holdPosts = null;
    await f;
    expect(vm.sending, isFalse);
    expect(vm.failed, isNull);
    expect(sent(), ['Weather']);
  });

  test('R-DK-1 device shows another channel → follow it, report, no second command', () async {
    vm = await make();
    answer('Claude');
    await vm.openProgram('Clock');
    expect(vm.channel, 'Claude');
    expect(vm.failed, ControlCommand.open);
    expect(vm.failedApp, 'Clock');
    expect(vm.windows.open, ['Claude']);
    expect(sent(), ['Clock']);
  });

  test('R-DK-1 no answer → back to the device channel, Thử lại is the only resend', () async {
    vm = await make();
    await vm.openProgram('Weather');
    expect(vm.channel, 'Home');
    expect(vm.failed, ControlCommand.open);
    expect(vm.windows.open, isEmpty);
    answer('Weather');
    await vm.retry();
    expect(sent(), ['Weather', 'Weather']);
    expect(vm.failed, isNull);
    expect(vm.channel, 'Weather');
  });

  test('R-DK-8 the taskbar = open windows in opening order, the top one pressed', () async {
    vm = await make();
    answer('Claude');
    await vm.openProgram('Claude');
    answer('Weather');
    await vm.openProgram('Weather');
    expect(vm.frame!.taskbar.programs, ['Claude', 'Weather']);
    expect(vm.frame!.taskbar.buttons, [TaskButton.claude, TaskButton.weather]);
    expect(vm.frame!.taskbar.active, 1);
  });

  test('R-DK-8 tap _ → desktop, the button stays unpressed; tap it → back', () async {
    vm = await make();
    answer('Claude');
    await vm.openProgram('Claude');
    answer('Home');
    expect(vm.tap(192, 11).kind, TouchKind.minimize);
    await Future<void>.delayed(Duration.zero);
    expect(vm.channel, 'Home');
    while (vm.sending) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(sent(), ['Claude', 'Home']);
    expect(vm.windows.minimized, {'Claude'});
    expect(vm.frame!.taskbar.programs, ['Claude']);
    expect(vm.frame!.taskbar.active, isNull);
    answer('Claude');
    expect(vm.tap(85, 227), const TouchTarget(TouchKind.taskbar, program: 'Claude'));
    while (vm.sending) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(sent().last, 'Claude');
    expect(vm.frame!.taskbar.active, 0);
  });

  test('R-DK-8 × → the window before it; the last one → desktop, empty taskbar', () async {
    vm = await make();
    answer('Claude');
    await vm.openProgram('Claude');
    answer('Weather');
    await vm.openProgram('Weather');
    answer('Claude');
    await vm.closeTop();
    expect(sent().last, 'Claude');
    expect(vm.windows.open, ['Claude']);
    answer('Home');
    await vm.closeTop();
    expect(sent().last, 'Home');
    expect(vm.windows.open, isEmpty);
    expect(vm.frame!.taskbar.buttons, isEmpty);
  });

  test("R-DK-8 the shown window's button minimizes it (as XP); □ and start send nothing", () async {
    vm = await make();
    answer('Claude');
    await vm.openProgram('Claude');
    answer('Home');
    await vm.taskbar('Claude');
    expect(sent(), ['Claude', 'Home']);
    expect(vm.windows.minimized, {'Claude'});
    answer('Claude');
    await vm.taskbar('Claude');
    expect(vm.tap(210, 11).kind, TouchKind.maximize);
    expect(vm.tap(30, 227).kind, TouchKind.start);
    await Future<void>.delayed(Duration.zero);
    expect(sent(), ['Claude', 'Home', 'Claude']);
  });

  test('R-DK-8 a desktop icon opens its program', () async {
    vm = await make();
    answer('Clock');
    expect(vm.tap(120, 60), const TouchTarget(TouchKind.icon, program: 'Clock'));
    while (vm.sending) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(sent(), ['Clock']);
  });

  test('R-DK-9 a skill turned off takes its windows with it', () async {
    vm = await make();
    answer('Claude');
    await vm.openProgram('Claude');
    answer('Clock');
    await vm.openProgram('Clock');
    expect(vm.windows.open, ['Claude', 'Clock']);
    rig.api.device(_url, {
      ..._state(channel: 'Clock'),
      'skills_on': ['agent', 'weather'],
    });
    await rig.repo.refresh();
    expect(vm.windows.open, ['Claude']);
    expect(vm.programs.values.expand((l) => l), isNot(contains('Clock')));
  });

  test('R-DK-3 R-DK-10 old firmware: no desktop sent, touches and locked buttons send nothing', () async {
    vm = await make(state: _state(channel: 'Claude', current: false));
    expect(vm.missing, [ControlCommand.minimize, ControlCommand.screenOff]);
    expect(vm.touchable, isFalse);
    expect(vm.windows.open, ['Claude'], reason: 'cannot go to the desktop: adopt what it shows');
    expect(vm.tap(228, 11).kind, TouchKind.none);
    expect(vm.tap(30, 227).kind, TouchKind.start, reason: 'Start is the app\'s');
    await vm.minimizeTop();
    await vm.closeTop();
    await vm.toggleScreen();
    expect(rig.posts(), isEmpty);
    expect(vm.failed, isNull);
  });

  test('R-DK-10 old firmware: Start still opens a program', () async {
    vm = await make(state: _state(current: false));
    answer('Weather');
    await vm.openProgram('Weather');
    expect(sent(), ['Weather']);
  });

  test('R-DK-5 brightness: dragging sends nothing, release sends once', () async {
    vm = await make();
    rig.api.on(_url, 'POST', '/api/settings', {'ok': true});
    vm.dragBrightness(60);
    vm.dragBrightness(80);
    expect(vm.brightness, 80);
    expect(vm.dragging, isTrue);
    expect(vm.dim, greaterThan(0));
    expect(rig.posts('/api/settings'), isEmpty);
    await vm.releaseBrightness();
    expect(rig.posts('/api/settings').single.body, {'brightness': 80});
    expect(vm.brightness, 80);
    expect(vm.dragging, isFalse);
  });

  test('R-DK-5 a refused brightness goes back to the old value and reports', () async {
    vm = await make();
    vm.dragBrightness(90);
    await vm.releaseBrightness();
    expect(vm.brightness, 50);
    expect(vm.failed, ControlCommand.brightness);
  });

  test('R-DK-2 dismiss card removes the holding card by id', () async {
    rig.api.on(_url, 'GET', '/push', {
      'cards': [
        {'id': 'c1', 'kind': 'approval', 'agent': 'claude', 'value': 'Bash', 'project': 'glimmer'},
      ],
    });
    vm = await make(state: _state(channel: 'Attention'));
    rig.api.device(_url, _state(channel: 'Attention'));
    rig.api.on(_url, 'GET', '/push', {
      'cards': [
        {'id': 'c1', 'kind': 'approval', 'agent': 'claude', 'value': 'Bash', 'project': 'glimmer'},
      ],
    });
    await vm.reload();
    expect(vm.holding?.id, 'c1');
    expect(vm.frame!.taskbar.flash, isTrue);
    rig.api.on(_url, 'POST', '/push/clear', {'cleared': 1});
    await vm.dismissCard();
    expect(rig.posts('/push/clear').single.body, {'id': 'c1'});
  });

  test('screen off: optimistic, frame dark; taskbar of the open windows', () async {
    vm = await make();
    answer('Claude');
    await vm.openProgram('Claude');
    rig.api.on(_url, 'POST', '/api/screen', {'ok': true, 'screen_on': false});
    final f = vm.toggleScreen();
    expect(vm.screenOff, isTrue);
    expect(vm.frame!.screenOff, isTrue);
    await f;
    expect(vm.screenOff, isTrue);
    expect(vm.frame!.taskbar.buttons, [TaskButton.claude]);
  });

  test('offline: the last picture stays, mode offline', () async {
    vm = await make();
    rig.api.gone(_url);
    await rig.repo.refresh();
    expect(vm.mode, ControlMode.offline);
    expect(vm.frame, isNotNull);
  });

  test('R-DK-7 the open windows go down after each change (POST /api/windows)', () async {
    vm = await make();
    rig.api.on(_url, 'POST', '/api/windows', {'ok': true});
    answer('Claude');
    await vm.openProgram('Claude');
    await Future<void>.delayed(Duration.zero);
    expect(rig.posts('/api/windows').last.body, {
      'open': ['Claude'],
      'top': 'Claude',
      'min': <String>[],
      'sel': null,
    });
  });

  test('R-DK-11 hold opens the menu; a lit item does its command; outside closes it', () async {
    vm = await make();
    rig.api.on(_url, 'POST', '/api/windows', {'ok': true});
    rig.api.on(_url, 'POST', '/api/menu', {'ok': true});
    answer('Claude');
    await vm.openProgram('Claude');
    await vm.hold(85, 227); // the Claude button
    expect(vm.menu?.kind, MenuKind.window);
    expect(vm.frame!.menu, isNotNull);
    expect(rig.posts('/api/menu').last.body, {'kind': 'window', 'x': 71, 'y': 100, 'minimized': false});
    expect(vm.tap(100, 175).kind, TouchKind.none, reason: 'Phóng to: dim, nothing happens');
    answer('Home');
    vm.tap(100, 160); // Thu nhỏ
    while (vm.sending) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(sent().last, 'Home');
    expect(vm.menu, isNull);
    expect(vm.windows.minimized, {'Claude'});
    await vm.hold(200, 60); // empty desktop spot
    expect(vm.menu?.kind, MenuKind.desktop);
    vm.tap(5, 5); // outside
    await Future<void>.delayed(Duration.zero);
    expect(vm.menu, isNull);
    expect(rig.posts('/api/menu').last.body, {'kind': 'none'});
  });

  test('R-DK-11 firmware without menus: hold does nothing', () async {
    vm = await make(state: {..._state()}..remove('windows'));
    await vm.hold(200, 60);
    expect(vm.menu, isNull);
    expect(rig.posts('/api/menu'), isEmpty);
  });

  test('R-DK-9 a skill turned on: its desktop icon selected; a tap on an empty spot drops it', () async {
    vm = await make();
    rig.api.on(_url, 'POST', '/api/windows', {'ok': true});
    rig.api.device(_url, {
      ..._state(),
      'skills_on': ['agent', 'weather', 'clock', 'photo'],
    });
    await rig.repo.refresh();
    expect(vm.windows.sel, 'Photo');
    expect(rig.posts('/api/windows').last.body, containsPair('sel', 'Photo'));
    vm.tap(200, 60);
    expect(vm.windows.sel, isNull);
  });

  group('R-DK-13 tray balloon', () {
    Map<String, dynamic> withBalloon({String channel = 'Home', bool up = false}) =>
        {..._state(channel: channel), 'balloon': up, 'weather_configured': true};

    test('desktop: tap the tray icon → show; tap × → hide; the mirror follows the answer', () async {
      vm = await make(state: withBalloon());
      rig.api.on(_url, 'POST', '/api/balloon', {'ok': true, 'balloon': true});
      expect(vm.tap(188, 227).kind, TouchKind.tray);
      await pumpEventQueue();
      expect(rig.posts('/api/balloon').single.body, {'show': true});
      expect(vm.frame!.agents.desktop.balloon, isTrue);
      rig.api.on(_url, 'POST', '/api/balloon', {'ok': true, 'balloon': false});
      expect(vm.tap(226, 149).kind, TouchKind.balloonClose);
      await pumpEventQueue();
      expect(rig.posts('/api/balloon').last.body, {'show': false});
      expect(vm.frame!.agents.desktop.balloon, isFalse);
    });

    test('over a window the tray sends nothing; old firmware has no tray target', () async {
      vm = await make(state: withBalloon(channel: 'Clock'));
      vm.tap(188, 227);
      await pumpEventQueue();
      expect(rig.posts('/api/balloon'), isEmpty);
      vm.dispose();
      vm = await make(state: _state());
      expect(vm.tap(188, 227).kind, TouchKind.none);
      expect(rig.posts('/api/balloon'), isEmpty);
    });
  });
}
