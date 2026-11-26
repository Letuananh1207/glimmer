import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/domain/models/attention_card.dart';
import 'package:glimmer_app/domain/models/control.dart';
import 'package:glimmer_app/domain/models/device_state.dart';
import 'package:glimmer_app/domain/models/touch.dart';
import 'package:glimmer_app/domain/rules/control_rules.dart';

DeviceState _s(Map<String, dynamic> extra) => DeviceState.fromJson({'fw': '1.0', 'wifi': 'connected', ...extra});

AttentionCard _card(String id, String kind, {int showsIn = 0}) =>
    AttentionCard(id, kind, 'claude', '', 'Bash', '', 'glimmer', -1, 0, showsInS: showsIn);

void main() {
  group('R-DK-3 firmware capabilities from /api/state', () {
    test('R-DK-10 old firmware (no paused / screen_on) lacks touches, screen, dismiss; opening still works', () {
      final c = controlCaps(_s({}));
      expect(c.touch || c.screen || c.dismissCard, isFalse);
      expect(c.supports(ControlCommand.open), isTrue);
      expect(c.supports(ControlCommand.close), isFalse);
      expect(c.supports(ControlCommand.minimize), isFalse);
      expect(c.missing, [ControlCommand.minimize, ControlCommand.screenOff]);
    });

    test('current firmware has everything', () {
      final c = controlCaps(_s({'paused': false, 'screen_on': true}));
      expect(c.missing, isEmpty);
      expect(c.supports(ControlCommand.desktop), isTrue);
      expect(c.supports(ControlCommand.screenOn), isTrue);
    });
  });

  group('channels', () {
    test('skill of each channel; system channels have none', () {
      expect(channelSkill('Forecast'), 'weather');
      expect(channelSkill('Codex'), 'agent');
      expect(channelSkill('Photo'), 'photo');
      expect(channelSkill('Info'), isNull);
      expect(channelSkill('Attention'), isNull);
    });

    test('jump: agent channels follow show* flags, Claude first when unknown', () {
      expect(jumpCandidates('agent', null).first, 'Claude');
      expect(jumpCandidates('agent', {'showClaude': false, 'showCodex': true}).first, 'Codex');
      expect(jumpCandidates('weather', null), ['Weather', 'Forecast']);
    });

    test('R-DK-9 programs follow the enabled skills and the show* flags', () {
      final all = programsOf(['agent', 'weather', 'clock'], null);
      expect(all[ProgramGroup.agent], ['Claude', 'Codex', 'AI', 'Trend', 'Agents']);
      expect(all[ProgramGroup.other], ['Weather', 'Forecast', 'Clock']);
      expect(all[ProgramGroup.system], isEmpty);
      final some = programsOf(['agent', 'photo'], {'showCodex': false, 'showInfo': true});
      expect(some[ProgramGroup.agent], ['Claude', 'AI', 'Trend', 'Agents']);
      expect(some[ProgramGroup.other], ['Photo']);
      expect(some[ProgramGroup.system], ['Info']);
      expect(programSet(['weather'], null), {'Weather', 'Forecast'});
    });

    test('R-DK-7 rotation must be off', () {
      expect(rotationOn({'autoRotate': true}), isTrue);
      expect(rotationOn({'autoRotate': false}), isFalse);
      expect(rotationOn(null), isFalse);
    });
  });

  test('holding card: an approval / input showing on the Attention channel', () {
    final cards = [_card('a', 'info'), _card('b', 'input', showsIn: 30), _card('c', 'approval')];
    expect(holdingCard(_s({'active_channel': 'Attention'}), cards)?.id, 'c');
    expect(holdingCard(_s({'active_channel': 'Claude'}), cards), isNull);
  });
}
