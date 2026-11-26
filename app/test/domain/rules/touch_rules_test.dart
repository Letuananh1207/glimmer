import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/domain/models/device_state.dart';
import 'package:glimmer_app/domain/models/mirror_frame.dart';
import 'package:glimmer_app/domain/models/touch.dart';
import 'package:glimmer_app/domain/models/windows.dart';
import 'package:glimmer_app/domain/rules/mirror_agent_rules.dart';
import 'package:glimmer_app/domain/rules/mirror_rules.dart';
import 'package:glimmer_app/domain/rules/touch_rules.dart';

DeviceState _s(String channel, {List<String> skills = const ['agent', 'weather', 'clock']}) =>
    DeviceState.fromJson({'fw': '1.0', 'wifi': 'connected', 'active_channel': channel, 'skills_on': skills});

TouchTarget _at(
  double x,
  double y,
  String channel, {
  List<String> skills = const ['agent', 'weather', 'clock'],
  WindowStack windows = WindowStack.empty,
}) => touchTargetAt(
  x,
  y,
  mirrorFrameOf(
    _s(channel, skills: skills),
    now: DateTime(2026, 11, 26),
    windows: windows,
  ),
);

void main() {
  group('R-DK-8 title bar buttons', () {
    test('centres hit (□ at x 210), the nearest wins inside the 44 dp box', () {
      expect(_at(192, 11, 'Claude').kind, TouchKind.minimize);
      expect(_at(210, 11, 'Claude').kind, TouchKind.maximize);
      expect(_at(228, 11, 'Claude').kind, TouchKind.close);
      expect(_at(198, 11, 'Claude').kind, TouchKind.minimize);
      expect(_at(204, 11, 'Claude').kind, TouchKind.maximize);
      expect(_at(239, 24, 'Claude').kind, TouchKind.close); // 11 px right, 13 px down: still in reach
      expect(_at(160, 11, 'Claude').kind, TouchKind.none);
      expect(_at(228, 40, 'Claude').kind, TouchKind.none);
    });

    test('no window buttons on the desktop, cards, the night face', () {
      expect(_at(228, 11, 'Home').kind, TouchKind.none);
      expect(_at(228, 11, 'Attention').kind, TouchKind.none);
      expect(_at(228, 11, 'Night').kind, TouchKind.none);
    });
  });

  group('R-DK-8 taskbar = open windows', () {
    test('start on the left, then one button per open window from x 71', () {
      final w = WindowStack.empty.opened('Claude').opened('Weather');
      expect(_at(30, 227, 'Weather', windows: w).kind, TouchKind.start);
      expect(_at(85, 227, 'Weather', windows: w), const TouchTarget(TouchKind.taskbar, program: 'Claude'));
      expect(_at(115, 227, 'Weather', windows: w), const TouchTarget(TouchKind.taskbar, program: 'Weather'));
      expect(_at(145, 227, 'Weather', windows: w).kind, TouchKind.none);
      expect(_at(85, 227, 'Home').kind, TouchKind.none, reason: 'nothing open: empty taskbar');
    });

    test('the taskbar model: opening order, top pressed only while it shows, at most 4', () {
      final w = WindowStack.empty.opened('Claude').opened('Weather');
      final shown = mirrorFrameOf(_s('Weather'), now: DateTime(2026), windows: w).taskbar;
      expect(shown.programs, ['Claude', 'Weather']);
      expect(shown.buttons, [TaskButton.claude, TaskButton.weather]);
      expect(shown.active, 1);
      final card = mirrorFrameOf(_s('Attention'), now: DateTime(2026), windows: w).taskbar;
      expect(card.active, isNull);
      final many = ['Claude', 'Codex', 'Weather', 'Clock', 'Info'].fold(WindowStack.empty, (s, p) => s.opened(p));
      final five = mirrorFrameOf(_s('Info'), now: DateTime(2026), windows: many).taskbar;
      expect(five.programs, ['Codex', 'Weather', 'Clock', 'Info']);
      expect(five.buttons.last, TaskButton.info);
      expect(five.active, 3);
    });

    test('the night face has no taskbar', () {
      expect(_at(30, 227, 'Night').kind, TouchKind.none);
    });
  });

  test('desktop icons follow the enabled skills (panel P-2026-11-26.14)', () {
    expect(deskIconsOf(['agent', 'weather', 'clock']), const [
      DeskIcon('Claude', 40, 8),
      DeskIcon('Codex', 40, 56),
      DeskIcon(null, 40, 104),
      DeskIcon('Weather', 120, 8),
      DeskIcon('Clock', 120, 56),
    ]);
    expect(deskIconsOf(['agent', 'photo', 'weather', 'clock']).map((i) => (i.program, i.y)).take(4), [
      ('Claude', 8),
      ('Codex', 56),
      ('Photo', 104),
      (null, 152),
    ]);
  });

  test('R-DK-8 desktop icons open their program; the trash opens nothing', () {
    expect(_at(40, 20, 'Home'), const TouchTarget(TouchKind.icon, program: 'Claude'));
    expect(_at(40, 70, 'Home'), const TouchTarget(TouchKind.icon, program: 'Codex'));
    expect(_at(40, 120, 'Home').kind, TouchKind.none); // trash
    expect(_at(120, 20, 'Home'), const TouchTarget(TouchKind.icon, program: 'Weather'));
    expect(_at(40, 120, 'Home', skills: ['agent', 'photo']), const TouchTarget(TouchKind.icon, program: 'Photo'));
    expect(_at(200, 60, 'Home').kind, TouchKind.none);
  });

  group('R-DK-11 hold = right-click menu', () {
    test("a taskbar button: that window's menu rising from the button", () {
      final w = WindowStack.empty.opened('Claude').opened('Weather').minimize('Weather');
      final f = mirrorFrameOf(_s('Home'), now: DateTime(2026), windows: w);
      final m = holdMenuAt(115, 227, f, minimized: w.minimized)!;
      expect((m.kind, m.x, m.y, m.program, m.minimized), (MenuKind.window, 101, 100, 'Weather', true));
      expect(m.enabled(MenuItem.restore), isTrue);
      expect(m.enabled(MenuItem.minimize), isFalse);
      expect(m.enabled(MenuItem.maximize), isFalse);
    });

    test('a title bar: the window menu at the point; an empty desktop spot: the desktop menu, kept on screen', () {
      final win = holdMenuAt(60, 10, mirrorFrameOf(_s('Claude'), now: DateTime(2026)))!;
      expect((win.kind, win.x, win.y, win.program), (MenuKind.window, 60, 10, 'Claude'));
      final desk = holdMenuAt(200, 180, mirrorFrameOf(_s('Home'), now: DateTime(2026)))!;
      expect((desk.kind, desk.x, desk.y), (MenuKind.desktop, 74, 87));
      expect(desk.height, 127);
    });

    test('icons, the window body, start, the night face: no menu', () {
      expect(holdMenuAt(40, 20, mirrorFrameOf(_s('Home'), now: DateTime(2026))), isNull);
      expect(holdMenuAt(100, 120, mirrorFrameOf(_s('Claude'), now: DateTime(2026))), isNull);
      expect(holdMenuAt(30, 227, mirrorFrameOf(_s('Home'), now: DateTime(2026))), isNull);
      expect(holdMenuAt(100, 100, mirrorFrameOf(_s('Night'), now: DateTime(2026))), isNull);
    });

    test('items under the finger (separators and outside: none)', () {
      const m = MenuView(MenuKind.window, 71, 100, program: 'Claude');
      expect(menuItemAt(m, 100, 104), MenuItem.restore);
      expect(menuItemAt(m, 100, 160), MenuItem.minimize);
      expect(menuItemAt(m, 100, 190), isNull); // separator 187..193
      expect(menuItemAt(m, 100, 200), MenuItem.close);
      expect(menuItemAt(m, 20, 200), isNull);
      expect(menuContains(m, 20, 200), isFalse);
      const d = MenuView(MenuKind.desktop, 60, 30);
      expect(menuItemAt(d, 100, 52), MenuItem.refresh);
      expect(menuItemAt(d, 100, 145), MenuItem.properties);
    });
  });

  group('R-DK-13 tray balloon (panel P-2026-11-26.15)', () {
    MirrorFrame frame(String channel, {bool? balloon, List<String> skills = const ['agent', 'weather', 'clock'],
        WindowStack windows = WindowStack.empty}) => mirrorFrameOf(
      DeviceState.fromJson({
        'fw': '1.0',
        'wifi': 'connected',
        'active_channel': channel,
        'skills_on': skills,
        'weather_configured': true,
        'balloon': ?balloon,
      }),
      now: DateTime(2026, 11, 26),
      windows: windows,
    );

    test('weather skill + firmware with the balloon → tray icon at x 176+, 3 buttons at most', () {
      final w = WindowStack.empty.opened('Claude').opened('Codex').opened('Weather').opened('Clock');
      final f = frame('Clock', balloon: false, windows: w);
      expect(f.taskbar.trayWeather, isTrue);
      expect(f.taskbar.programs, ['Codex', 'Weather', 'Clock']);
      expect(touchTargetAt(188, 227, f).kind, TouchKind.tray);
      expect(touchTargetAt(176, 230, f).kind, TouchKind.tray);
      expect(touchTargetAt(145, 227, f), const TouchTarget(TouchKind.taskbar, program: 'Clock'));
      expect(holdMenuAt(188, 227, f), isNull, reason: 'the tray has no context menu');
    });

    test('old firmware (no balloon) or weather off → old tray, 4 buttons, no tray target', () {
      final w = WindowStack.empty.opened('Claude').opened('Codex').opened('Weather').opened('Clock');
      final old = frame('Clock', windows: w);
      expect(old.taskbar.trayWeather, isFalse);
      expect(old.taskbar.programs.length, 4);
      expect(touchTargetAt(188, 227, old), const TouchTarget(TouchKind.taskbar, program: 'Clock'));
      expect(touchTargetAt(225, 227, old).kind, TouchKind.none, reason: 'the clock is not a target');
      expect(frame('Home', balloon: false, skills: const ['agent']).taskbar.trayWeather, isFalse);
    });

    test('the balloon follows the device; its × is a target while it is up', () {
      final up = frame('Home', balloon: true);
      expect(up.agents.desktop.balloon, isTrue);
      expect(up.agents.desktop.tipBalloon, isTrue);
      expect(touchTargetAt(226, 149, up).kind, TouchKind.balloonClose);
      final down = frame('Home', balloon: false);
      expect(down.agents.desktop.balloon, isFalse);
      expect(touchTargetAt(226, 149, down).kind, TouchKind.none);
      final old = frame('Home');
      expect((old.agents.desktop.balloon, old.agents.desktop.tipBalloon), (true, false),
          reason: 'old firmware: the always-on balloon');
      expect(touchTargetAt(226, 149, old).kind, TouchKind.none);
    });
  });
}
