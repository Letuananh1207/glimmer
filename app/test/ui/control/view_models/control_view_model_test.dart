import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/domain/models/control.dart';
import 'package:glimmer_app/domain/use_cases/control_device_use_case.dart';
import 'package:glimmer_app/domain/models/touch.dart';
import 'package:glimmer_app/ui/control/view_models/control_view_model.dart';
import 'package:glimmer_app/domain/models/mirror_frame.dart';

import '../../../../testing/fakes/fake_repositories.dart';

const _url = 'http://192.168.1.50';

Map<String, dynamic> _state({String channel = 'Claude', bool paused = false, bool current = true}) => {
  'fw': current ? '0.25.0' : '0.24.0',
  'wifi': 'connected',
  'ip': '192.168.1.50',
  'ssid': 'Nha',
  'time': 1795500000,
  'active_channel': channel,
  'skills_on': ['agent', 'weather', 'clock'],
  if (current) ...{'paused': paused, 'screen_on': true, 'slide_ms': 8000, 'slide_left_ms': 6000},
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

  test('R-DK-6 opening reads /api/state and the settings at once', () async {
    vm = await make();
    final reads = rig.api.calls.where((c) => c.method == 'GET' && c.path == '/api/state').length;
    final settings = rig.api.calls.where((c) => c.method == 'GET' && c.path == '/api/settings').length;
    // connect() reads it once; opening the screen reads it again (constructor + reload in this test).
    expect(reads, greaterThanOrEqualTo(2));
    expect(settings, greaterThanOrEqualTo(1));
    expect(vm.brightness, 50);
    expect(vm.frame!.channel, 'Claude');
    expect(vm.frame!.taskbar.progress, 0); // the device does not rotate: no slide progress
  });

  void answer(String active) =>
      rig.api.on(_url, 'POST', '/api/channel', {'ok': true, 'active': active, 'paused': false});

  test('R-DK-7 the device window is open from the start; autoRotate on → off, once', () async {
    vm = await make(settings: {'brightness': 50, 'autoRotate': true});
    rig.api.on(_url, 'POST', '/api/settings', {'ok': true});
    expect(vm.windows.open, ['Claude']);
    expect(vm.windows.top, 'Claude');
    await vm.reload();
    expect(rig.posts('/api/settings').map((c) => c.body), [
      {'autoRotate': false},
    ]);
  });

  test('R-DK-1 R-DK-7 a desktop icon / Start opens at once, then the device answer', () async {
    vm = await make();
    final hold = Completer<void>();
    rig.api.holdPosts = hold;
    answer('Weather');
    final f = vm.openProgram('Weather');
    await Future<void>.delayed(Duration.zero);
    expect(vm.channel, 'Weather');
    expect(vm.sending, isTrue);
    expect(vm.chip, ChipKind.openingApp);
    expect(vm.windows.top, 'Weather');
    hold.complete();
    rig.api.holdPosts = null;
    await f;
    expect(vm.sending, isFalse);
    expect(vm.failed, isNull);
    expect(vm.windows.open, ['Claude', 'Weather']);
    expect(rig.posts('/api/channel').single.body, {'name': 'Weather'});
  });

  test('R-DK-1 device shows another channel → follow it, report, no second command', () async {
    vm = await make();
    answer('Claude');
    await vm.openProgram('Clock');
    expect(vm.channel, 'Claude');
    expect(vm.failed, ControlCommand.open);
    expect(vm.failedApp, 'Clock');
    expect(vm.windows.open, ['Claude']);
    expect(rig.posts('/api/channel'), hasLength(1));
  });

  test('R-DK-1 no answer → back to the device channel, Thử lại is the only resend', () async {
    vm = await make();
    await vm.openProgram('Weather');
    expect(vm.channel, 'Claude');
    expect(vm.failed, ControlCommand.open);
    expect(rig.posts('/api/channel'), hasLength(1));
    answer('Weather');
    await vm.retry();
    expect(rig.posts('/api/channel'), hasLength(2));
    expect(vm.failed, isNull);
    expect(vm.channel, 'Weather');
  });

  test('R-DK-8 tap _ → desktop, the window keeps its button; tap its button → back', () async {
    vm = await make();
    answer('Home');
    expect(vm.tap(192, 11).kind, TouchKind.minimize);
    await Future<void>.delayed(Duration.zero);
    expect(vm.channel, 'Home');
    expect(vm.chip, ChipKind.minimizing);
    while (vm.sending) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(rig.posts('/api/channel').single.body, {'name': 'Home'});
    expect(vm.windows.open, ['Claude']);
    expect(vm.windows.minimized, {'Claude'});
    expect(vm.note, LineNote.minimized);
    expect(vm.minimizedApp, 'Claude');
    answer('Claude');
    await vm.taskbar('agent');
    expect(rig.posts('/api/channel').last.body, {'name': 'Claude'});
    expect(vm.windows.top, 'Claude');
    expect(vm.note, LineNote.justOpened);
  });

  test('R-DK-8 × → the window before it; the last one → desktop', () async {
    vm = await make();
    answer('Weather');
    await vm.openProgram('Weather');
    answer('Claude');
    await vm.closeTop();
    expect(rig.posts('/api/channel').last.body, {'name': 'Claude'});
    expect(vm.windows.open, ['Claude']);
    answer('Home');
    await vm.closeTop();
    expect(rig.posts('/api/channel').last.body, {'name': 'Home'});
    expect(vm.windows.open, isEmpty);
    expect(vm.windows.top, isNull);
  });

  test('R-DK-8 the shown window\'s taskbar button minimizes it (as XP); □ and start send nothing', () async {
    vm = await make();
    answer('Home');
    await vm.taskbar('agent');
    expect(rig.posts('/api/channel').single.body, {'name': 'Home'});
    expect(vm.windows.minimized, {'Claude'});
    answer('Claude');
    await vm.taskbar('agent');
    final n = rig.posts('/api/channel').length;
    expect(vm.tap(207, 11).kind, TouchKind.maximize);
    expect(vm.tap(30, 227).kind, TouchKind.start);
    await Future<void>.delayed(Duration.zero);
    expect(rig.posts('/api/channel'), hasLength(n));
  });

  test('R-DK-8 a skill with no open window: its taskbar button opens its first program', () async {
    vm = await make();
    answer('Weather');
    await vm.taskbar('weather');
    expect(rig.posts('/api/channel').single.body, {'name': 'Weather'});
    expect(vm.windows.top, 'Weather');
  });

  test('R-DK-9 a skill turned off takes its windows with it', () async {
    vm = await make();
    answer('Clock');
    await vm.openProgram('Clock');
    expect(vm.windows.open, ['Claude', 'Clock']);
    rig.api.device(_url, {
      ..._state(),
      'skills_on': ['agent', 'weather'],
    });
    await rig.repo.refresh();
    expect(vm.windows.open, ['Claude']);
    expect(vm.programs.values.expand((l) => l), isNot(contains('Clock')));
  });

  test('R-DK-3 R-DK-10 old firmware: touches and locked buttons send nothing', () async {
    vm = await make(state: _state(current: false));
    expect(vm.missing, [ControlCommand.minimize, ControlCommand.screenOff]);
    expect(vm.touchable, isFalse);
    expect(vm.tap(228, 11).kind, TouchKind.none);
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
    expect(rig.posts('/api/channel').single.body, {'name': 'Weather'});
  });

  test('R-DK-5 brightness: dragging sends nothing, release sends once', () async {
    vm = await make();
    rig.api.on(_url, 'POST', '/api/settings', {'ok': true});
    vm.dragBrightness(60);
    vm.dragBrightness(80);
    expect(vm.brightness, 80);
    expect(vm.dragging, isTrue);
    expect(vm.dim, greaterThan(0));
    expect(rig.posts(), isEmpty);
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

  test('screen off: optimistic, frame dark; taskbar of enabled skills', () async {
    vm = await make();
    rig.api.on(_url, 'POST', '/api/screen', {'ok': true, 'screen_on': false});
    final f = vm.toggleScreen();
    expect(vm.screenOff, isTrue);
    expect(vm.frame!.screenOff, isTrue);
    await f;
    expect(vm.screenOff, isTrue);
    expect(vm.frame!.taskbar.buttons, [TaskButton.claude, TaskButton.weather, TaskButton.clock]);
  });

  test('offline: the last picture stays, mode offline', () async {
    vm = await make();
    rig.api.gone(_url);
    await rig.repo.refresh();
    expect(vm.mode, ControlMode.offline);
    expect(vm.frame, isNotNull);
  });
}
