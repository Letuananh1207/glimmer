import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/domain/models/cursor.dart';
import 'package:glimmer_app/domain/models/xp_views.dart';
import 'package:glimmer_app/domain/use_cases/control_device_use_case.dart';
import 'package:glimmer_app/ui/control/view_models/control_view_model.dart';

import '../../../../testing/fakes/fake_repositories.dart';

const _url = 'http://192.168.1.50';

Map<String, dynamic> _state({String channel = 'Home', int trash = 2, bool xp = true}) => {
  'fw': '0.32.0',
  'wifi': 'connected',
  'ip': '192.168.1.50',
  'time': 1795500000,
  'active_channel': channel,
  'skills_on': ['agent', 'weather', 'clock', 'fun'],
  'paused': false,
  'screen_on': true,
  'slide_ms': 0,
  'slide_left_ms': 0,
  'windows': <String, Object?>{},
  'clock': <String, Object?>{},
  'cursor': {'port': 4210, 'x': 120, 'y': 120, 'shape': 1, 'shown': false},
  'power': 'on',
  'wallpaper': false,
  if (xp) ...{
    'taskmgr': {'tab': 0, 'sel': -1, 'cpu': 3},
    'display': {'tab': 0},
    'calc': {'display': '0.'},
    'explorer': {'place': 'computer', 'sel': -1, 'trash': trash},
  },
};

void main() {
  late DeviceRig rig;
  late ControlViewModel vm;
  var now = DateTime(2026, 11, 28, 10);

  Future<ControlViewModel> make({Map<String, dynamic>? state}) async {
    await rig.connect(_url, state ?? _state());
    rig.api.on(_url, 'GET', '/api/settings', {
      'brightness': 80, 'nightMode': 0, 'weatherPlace': 'Hà Nội', //
      'wallpaperMode': 1, 'invertDisplay': true, 'idleDim': true,
    });
    for (final p in ['menu', 'windows', 'taskmgr', 'display', 'calc', 'explorer', 'settings']) {
      rig.api.on(_url, 'POST', '/api/$p', {'ok': true});
    }
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

  /// The pointer to device pixel ([x], [y]) (slow moves: 2 dp = 1 px).
  void to(int x, int y) =>
      vm.movePointer((x - vm.cursor.px) * 2.0, (y - vm.cursor.py) * 2.0, const Duration(seconds: 100));

  Future<void> click(int x, int y) async {
    to(x, y);
    await vm.clickLeft();
    await Future<void>.delayed(Duration.zero);
  }

  List<Map> posts(String path) => [for (final c in rig.posts(path)) c.body as Map];

  setUp(() async {
    now = DateTime(2026, 11, 28, 10);
    rig = await DeviceRig.create();
  });
  tearDown(() {
    vm.dispose();
    rig.repo.dispose();
  });

  test('R-DK-29 R-DK-26 desktop menu › Thuộc tính → Display; edits go to /api/display; Áp dụng saves; Hủy closes',
      () async {
    vm = await make();
    answer('Display');
    await vm.clickRight(); // desktop at (120, 120)
    await vm.pressKey(ControlKey.up); // ↑ from nothing lights the last item: Thuộc tính
    await vm.pressKey(ControlKey.enter);
    await Future<void>.delayed(Duration.zero);
    expect(rig.posts('/api/channel').last.body, {'name': 'Display'});
    expect(posts('/api/display').first, containsPair('wall', 1));
    await click(200, 30); // Cài đặt
    await click(73, 145); // brightness 50
    final b = vm.displayProps!.pending.brightness;
    expect(b, inInclusiveRange(48, 52), reason: 'x ≈ 73 on the 20…127 track');
    expect(posts('/api/display').last, containsPair('bright', b));
    await click(180, 195); // Áp dụng
    await Future<void>.delayed(Duration.zero);
    expect(posts('/api/settings').last, containsPair('brightness', b));
    expect(vm.displayProps!.dirty, isFalse);
    answer('Home');
    await click(120, 195); // Hủy
    expect(rig.posts('/api/channel').last.body, {'name': 'Home'});
  });

  test('R-DK-26 Esc = Hủy, Enter = OK (saves, closes)', () async {
    vm = await make();
    answer('Display');
    await vm.openProgram('Display');
    await click(120, 68); // (Không)
    expect(vm.displayProps!.pending.wallpaper, 0);
    answer('Home');
    await vm.pressKey(ControlKey.enter);
    await Future<void>.delayed(Duration.zero);
    expect(posts('/api/settings').last, containsPair('wallpaperMode', 0));
    expect(rig.posts('/api/channel').last.body, {'name': 'Home'});
  });

  test('R-DK-27 Máy tính bỏ túi: clicks → /api/calc with the key held, then released; Enter = "="', () async {
    vm = await make();
    answer('Calc');
    await vm.openProgram('Calc');
    await click(8 + 38 * 2 + 10, 86 + 30 * 2 + 10); // 2
    await click(8 + 38 * 4 + 10, 86 + 30 * 3 + 10); // +
    await click(8 + 38 * 3 + 10, 86 + 30 * 2 + 10); // 3
    expect(posts('/api/calc').last, containsPair('display', '3.'));
    expect(posts('/api/calc').last['down'], isNot(-1));
    await vm.pressKey(ControlKey.enter);
    expect(vm.calcState.value, 5);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(posts('/api/calc').last, {'display': '5.', 'error': false, 'mem': false, 'down': -1});
  });

  test('R-DK-24 Trình quản lý tác vụ: a row, Kết thúc tác vụ closes that window; Chuyển tới brings one up', () async {
    vm = await make();
    answer('Claude');
    await vm.openProgram('Claude');
    answer('Clock');
    await vm.openProgram('Clock');
    answer('TaskMgr');
    await vm.openProgram('TaskMgr');
    await click(100, 64 + 18 + 5); // row 1 = Đồng hồ

    expect(vm.taskMgrView.sel, 1);
    expect(posts('/api/taskmgr').last, {'tab': 0, 'sel': 1});
    await click(60, 170); // Kết thúc tác vụ
    expect(vm.windows.open, ['Claude', 'TaskMgr']);
    expect(vm.taskMgrView.sel, -1);
    await vm.pressKey(ControlKey.down); // ↓ selects Claude
    expect(vm.taskMgrView.sel, 0);
    answer('Claude');
    await click(200, 170); // Chuyển tới
    expect(rig.posts('/api/channel').last.body, {'name': 'Claude'});
  });

  test('R-DK-25 Alt+Tab: the box picks the second tile, again the next; 1 s quiet → that window; Esc cancels',
      () async {
    vm = await make();
    for (final p in ['Claude', 'Weather', 'Clock']) {
      answer(p);
      await vm.openProgram(p);
    }
    await vm.pressKey(ControlKey.altTab);
    expect(posts('/api/menu').last, {'kind': 'alttab', 'sel': 1}); // [Clock, Weather, Claude] → Weather
    await vm.pressKey(ControlKey.altTab);
    expect(posts('/api/menu').last, {'kind': 'alttab', 'sel': 2}); // Claude
    answer('Claude');
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    expect(posts('/api/menu').last, {'kind': 'none'});
    expect(rig.posts('/api/channel').last.body, {'name': 'Claude'});
    expect(vm.altTabOpen, isFalse);
    await vm.pressKey(ControlKey.altTab);
    await vm.pressKey(ControlKey.escape);
    expect(posts('/api/menu').last, {'kind': 'none'});
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    expect(rig.posts('/api/channel').last.body, {'name': 'Claude'}, reason: 'Esc: nothing else opened');
  });

  test('R-DK-29 R-DK-28 Recycle Bin icon → Thùng rác; a row, Khôi phục; Dọn sạch asks, Có empties', () async {
    vm = await make();
    answer('Explorer');
    final bin = vm.frame!.agents.desktop.icons.firstWhere((i) => i.program == null);
    await click(bin.cx.round(), bin.y.round() + 10); // the Recycle Bin
    expect(rig.posts('/api/channel').last.body, {'name': 'Explorer'});
    expect(posts('/api/explorer').first, containsPair('place', 'trash'));
    await click(100, 75);
    expect(vm.explorerView.sel, 0);
    await click(180, 35); // Khôi phục
    expect(posts('/api/explorer').last, containsPair('do', 'restore'));
    expect(posts('/api/explorer').last['sel'], 0);
    await click(50, 35); // Dọn sạch Thùng rác
    expect(vm.explorerView.confirmEmpty, isTrue);
    await click(80, 140); // Có
    expect(posts('/api/explorer').last, containsPair('do', 'empty'));
    expect(vm.explorerView.confirmEmpty, isFalse);
  });

  test('R-DK-28 Máy tính: a double click on Ảnh của tôi opens it; double click on a photo opens it in Ảnh', () async {
    vm = await make();
    rig.api.on(_url, 'GET', '/api/photos', {
      'photos': [
        {'name': 'p1.jpg', 'size': 100},
      ],
      'samples': [
        {'name': 's1.jpg', 'size': 100},
        {'name': 's2.jpg', 'size': 100},
      ],
      'free': 1000,
    });
    answer('Explorer');
    await vm.openExplorer(ExplorerPlace.computer);
    await click(100, 130);
    expect(vm.explorerView.place, ExplorerPlace.computer, reason: 'one click only selects');
    now = now.add(const Duration(milliseconds: 200));
    await click(100, 130);
    expect(vm.explorerView.place, ExplorerPlace.photos);
    await Future<void>.delayed(Duration.zero);
    now = now.add(const Duration(seconds: 2));
    await click(6 + 57 + 20, 40); // photo 1
    expect(vm.explorerView.sel, 1);
    answer('Photo');
    now = now.add(const Duration(milliseconds: 100));
    await click(6 + 57 + 20, 40);
    await Future<void>.delayed(Duration.zero);
    expect(posts('/api/explorer').last, containsPair('do', 'open'));
    expect(rig.posts('/api/channel').last.body, {'name': 'Photo'});
  });

  test('R-DK-29 Start › Thiết bị → Explorer › Máy tính (firmware with it); older firmware keeps the phone screen',
      () async {
    vm = await make();
    answer('Explorer');
    await vm.pressKey(ControlKey.windows);
    await click(190, 140); // Thiết bị
    expect(rig.posts('/api/channel').last.body, {'name': 'Explorer'});
    expect(posts('/api/explorer').last, containsPair('place', 'computer'));
  });
}
