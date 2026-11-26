import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/domain/models/attention_card.dart';
import 'package:glimmer_app/domain/models/control.dart';
import 'package:glimmer_app/domain/models/device_state.dart';
import 'package:glimmer_app/domain/rules/control_rules.dart';

DeviceState _s(Map<String, dynamic> extra) => DeviceState.fromJson({'fw': '1.0', 'wifi': 'connected', ...extra});

AttentionCard _card(String id, String kind, {int showsIn = 0}) =>
    AttentionCard(id, kind, 'claude', '', 'Bash', '', 'glimmer', -1, 0, showsInS: showsIn);

void main() {
  group('R-DK-3 firmware capabilities from /api/state', () {
    test('old firmware (no paused / screen_on / slide_left_ms) lacks prev, pause, screen, dismiss', () {
      final c = controlCaps(_s({}));
      expect(c.prev || c.pause || c.screen || c.dismissCard || c.slide, isFalse);
      expect(c.supports(ControlCommand.next), isTrue);
      expect(c.supports(ControlCommand.jump), isTrue);
      expect(c.missing, [ControlCommand.prev, ControlCommand.pause, ControlCommand.screenOff]);
    });

    test('current firmware has everything', () {
      final c = controlCaps(_s({'paused': false, 'screen_on': true, 'slide_ms': 8000, 'slide_left_ms': 3000}));
      expect(c.missing, isEmpty);
      expect(c.supports(ControlCommand.resume), isTrue);
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

    test('rotation guess and next / previous step', () {
      final s = _s({
        'skills_on': ['agent', 'weather', 'clock'],
      });
      final order = rotationGuess(s, {'showClaude': true, 'showInfo': true});
      expect(order, ['Claude', 'Weather', 'Forecast', 'Clock', 'Info']);
      expect(stepChannel(order, 'Clock', 1), 'Info');
      expect(stepChannel(order, 'Claude', -1), 'Info');
      expect(stepChannel(order, 'Night', 1), isNull);
    });
  });

  test('holding card: an approval / input showing on the Attention channel', () {
    final cards = [_card('a', 'info'), _card('b', 'input', showsIn: 30), _card('c', 'approval')];
    expect(holdingCard(_s({'active_channel': 'Attention'}), cards)?.id, 'c');
    expect(holdingCard(_s({'active_channel': 'Claude'}), cards), isNull);
  });

  test('slide progress and seconds left', () {
    expect(slideProgress(8000, 6000), 0.25);
    expect(slideProgress(0, 0), 0);
    expect(secondsLeft(4001), 5);
    expect(secondsLeft(0), 0);
  });
}
