import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/domain/models/device_state.dart';
import 'package:glimmer_app/domain/rules/mirror_rules.dart';
import 'package:glimmer_app/domain/models/touch.dart';
import 'package:glimmer_app/domain/rules/touch_rules.dart';

DeviceState _s(String channel, {List<String> skills = const ['agent', 'weather', 'clock']}) =>
    DeviceState.fromJson({'fw': '1.0', 'wifi': 'connected', 'active_channel': channel, 'skills_on': skills});

TouchTarget _at(double x, double y, String channel, {List<String> skills = const ['agent', 'weather', 'clock']}) =>
    touchTargetAt(x, y, mirrorFrameOf(_s(channel, skills: skills), now: DateTime(2026, 11, 26)));

void main() {
  group('R-DK-8 title bar buttons', () {
    test('centres hit, the nearest wins inside the 44 dp box', () {
      expect(_at(192, 11, 'Claude').kind, TouchKind.minimize);
      expect(_at(207, 11, 'Claude').kind, TouchKind.maximize);
      expect(_at(228, 11, 'Claude').kind, TouchKind.close);
      expect(_at(198, 11, 'Claude').kind, TouchKind.minimize);
      expect(_at(201, 11, 'Claude').kind, TouchKind.maximize);
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

  group('R-DK-8 taskbar', () {
    test('start on the left, one button per enabled skill from x 71', () {
      expect(_at(30, 227, 'Claude').kind, TouchKind.start);
      expect(_at(85, 227, 'Claude'), const TouchTarget(TouchKind.taskbar, skill: 'agent'));
      expect(_at(115, 227, 'Claude'), const TouchTarget(TouchKind.taskbar, skill: 'weather'));
      expect(_at(145, 227, 'Claude'), const TouchTarget(TouchKind.taskbar, skill: 'clock'));
      expect(_at(175, 227, 'Claude').kind, TouchKind.none);
      expect(_at(220, 227, 'Claude').kind, TouchKind.none); // tray clock
    });

    test('the night face has no taskbar', () {
      expect(_at(30, 227, 'Night').kind, TouchKind.none);
    });
  });

  test('R-DK-8 desktop icons open their program; the trash opens nothing', () {
    expect(_at(40, 20, 'Home'), const TouchTarget(TouchKind.icon, program: 'Claude'));
    expect(_at(40, 70, 'Home'), const TouchTarget(TouchKind.icon, program: 'Codex'));
    expect(_at(40, 120, 'Home', skills: ['agent', 'photo']), const TouchTarget(TouchKind.icon, program: 'Photo'));
    expect(_at(40, 120, 'Home').kind, TouchKind.none); // photo skill off
    expect(_at(40, 170, 'Home').kind, TouchKind.none);
    expect(_at(150, 60, 'Home').kind, TouchKind.none);
  });
}
