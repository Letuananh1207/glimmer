import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/data/repositories/skill/skill_repository_local.dart';
import 'package:glimmer_app/domain/models/control.dart';
import 'package:glimmer_app/domain/use_cases/control_device_use_case.dart';
import 'package:glimmer_app/domain/use_cases/toggle_skill_use_case.dart';
import 'package:glimmer_app/ui/control/view_models/control_view_model.dart';
import 'package:glimmer_app/domain/models/mirror_frame.dart';

import '../../../../testing/fakes/fake_repositories.dart';
import '../../../../testing/fakes/fake_services.dart';

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

  Future<ControlViewModel> make({Map<String, dynamic>? state}) async {
    await rig.connect(_url, state ?? _state());
    rig.api.on(_url, 'GET', '/api/settings', {'brightness': 50, 'nightMode': 0, 'showClaude': true, 'tzMinutes': 420});
    final toggle = ToggleSkillUseCase(
      skills: SkillRepositoryLocal(store: await fakeStore()),
      device: rig.repo,
    );
    final v = ControlViewModel(
      device: rig.repo,
      control: ControlDeviceUseCase(device: rig.repo),
      toggleSkill: toggle,
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
    expect(vm.secondsLeft, 6);
  });

  test('R-DK-1 jump: the mirror shows the new channel at once, then the device answer', () async {
    vm = await make();
    final hold = Completer<void>();
    rig.api.holdPosts = hold;
    rig.api.on(_url, 'POST', '/api/channel', {'ok': true, 'active': 'Weather', 'paused': false});
    final f = vm.jump('weather');
    await Future<void>.delayed(Duration.zero);
    expect(vm.channel, 'Weather');
    expect(vm.sending, isTrue);
    expect(vm.switching, isTrue);
    hold.complete();
    rig.api.holdPosts = null;
    await f;
    expect(vm.sending, isFalse);
    expect(vm.failed, isNull);
    expect(vm.channel, 'Weather');
    expect(vm.channelSkill, 'weather');
  });

  test('R-DK-1 device shows another channel → follow it, report, no second command', () async {
    vm = await make();
    rig.api.on(_url, 'POST', '/api/channel', {'ok': true, 'active': 'Claude', 'paused': false});
    await vm.jump('clock');
    expect(vm.channel, 'Claude');
    expect(vm.failed, ControlCommand.jump);
    expect(vm.failedSkill, 'clock');
    expect(rig.posts('/api/channel'), hasLength(1));
  });

  test('R-DK-1 no answer → back to the device channel, Thử lại is the only resend', () async {
    vm = await make();
    await vm.step(ControlCommand.next);
    expect(vm.channel, 'Claude');
    expect(vm.failed, ControlCommand.next);
    expect(rig.posts('/api/channel'), hasLength(1));
    rig.api.on(_url, 'POST', '/api/channel', {'ok': true, 'active': 'Weather', 'paused': false});
    await vm.retry();
    expect(rig.posts('/api/channel'), hasLength(2));
    expect(vm.failed, isNull);
    expect(vm.channel, 'Weather');
  });

  test('R-DK-3 locked buttons send nothing', () async {
    vm = await make(state: _state(current: false));
    expect(vm.missing, [ControlCommand.prev, ControlCommand.pause, ControlCommand.screenOff]);
    await vm.step(ControlCommand.prev);
    await vm.togglePause();
    await vm.toggleScreen();
    expect(rig.posts(), isEmpty);
    expect(vm.failed, isNull);
  });

  test('R-DK-4 pause: the button flips at once, only /api/channel pause is sent', () async {
    vm = await make();
    rig.api.on(_url, 'POST', '/api/channel', {'ok': true, 'active': 'Claude', 'paused': true});
    final f = vm.togglePause();
    expect(vm.paused, isTrue);
    await f;
    expect(vm.paused, isTrue);
    expect(vm.secondsLeft, isNull);
    expect(rig.posts('/api/settings'), isEmpty);
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
